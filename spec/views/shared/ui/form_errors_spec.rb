require "rails_helper"

RSpec.describe "shared/ui/_form_errors", type: :view do
  before do
    stub_const("SampleRecord", Class.new do
      include ActiveModel::Model

      attr_accessor :title, :person, :status
    end)
  end

  it "links errors by attribute even when different fields have identical messages" do
    record = SampleRecord.new
    allow(SampleRecord).to receive(:human_attribute_name).and_return("Value")
    record.errors.add(:title, "is invalid")
    record.errors.add(:person, "is invalid")
    record.errors.add(:status, "is unavailable")
    record.errors.add(:base, "The record cannot be saved")

    render partial: "shared/ui/form_errors", locals: {
      errors: record.errors,
      field_ids: {title: "edit_movie_title", person: "edit_movie_person_id"},
      title: "Please correct these errors", id: "edit-movie-errors"
    }

    expect(rendered).to have_link("Value is invalid", href: "#edit_movie_title")
    expect(rendered).to have_link("Value is invalid", href: "#edit_movie_person_id")
    expect(rendered).to have_css("li", text: "Value is unavailable")
    expect(rendered).to have_css("li", text: "The record cannot be saved")
    expect(rendered).to have_css("a", count: 2)
    expect(rendered).to have_css('[role="alert"][aria-labelledby="edit-movie-errors"]')
  end

  it "omits the summary when there are no errors" do
    render partial: "shared/ui/form_errors", locals: {
      errors: SampleRecord.new.errors, field_ids: {}, title: "Please correct these errors", id: "edit-movie-errors"
    }

    expect(rendered).not_to have_css('[role="alert"]')
  end
end
