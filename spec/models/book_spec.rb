require "rails_helper"

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

  it "accepts false for finished" do
    record = build(:book, finished: false)
    record.validate

    expect(record.errors[:finished]).to be_empty
  end
end
