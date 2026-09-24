require "rails_helper"

RSpec.describe "Browser support", type: :request do
  let(:old_safari_user_agent) do
    "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) " \
      "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
  end

  it "rejects an outdated ordinary web browser" do
    get privacy_path, headers: {"User-Agent" => old_safari_user_agent}

    expect(response).to have_http_status(:not_acceptable)
  end

  it "allows an older WebView in a Hotwire Native iOS shell" do
    user_agent = "#{old_safari_user_agent} Foundation/1.0; " \
      "Hotwire Native iOS; Turbo Native iOS; bridge-components: []"

    get privacy_path, headers: {"User-Agent" => user_agent}

    expect(response).to have_http_status(:ok)
  end

  it "allows an older WebView in a Hotwire Native Android shell" do
    user_agent = "Foundation/1.0; Hotwire Native Android; Turbo Native Android; " \
      "bridge-components: []; Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 " \
      "(KHTML, like Gecko) Chrome/80.0.3987.149 Mobile Safari/537.36"

    get privacy_path, headers: {"User-Agent" => user_agent}

    expect(response).to have_http_status(:ok)
  end
end
