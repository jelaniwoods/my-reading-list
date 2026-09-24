FactoryBot.define do
  factory :book, class: "Book" do
    title { "title" }
    author { "author" }
    finished { true }
  end
end
