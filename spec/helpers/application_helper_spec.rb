require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  [false, true].each do |native_request|
    context "with a #{native_request ? "native" : "browser"} request" do
      before { allow(helper).to receive(:hotwire_native_app?).and_return(native_request) }

      it "uses the application name when the page has no title" do
        expect(helper.full_page_title).to eq(I18n.t("app_name"))
      end

      it "uses the application name when the page title is blank" do
        helper.content_for :title, " "

        expect(helper.full_page_title).to eq(I18n.t("app_name"))
      end
    end
  end
end
