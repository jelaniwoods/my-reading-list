require "rails_helper"

RSpec.describe "Readiness", type: :request do
  it "succeeds after a database round-trip" do
    get readiness_check_path

    expect(response).to have_http_status(:ok)
  end

  it "reports that the database is unavailable" do
    allow(ActiveRecord::Base.connection).to receive(:select_value)
      .and_raise(ActiveRecord::ConnectionNotEstablished, "database unavailable")

    get readiness_check_path

    expect(response).to have_http_status(:service_unavailable)
  end
end
