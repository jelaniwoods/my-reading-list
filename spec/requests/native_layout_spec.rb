require "rails_helper"

RSpec.describe "Native presentation", type: :request do
  let(:browser_user_agent) do
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
      "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36"
  end

  it "keeps web navigation available to ordinary browsers" do
    get privacy_path, headers: {"User-Agent" => browser_user_agent}

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css("header")).to be_present
  end

  {
    "iOS" => "Foundation/1.0; Hotwire Native iOS; Turbo Native iOS; bridge-components: []",
    "Android" => "Hotwire Native Android; Turbo Native Android"
  }.each do |platform, user_agent|
    context "in a #{platform} shell" do
      it "leaves navigation and the color preference to the native client" do
        get privacy_path, headers: {"User-Agent" => user_agent}

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.css("header.app-header")).to be_empty
        expect(response.parsed_body.css("[data-controller='theme']")).to be_empty
        expected_mode = (Rails.application.config.x.ui_theme == "toggle") ? "auto" : Rails.application.config.x.ui_theme
        expect(response.parsed_body.at_css("html")["data-theme-mode"]).to eq(expected_mode)
      end

      it "uses the page title alone for the native toolbar" do
        get privacy_path, headers: {"User-Agent" => user_agent}

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.at_css("title").text).to eq(I18n.t("pages.privacy.heading"))
      end
    end
  end

  it "includes the application name in browser page titles" do
    get privacy_path, headers: {"User-Agent" => browser_user_agent}

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css("title").text).to eq("#{I18n.t("pages.privacy.heading")} · #{I18n.t("app_name")}")
  end

  context "with punctuation and markup in the title" do
    let(:page_title) { %(Joe's "R&D" </title><script id="title-payload">alert(1)</script>) }
    let(:app_name) { %(Bob's & <Friends>) }

    before do
      I18n.t("app_name")
      I18n.backend.store_translations(:en, app_name: app_name, pages: {privacy: {heading: page_title}})
    end

    after { I18n.backend.reload! }

    it "escapes native toolbar titles exactly once" do
      ["Hotwire Native iOS", "Hotwire Native Android"].each do |user_agent|
        get privacy_path, headers: {"User-Agent" => user_agent}

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.css("title").map(&:text)).to eq([page_title])
        expect(response.parsed_body.css("script#title-payload")).to be_empty
      end
    end

    it "escapes browser page titles exactly once" do
      get privacy_path, headers: {"User-Agent" => browser_user_agent}

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.css("title").map(&:text)).to eq(["#{page_title} · #{app_name}"])
      expect(response.parsed_body.css("script#title-payload")).to be_empty
    end
  end
end
