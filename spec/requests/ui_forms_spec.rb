require "rails_helper"
require_relative "../support/ui_fixture_controller"

RSpec.describe "Form feedback and native controls", type: :request do
  it "retains live regions while omitting blank feedback messages" do
    get "/__ui/guidance", params: {blank_warning: true}

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.css("[role='status'][aria-atomic='true']").size).to eq(1)
    expect(response.parsed_body.css("[role='alert'][aria-atomic='true']").size).to eq(1)
    messages = response.parsed_body.css("[data-flash-message]")
    expect(messages.size).to eq(2)
    expect(messages.map { |message| message.text.strip }).to all(be_present)
  end
end
