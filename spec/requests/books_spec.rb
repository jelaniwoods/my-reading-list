require "rails_helper"

RSpec.describe "Book", type: :request do
  around do |example|
    configuration = Rails.application.env_config
    previous = configuration["action_dispatch.show_exceptions"]
    configuration["action_dispatch.show_exceptions"] = :all
    example.run
  ensure
    configuration["action_dispatch.show_exceptions"] = previous
  end

  it "index lists accessible records" do
    record = create(:book)
    get books_path
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.text).to include(record.title)
  end

  it "show shows the requested record" do
    record = create(:book)
    get book_path(record)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.text).to include(record.title)
  end

  it "new accepts a permitted new-record request" do
    get new_book_path
    expect(response).to have_http_status(:ok)
  end

  it "create persists the submitted values" do
    title_value = "title"
    author_value = "author"
    note_value = "note"
    finished_value = true
    existing_ids = Book.pluck(:id)
    expect {
      post books_path, params: {book: {title: title_value, author: author_value, note: note_value, finished: finished_value}}
    }.to change(Book, :count).by(1)
    expect(response.status).to be_between(200, 399)
    record = Book.where.not(id: existing_ids).sole
    expect(record.title).to eq(title_value)
    expect(record.author).to eq(author_value)
    expect(record.note).to eq(note_value)
    expect(record.finished).to eq(finished_value)
  end

  it "create rejects a missing title without persisting changes" do
    author_value = "author"
    note_value = "note"
    finished_value = true
    expect {
      post books_path, params: {book: {author: author_value, note: note_value, finished: finished_value, title: nil}}
    }.not_to change(Book, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "edit accepts a permitted edit request" do
    record = create(:book)
    get edit_book_path(record)
    expect(response).to have_http_status(:ok)
  end

  it "update persists the submitted changes" do
    record = create(:book)
    title_value = "title_updated"
    author_value = "author_updated"
    note_value = "note_updated"
    finished_value = false
    expect(record.title).not_to eq(title_value)
    patch book_path(record), params: {book: {title: title_value, author: author_value, note: note_value, finished: finished_value}}
    expect(response.status).to be_between(200, 399)
    record.reload
    expect(record.title).to eq(title_value)
    expect(record.author).to eq(author_value)
    expect(record.note).to eq(note_value)
    expect(record.finished).to eq(finished_value)
  end

  it "update rejects a missing title without persisting changes" do
    record = create(:book)
    author_value = "author_updated"
    note_value = "note_updated"
    finished_value = false
    original_attributes = record.attributes
    patch book_path(record), params: {book: {author: author_value, note: note_value, finished: finished_value, title: nil}}
    expect(record.reload.attributes).to eq(original_attributes)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "destroy removes the requested record" do
    record = create(:book)
    expect {
      delete book_path(record)
    }.to change { Book.exists?(record.id) }.from(true).to(false)
    expect(response.status).to be_between(200, 399)
  end

  context "index query growth", :n_plus_one do
    populate do |n|
      @descriptors = Array.new(n) do
        record = create(:book)
        record.title
      end
    end

    warmup { get books_path }

    it "keeps query count stable as the list grows" do
      expect {
        get books_path

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.text).to include(*@descriptors)
      }.to perform_constant_number_of_queries.with_scale_factors(2, 5)
    end
  end
end
