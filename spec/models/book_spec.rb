require "rails_helper"

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
RSpec.describe Book, type: :model do
  it "is valid with the required data" do
    expect(build(:book)).to be_valid
  end

  it "requires title" do
    record = build(:book, title: nil)
    record.validate

    expect(record.errors[:title]).not_to be_empty
  end

  it "requires author" do
    record = build(:book, author: nil)
    record.validate

    expect(record.errors[:author]).not_to be_empty
  end

  it "allows note to be absent" do
    record = build(:book, note: nil)
    record.validate

    expect(record.errors[:note]).to be_empty
  end

  it "requires finished" do
    record = build(:book, finished: nil)
    record.validate

    expect(record.errors[:finished]).not_to be_empty
  end

  it "starts unfinished" do
    expect(Book.new.finished).to be(false)
  end

  it "saves as unfinished when finished is not given" do
    book = Book.create!(title: "Beloved", author: "Toni Morrison")

    expect(book.reload.finished).to be(false)
  end

  it "accepts false for finished" do
    record = build(:book, finished: false)
    record.validate

    expect(record.errors[:finished]).to be_empty
  end
end
