require "spec_helper"
require "fileutils"
require "open3"
require "tmpdir"

RSpec.describe "Local environment setup" do
  let(:root) { File.expand_path("../..", __dir__) }

  around do |example|
    Dir.mktmpdir("environment-setup-") do |directory|
      @directory = directory
      example.run
    end
  end

  before do
    FileUtils.mkdir_p(File.join(@directory, "bin"))
    %w[setup lint-env].each do |script|
      FileUtils.cp(File.join(root, "bin", script), File.join(@directory, "bin", script))
    end
    write(".env.example", "# Optional settings\n# DB_POOL=8\n# ROLLBAR_ACCESS_TOKEN=\n")
  end

  it "allows absent or partial dotenv files" do
    [nil, "DB_POOL=8\n"].each do |contents|
      write(".env", contents) if contents

      stdout, stderr, status = run_script("lint-env")

      expect(status).to be_success, stderr
      expect(stdout).to be_empty
      expect(stderr).to be_empty
    end
  end

  it "reports only active undocumented names" do
    write(".env", "# UNUSED_SECRET=commented-value\nDB_POOL=12\nNEW_TOKEN=private-value\n")

    stdout, stderr, status = run_script("lint-env")

    expect(status).not_to be_success
    expect(stdout).to be_empty
    expect(stderr).to include(".env: undocumented keys: NEW_TOKEN")
    expect(stderr).not_to match(/private-value|commented-value|UNUSED_SECRET|DB_POOL|ROLLBAR_ACCESS_TOKEN/)
  end

  it "checks development and test override files" do
    %w[.env.local .env.development .env.development.local .env.test .env.test.local].each do |path|
      write(path, "NEW_SETTING=value\n")
    end

    _stdout, stderr, status = run_script("lint-env")

    expect(status).not_to be_success
    expect(stderr.scan("undocumented keys: NEW_SETTING").length).to eq(5)
  end

  it "accepts explicit dotenv paths" do
    write(".env", "UNRELATED=value\n")
    write(".env.preview", "PREVIEW_SETTING=value\n")

    _stdout, stderr, status = run_script("lint-env", ".env.preview")

    expect(status).not_to be_success
    expect(stderr).to include(".env.preview: undocumented keys: PREVIEW_SETTING")
    expect(stderr).not_to include("UNRELATED")
  end

  it "understands dotenv declarations without treating comment prose as keys" do
    write(".env.example", "# Runtime settings:\r\n# DB_POOL: 8\r\n# export lower.case = example\r\n# EMPTY=\r\n")
    write(".env", "DB_POOL: 12\r\nexport lower.case = value\r\nEMPTY\r\nRuntime=value\r\n")

    _stdout, stderr, status = run_script("lint-env")

    expect(status).not_to be_success
    expect(stderr).to include("undocumented keys: Runtime")
    expect(stderr).not_to match(/DB_POOL|lower.case|EMPTY/)
  end

  it "rejects missing explicit paths" do
    _stdout, stderr, status = run_script("lint-env", ".env.misspelled")

    expect(status).not_to be_success
    expect(stderr).to include("No such dotenv file:", ".env.misspelled")
  end

  it "resolves explicit paths from the calling directory" do
    FileUtils.mkdir_p(File.join(@directory, "outside"))
    write("outside/.env.preview", "PREVIEW_SETTING=value\n")

    _stdout, stderr, status = run_script("lint-env", ".env.preview", chdir: File.join(@directory, "outside"))

    expect(status).not_to be_success
    expect(stderr).to include("undocumented keys: PREVIEW_SETTING")
    expect(stderr).not_to include("No such dotenv file:")
  end

  it "does not evaluate or disclose quoted multiline values" do
    write(".env", <<~DOTENV)
      ROLLBAR_ACCESS_TOKEN="private-value
      SECRET_INSIDE_VALUE=private-value
      $(touch evaluated)"
      DB_POOL=8
    DOTENV

    stdout, stderr, status = run_script("lint-env")

    expect(status).to be_success, stderr
    expect(stdout).to be_empty
    expect(stderr).to be_empty
    expect(File.exist?(File.join(@directory, "evaluated"))).to be(false)
  end

  it "does not evaluate command substitution in undocumented values" do
    write(".env", "NEW_TOKEN=$(touch evaluated)\n")

    _stdout, stderr, status = run_script("lint-env")

    expect(status).not_to be_success
    expect(stderr).to include("undocumented keys: NEW_TOKEN")
    expect(stderr).not_to include("touch")
    expect(File.exist?(File.join(@directory, "evaluated"))).to be(false)
  end

  it "does not require or inventory inherited environment values" do
    stdout, stderr, status = run_script("lint-env", env: {"DB_POOL" => "12", "UNRELATED_TOKEN" => "private-value"})

    expect(status).to be_success, stderr
    expect(stdout).to be_empty
    expect(stderr).to be_empty
  end

  it "continues setup with absent partial and undocumented local configuration" do
    stub_setup_commands

    [nil, "DB_POOL=8\n", "NEW_SETTING=private-value\n"].each do |contents|
      write(".env", contents) if contents
      write("commands.log", "")

      stdout, stderr, status = run_script("setup", "--skip-server")

      expect(status).to be_success, stderr
      expect(File.read(File.join(@directory, "commands.log"))).to include("rails db:prepare\n", "rails log:clear tmp:clear\n")
      expect(stdout + stderr).not_to match(/Optional keys|Not set|private-value/)
      expect(stderr).to include("undocumented keys: NEW_SETTING") if contents&.include?("NEW_SETTING")
    end
  end

  it "preserves database preparation failures" do
    stub_setup_commands

    _stdout, stderr, status = run_script("setup", "--skip-server", env: {"SETUP_DATABASE_STATUS" => "7"})

    expect(status).not_to be_success
    expect(stderr).to include("Command failed with exit 7")
    expect(File.read(File.join(@directory, "commands.log"))).to include("rails db:prepare\n")
    expect(File.read(File.join(@directory, "commands.log"))).not_to include("log:clear")
  end

  def write(path, contents)
    File.write(File.join(@directory, path), contents)
  end

  def run_script(name, *arguments, env: {}, chdir: @directory)
    Open3.capture3(
      {
        "BUNDLE_GEMFILE" => File.join(root, "Gemfile"),
        "PATH" => "#{@directory}/bin:#{ENV.fetch("PATH")}",
        "SETUP_COMMAND_LOG" => File.join(@directory, "commands.log")
      }.merge(env),
      RbConfig.ruby, File.join(@directory, "bin", name), *arguments,
      chdir:
    )
  end

  def stub_setup_commands
    %w[bundle npm package-manager-check rails].each do |name|
      path = "bin/#{name}"
      write(path, <<~RUBY)
        #!/usr/bin/env ruby
        File.open(ENV.fetch("SETUP_COMMAND_LOG"), "a") do |file|
          file.puts([File.basename($PROGRAM_NAME), *ARGV].join(" "))
        end
        exit ENV.fetch("SETUP_DATABASE_STATUS", "0").to_i if ARGV == ["db:prepare"]
      RUBY
      FileUtils.chmod(0o755, File.join(@directory, path))
    end
  end
end
