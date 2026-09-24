require "rails_helper"

RSpec.describe "shared/ui/_date_field", type: :view do
  let(:min) { nil }
  let(:max) { nil }
  let(:date_input) do
    render inline: <<~ERB, locals: {value: value, min: min, max: max}
      <%= form_with scope: :event, url: "/events" do |form| %>
        <%= render "shared/ui/date_field", form: form, attribute: :starts_on, label: "Starts on", value: value, min: min, max: max %>
      <% end %>
    ERB
    Nokogiri::HTML.fragment(rendered).at_css("input[type=date]")
  end

  {
    "a Date" => [Date.new(2026, 9, 13), "2026-09-13"],
    "a UTC Time" => [Time.utc(2026, 9, 13, 23, 45), "2026-09-13"],
    "a time in its own zone" => [Time.find_zone!("Tokyo").local(2026, 9, 13, 1, 30), "2026-09-13"],
    "an invalid literal" => ["invalid-date", "invalid-date"],
    "an empty string" => ["", ""],
    "a missing value" => [nil, nil]
  }.each do |description, (input_value, expected)|
    context "with #{description}" do
      let(:value) { input_value }

      it "retains the calendar date or submitted literal" do
        expect(date_input["value"]).to eq(expected)
      end
    end
  end

  context "with calendar-date bounds" do
    let(:value) { Date.new(2026, 9, 13) }
    let(:min) { Date.new(1851, 1, 1) }
    let(:max) { Time.find_zone!("Tokyo").local(2026, 12, 31, 1, 30) }

    it "formats each bound without converting its time zone" do
      expect(date_input["min"]).to eq("1851-01-01")
      expect(date_input["max"]).to eq("2026-12-31")
    end
  end
end
