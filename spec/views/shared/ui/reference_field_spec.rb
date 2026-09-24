require "rails_helper"

RSpec.describe "shared/ui/_reference_field", type: :view do
  {
    "unpaired labels" => %w[draft published],
    "grouped options" => [["Group", [["Draft", "draft"]]]],
    "per-option HTML attributes" => [["Draft", "draft", {disabled: true}]]
  }.each do |description, options|
    it "rejects #{description} before rendering mismatched native and enhanced controls" do
      expect do
        render inline: <<~ERB, locals: {options: options}
          <%= form_with scope: :article, url: "/articles" do |form| %>
            <%= render "shared/ui/reference_field", form: form, attribute: :status, label: "Status", value: "draft", options: options %>
          <% end %>
        ERB
      end.to raise_error(ActionView::Template::Error, /reference_field options must be \[label, value\] pairs/)
    end
  end
end
