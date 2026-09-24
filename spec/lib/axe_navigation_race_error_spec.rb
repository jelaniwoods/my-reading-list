require "rails_helper"

RSpec.describe "Accessibility audit retries" do
  let(:pattern) { SystemSpecSupport::AXE_NAVIGATION_RACE_ERROR }

  it "recognizes the known axe property lookup failures" do
    [
      "Cannot read properties of undefined (reading 'runPartial')",
      "Cannot read properties of undefined (reading \"runPartial\")",
      "Cannot read properties of undefined (reading 'utils')",
      "Cannot read properties of undefined (reading \"utils\")"
    ].each do |message|
      expect(message).to match(pattern)
    end
  end

  it "rejects unrelated JavaScript and accessibility failures" do
    [
      "Cannot read properties of undefined (reading 'run')",
      "Accessibility violations found: color-contrast",
      "utils"
    ].each do |message|
      expect(message).not_to match(pattern)
    end
  end
end
