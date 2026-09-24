# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "open3"
require "optparse"
require "tmpdir"
require "uri"

module AndroidPreview
  class Error < StandardError; end

  class Runner
    def initialize(root:)
      @root = root
    end

    def capture!(*command)
      stdout, stderr, status = Open3.capture3(*command, chdir: @root)
      return stdout if status.success?

      detail = stderr.strip.empty? ? stdout.strip : stderr.strip
      message = "#{command.join(" ")} failed"
      message = "#{message}: #{detail}" unless detail.empty?
      raise Error, message
    end

    def run!(*command)
      return if system(*command, chdir: @root)

      raise Error, "#{command.join(" ")} failed"
    end
  end

  class Origin
    CHECK_PATHS = ["/up"].freeze

    attr_reader :url

    def initialize(raw)
      uri = URI.parse(raw.to_s.strip)
      valid = uri.is_a?(URI::HTTPS) && uri.host && uri.userinfo.nil? &&
        (uri.path.empty? || uri.path == "/") && uri.query.nil? && uri.fragment.nil?
      unless valid
        raise Error, "preview URL must be an HTTPS origin with no credentials, path, query, or fragment"
      end

      @url = "https://#{uri.host}#{":#{uri.port}" unless uri.port == 443}"
    rescue URI::InvalidURIError
      raise Error, "preview URL is not a valid absolute URL"
    end

    def verify!(runner)
      CHECK_PATHS.each do |path|
        status = runner.capture!(
          "curl", "--silent", "--show-error", "--output", File::NULL,
          "--write-out", "%{http_code}", "--connect-timeout", "10", "--max-time", "20",
          "#{url}#{path}"
        ).strip
        next if status.match?(/\A2\d\d\z/)

        raise Error, "#{url}#{path} returned HTTP #{status}; make the Rails preview public and healthy"
      end
    end
  end

  class Artifact
    attr_reader :archive, :manifest, :source_sha, :digest

    def initialize(archive:, manifest:, expected_sha:)
      @archive = File.expand_path(archive)
      @manifest = File.expand_path(manifest)
      raise Error, "artifact not found: #{@archive}" unless File.file?(@archive)
      raise Error, "manifest not found: #{@manifest}" unless File.file?(@manifest)
      raise Error, "expected a .apk artifact: #{@archive}" unless @archive.end_with?(".apk")

      data = JSON.parse(File.read(@manifest))
      @source_sha = data.fetch("commit_sha")
      @digest = Digest::SHA256.file(@archive).hexdigest

      raise Error, "unsupported APK manifest format" unless data["format"] == "firstdraft-android-apk-v1"
      raise Error, "artifact is for #{data["app_platform"].inspect}, not android" unless data["app_platform"] == "android"
      raise Error, "manifest source #{@source_sha} does not match HEAD #{expected_sha}" unless @source_sha == expected_sha
      raise Error, "artifact digest does not match manifest" unless data["artifact_sha256"] == @digest

      raise Error, "Revyl requires a debuggable APK" unless data["debuggable"] == true
      unless data["application_id"].is_a?(String) &&
          /\A[a-zA-Z][a-zA-Z0-9_]*(?:\.[a-zA-Z][a-zA-Z0-9_]*)+\z/.match?(data["application_id"])
        raise Error, "APK manifest has no valid application ID"
      end
    rescue JSON::ParserError, KeyError => error
      raise Error, "invalid APK manifest: #{error.message}"
    end
  end

  class ProjectConfig
    attr_reader :path

    def initialize(root:)
      @path = File.join(root, "config", "android_preview.json")
      raise Error, "missing config/android_preview.json" unless File.file?(@path)

      @data = JSON.parse(File.read(@path))
      raise Error, "config/android_preview.json must contain a JSON object" unless @data.is_a?(Hash)
    rescue JSON::ParserError => error
      raise Error, "invalid config/android_preview.json: #{error.message}"
    end

    def project_name
      @data["name"].to_s.strip.then { |name| name.empty? ? "Android preview" : name }
    end

    def app_name
      "#{project_name} Android preview"
    end

    def app_id
      @data["app_id"].to_s.strip
    end

    def store_app_id!(value)
      @data["app_id"] = value

      temporary = "#{path}.tmp"
      serialized = JSON.pretty_generate(@data) + "\n"
      File.write(temporary, serialized)
      File.rename(temporary, path)
    end
  end

  class GitHubArtifact
    WORKFLOW = "android-apk-artifact.yml"
    BUILD_EVENTS = %w[push workflow_dispatch].freeze
    PENDING_STATUSES = %w[requested waiting pending queued in_progress].freeze
    RUN_FIELDS = "databaseId,event,headSha,status,conclusion,url,createdAt"
    BUILD_INPUTS = [
      "android",
      "bin/android",
      "bin/android-apk-artifact",
      ".github/workflows/android-apk-artifact.yml"
    ].freeze

    def initialize(root:, runner:, out:, sleeper: ->(seconds) { Kernel.sleep(seconds) })
      @root = root
      @runner = runner
      @out = out
      @sleeper = sleeper
    end

    def fetch(expected_sha)
      ensure_clean_build_inputs!
      ensure_pushed_head!(expected_sha)
      run = reusable_run(expected_sha) || wait_for_run(expected_sha)
      source_sha = run.fetch("headSha")
      if source_sha != expected_sha
        @out.puts "Native build inputs are unchanged; reusing #{source_sha} for Rails HEAD #{expected_sha}."
      end
      destination = File.join(@root, "tmp", "android-preview", "#{expected_sha}-#{run.fetch("databaseId")}")
      destination = Dir.mktmpdir("#{expected_sha}-", File.join(@root, "tmp", "android-preview")) if File.exist?(destination)
      FileUtils.mkdir_p(destination)

      @runner.run!("gh", "run", "download", run.fetch("databaseId").to_s, "--dir", destination)
      archives = Dir.glob(File.join(destination, "**", "*.apk"))
      manifests = Dir.glob(File.join(destination, "**", "manifest.json"))
      raise Error, "downloaded workflow artifact did not contain exactly one .apk and manifest.json" unless archives.one? && manifests.one?

      @out.puts "Downloaded GitHub run: #{run["url"]}" if run["url"]
      [archives.first, manifests.first, source_sha]
    end

    private

    def ensure_clean_build_inputs!
      status = @runner.capture!("git", "status", "--porcelain", "--", *BUILD_INPUTS).strip
      return if status.empty?

      raise Error, "commit or discard native build-input changes before requesting the GitHub artifact:\n#{status}"
    end

    def ensure_pushed_head!(expected_sha)
      upstream = @runner.capture!("git", "rev-parse", "@{upstream}").strip
      return if upstream == expected_sha

      raise Error, "HEAD #{expected_sha} is not pushed to its upstream branch (currently #{upstream})"
    rescue Error => error
      raise error if error.message.start_with?("HEAD ")

      raise Error, "current branch needs a pushed upstream before GitHub can build it"
    end

    def runs(expected_sha = nil, status: nil)
      command = [
        "gh", "run", "list", "--workflow", WORKFLOW,
        "--limit", "20", "--json", RUN_FIELDS
      ]
      command.concat(["--commit", expected_sha]) if expected_sha
      command.concat(["--status", status]) if status
      JSON.parse(@runner.capture!(*command))
    rescue JSON::ParserError => error
      raise Error, "GitHub returned invalid run data: #{error.message}"
    end

    def reusable_run(expected_sha)
      ancestors = @runner.capture!("git", "rev-list", expected_sha).split
      inputs = native_inputs(expected_sha)
      runs(status: "success").find do |run|
        source = run["headSha"]
        BUILD_EVENTS.include?(run["event"]) && run["conclusion"] == "success" &&
          ancestors.include?(source) && native_inputs(source) == inputs && artifact_available?(run)
      end
    end

    def native_inputs(sha)
      @runner.capture!("git", "ls-tree", "-r", "--full-tree", sha, "--", *BUILD_INPUTS)
    end

    def artifact_available?(run)
      data = JSON.parse(@runner.capture!(
        "gh", "api", "repos/{owner}/{repo}/actions/runs/#{run.fetch("databaseId")}/artifacts"
      ))
      data.fetch("artifacts").any? { |artifact| !artifact.fetch("expired") }
    end

    def successful_run(expected_sha)
      runs(expected_sha, status: "success").find do |run|
        eligible_run?(run, expected_sha) && run["conclusion"] == "success" && artifact_available?(run)
      end
    end

    def wait_for_run(expected_sha)
      run = pending_or_successful_run(expected_sha)
      unless run
        @out.puts "Waiting for GitHub to register the native build..."
        10.times do
          @sleeper.call(2)
          run = pending_or_successful_run(expected_sha)
          break if run
        end
      end
      unless run
        branch = @runner.capture!("git", "branch", "--show-current").strip
        raise Error, "preview artifacts require a named branch" if branch.empty?

        @out.puts "No reusable native artifact exists; starting the GitHub Linux workflow."
        dispatch!(branch)
        15.times do
          @sleeper.call(2)
          run = pending_or_successful_run(expected_sha)
          break if run
        end
      end
      raise Error, "GitHub did not report a workflow run for HEAD" unless run

      @runner.run!("gh", "run", "watch", run.fetch("databaseId").to_s, "--exit-status", "--interval", "10") unless run["conclusion"] == "success"
      successful_run(expected_sha) || raise(Error, "GitHub workflow completed without a successful artifact")
    end

    def eligible_run?(run, expected_sha)
      run["headSha"] == expected_sha && BUILD_EVENTS.include?(run["event"])
    end

    def pending_or_successful_run(expected_sha)
      runs(expected_sha).find do |candidate|
        eligible_run?(candidate, expected_sha) &&
          ((candidate["conclusion"] == "success" && artifact_available?(candidate)) ||
            PENDING_STATUSES.include?(candidate["status"]))
      end
    end

    def dispatch!(branch)
      @runner.run!("gh", "workflow", "run", WORKFLOW, "--ref", branch)
    rescue Error => error
      raise Error,
        "#{error.message}. Codespaces may permit pushes but not workflow dispatch. " \
        "Open your repository on GitHub → Actions → Android APK artifact → Run workflow, " \
        "choose #{branch}, then rerun this preview command."
    end
  end

  class RevylAdapter
    REQUIRED_VERSION = "v0.1.109"

    def initialize(config:, runner:, out:)
      @config = config
      @runner = runner
      @out = out
    end

    def authenticate!
      require_compatible_version!
      data = json!("revyl", "auth", "status", "--json")
      unless data["authenticated"] == true
        raise Error,
          "Revyl is not authenticated; run `revyl auth login` and approve its URL in your browser"
      end
      @apps = json!("revyl", "app", "list", "--platform", "android", "--json").fetch("apps")
    end

    def ensure_no_active_session!
      sessions = json!("revyl", "device", "list", "--json")
      return if sessions.empty?

      raise Error, "a preview session already exists; use `bin/android preview revyl status` or stop it before starting another"
    end

    def app_id
      apps = @apps
      configured = @config.app_id
      if !configured.empty?
        return configured if apps.any? { |app| app["id"] == configured }

        raise Error, "configured Revyl app #{configured} is unavailable to the authenticated account"
      end

      matches = apps.select { |app| app["name"].to_s.casecmp?(@config.app_name) }
      raise Error, "multiple Revyl apps are named #{@config.app_name.inspect}; set app_id in config/android_preview.json" if matches.length > 1

      value = if matches.one?
        matches.first.fetch("id")
      else
        created = json!("revyl", "app", "create", "--name", @config.app_name, "--platform", "android", "--json")
        created["id"] || created.dig("app", "id") || raise(Error, "Revyl did not return the created app ID")
      end
      @config.store_app_id!(value)
      @out.puts "Saved the non-secret Revyl app ID in config/android_preview.json."
      value
    end

    def upload(artifact, app_id)
      version = "sha256-#{artifact.digest}"
      versions = json!("revyl", "build", "list", "--app", app_id, "--json").fetch("versions")
      existing = versions.find { |build| build["version"] == version }
      if existing
        @out.puts "Reusing the uploaded Revyl artifact."
        return existing.fetch("id")
      end

      data = json!(
        "revyl", "build", "upload", "--file", artifact.archive, "--app", app_id,
        "--platform", "android", "--version", version, "--yes", "--json"
      )
      version_id = data["version_id"] || data["build_version_id"] || data.dig("build", "build_id")
      raise Error, "Revyl did not return a build-version ID" if version_id.to_s.empty?
      raise Error, "Revyl changed the source artifact during upload" unless Digest::SHA256.file(artifact.archive).hexdigest == artifact.digest

      version_id
    end

    def start(build_version_id:, origin:, timeout:, open:)
      output = @runner.capture!(
        "revyl", "device", "start", "--platform", "android", "--build-version-id", build_version_id,
        "--launch-env", "APP_ROOT_URL=#{origin.url}", "--timeout", timeout.to_s,
        "--open=#{open}", "--json"
      )
      begin
        raise JSON::ParserError if output.strip.empty?

        JSON.parse(output)
      rescue JSON::ParserError
        @out.puts "Revyl started the device without complete JSON; recovering the active session details."
      end
      info = json!("revyl", "device", "info", "--json")
      session_id = info["session_id"].to_s
      raise Error, "Revyl started a session but did not return its ID; use revyl device list to stop it" if session_id.empty?

      viewer = "https://app.revyl.ai/tests/report?sessionId=#{URI.encode_www_form_component(session_id)}"

      @out.puts "Revyl session: #{info["index"] || "active"}"
      @out.puts "Viewer: #{viewer}"
      info
    end

    def status
      @out.puts JSON.pretty_generate(json!("revyl", "device", "list", "--json"))
    end

    def stop(index: nil)
      command = ["revyl", "device", "stop"]
      command.concat(["-s", index.to_s]) if index
      command << "--json"
      @out.puts JSON.pretty_generate(json!(*command))
    end

    private

    def require_compatible_version!
      output = @runner.capture!("revyl", "--version").strip
      return if output.split.include?(REQUIRED_VERSION)

      raise Error,
        "this preview adapter requires Revyl #{REQUIRED_VERSION}; found #{output.inspect}. " \
        "Follow ANDROID_PREVIEW.md to install the tested version."
    end

    def json!(*command)
      JSON.parse(@runner.capture!(*command))
    rescue JSON::ParserError => error
      raise Error, "#{command.join(" ")} returned invalid JSON: #{error.message}"
    end
  end

  class CLI
    ROOT = File.expand_path("..", __dir__)

    def initialize(arguments, root: ROOT, runner: nil, out: $stdout, err: $stderr)
      @arguments = arguments.dup
      @root = root
      @runner = runner || Runner.new(root: root)
      @out = out
      @err = err
    end

    def run
      command = %w[start status stop doctor help].include?(@arguments.first) ? @arguments.shift : "start"
      case command
      when "start" then start
      when "status" then session_adapter.status
      when "stop" then stop
      when "doctor" then doctor
      else @out.puts(help)
      end
      0
    rescue Error, OptionParser::ParseError => error
      @err.puts "Android preview error: #{error.message}"
      1
    end

    private

    def start
      options = {timeout: 300, open: false}
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: bin/android preview revyl --server URL [options]"
        opts.on("--server URL", "Public HTTPS Rails preview origin") { |value| options[:server] = value }
        opts.on("--artifact PATH", "Use an existing .apk instead of downloading GitHub Actions") { |value| options[:artifact] = value }
        opts.on("--manifest PATH", "Manifest for --artifact (defaults to its sibling manifest.json)") { |value| options[:manifest] = value }
        opts.on("--timeout SECONDS", Integer, "Revyl idle timeout (default: 300)") { |value| options[:timeout] = value }
        opts.on("--open", "Also open the viewer in the CLI host's browser") { options[:open] = true }
        opts.on("--no-open", "Report the viewer URL without opening a browser") { options[:open] = false }
        opts.on("-h", "--help") { options[:help] = true }
      end
      parser.parse!(@arguments)
      if options[:help]
        @out.puts(help)
        return
      end
      raise Error, "provide the public Rails preview URL with --server" if options[:server].to_s.empty?
      raise Error, "unexpected arguments: #{@arguments.join(" ")}" unless @arguments.empty?
      raise Error, "timeout must be between 60 and 1800 seconds" unless (60..1800).cover?(options[:timeout])

      origin = Origin.new(options[:server])
      origin.verify!(@runner)
      adapter.ensure_no_active_session!
      expected_sha = @runner.capture!("git", "rev-parse", "HEAD").strip
      archive, manifest, source_sha = artifact_paths(options, expected_sha)
      artifact = Artifact.new(archive: archive, manifest: manifest, expected_sha: source_sha)

      @out.puts "Preparing the APK artifact in Revyl..."
      app_id = adapter.app_id
      version_id = adapter.upload(artifact, app_id)
      @out.puts "Starting the Revyl device..."
      adapter.start(build_version_id: version_id, origin: origin, timeout: options[:timeout], open: options[:open])
      @out.puts "Artifact: #{artifact.archive}"
      @out.puts "Source: #{artifact.source_sha}"
      @out.puts "SHA-256: #{artifact.digest}"
      @out.puts "When finished: bin/android preview revyl stop (closing the browser does not stop the device)."
    end

    def artifact_paths(options, expected_sha)
      if options[:artifact]
        manifest = options[:manifest] || File.join(File.dirname(File.expand_path(options[:artifact])), "manifest.json")
        [options[:artifact], manifest, expected_sha]
      elsif options[:manifest]
        raise Error, "--manifest requires --artifact"
      else
        GitHubArtifact.new(root: @root, runner: @runner, out: @out).fetch(expected_sha)
      end
    end

    def stop
      options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: bin/android preview revyl stop [--session INDEX]"
        opts.on("-s", "--session INDEX", Integer, "Stop one session (default: active)") { |value| options[:index] = value }
      end.parse!(@arguments)
      raise Error, "unexpected arguments: #{@arguments.join(" ")}" unless @arguments.empty?

      session_adapter.stop(index: options[:index])
    end

    def doctor
      checks = []
      checks << check("Git", "git", "--version")
      checks << check("GitHub CLI", "gh", "--version")
      checks << check("GitHub authentication", "gh", "auth", "status")
      checks << check("HTTP client", "curl", "--version")
      checks << revyl_version_check
      checks << revyl_auth_check
      checks << revyl_config_check
      checks << ["APK workflow", File.file?(File.join(@root, ".github", "workflows", GitHubArtifact::WORKFLOW)), GitHubArtifact::WORKFLOW]
      required_checks = checks.dup

      checks.each { |name, passed, detail| @out.puts "#{passed ? "PASS" : "FAIL"}  #{name}: #{detail}" }
      raise Error, "required preview checks failed" if required_checks.any? { |_, passed, _| !passed }
    end

    def check(name, *command)
      detail = @runner.capture!(*command).lines.first.to_s.strip
      [name, true, detail]
    rescue Error => error
      [name, false, error.message]
    end

    def revyl_auth_check
      data = JSON.parse(@runner.capture!("revyl", "auth", "status", "--json"))
      authenticated = data["authenticated"] == true
      detail = if authenticated
        "authenticated"
      else
        "run revyl auth login and approve its URL in your browser"
      end
      ["Revyl authentication", authenticated, detail]
    rescue Error, JSON::ParserError => error
      ["Revyl authentication", false, error.message]
    end

    def revyl_version_check
      output = @runner.capture!("revyl", "--version").strip
      required = RevylAdapter::REQUIRED_VERSION
      compatible = output.split.include?(required)
      detail = if compatible
        output
      else
        "requires #{required}; found #{output.inspect}; follow ANDROID_PREVIEW.md to install it"
      end
      ["Revyl CLI", compatible, detail]
    rescue Error => error
      ["Revyl CLI", false, error.message]
    end

    def revyl_config_check
      config = ProjectConfig.new(root: @root)
      detail = config.app_id.empty? ? "valid; app ID will be selected on first preview" : "valid; app ID configured"
      ["Revyl project config", true, detail]
    rescue Error => error
      ["Revyl project config", false, error.message]
    end

    def adapter
      @adapter ||= RevylAdapter.new(config: ProjectConfig.new(root: @root), runner: @runner, out: @out).tap(&:authenticate!)
    end

    def session_adapter
      @session_adapter ||= RevylAdapter.new(config: nil, runner: @runner, out: @out)
    end

    def help
      <<~TEXT
        Usage:
          bin/android preview revyl --server URL [--artifact APP.apk] [--manifest manifest.json]
          bin/android preview revyl status
          bin/android preview revyl stop [--session INDEX]
          bin/android preview revyl doctor

        Options: --timeout SECONDS (60–1800, default 300), --open, --no-open.
        The viewer link is always printed. Browser opening is off by default.

        With no artifact argument, the command verifies that HEAD is pushed, reuses a
        build with identical native inputs or starts android-apk-artifact.yml,
        verifies the manifest and SHA-256, uploads the unchanged archive through the
        locally authenticated Revyl CLI, and opens a browser device against URL.

        Credentials stay in each user's gh and revyl login stores.
        config/android_preview.json contains only the app name and non-secret app ID.
        GitHub builds the app; Revyl uploads it and runs a device with a 5-minute idle timeout.
      TEXT
    end
  end
end
