# == Schema Information
#
# Table name: books
#
#  id         :uuid             not null, primary key
#  author     :string           not null
#  finished   :boolean          default(FALSE), not null
#  note       :text
#  title      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :book, class: "Book" do
    title { "title" }
    author { "author" }
    finished { true }
  end
end
