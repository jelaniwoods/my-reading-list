class BooksController < ApplicationController
  PAGE_LIMIT = 24

  def index
    relation = Book.order(:id)
    @pagy, @books = pagy(:offset, relation, limit: PAGE_LIMIT)
    @new_book = Book.new
  end

  def show
    @book = Book.find(params[:id])
  end

  def new
    @book = Book.new
  end

  def create
    @book = Book.new(create_book_params)
    if @book.save
      redirect_to book_path(@book), status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @book = Book.find(params[:id])
  end

  def update
    @book = Book.find(params[:id])
    if @book.update(update_book_params)
      redirect_to book_path(@book), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @book = Book.find(params[:id])
    @book.destroy!
    redirect_to books_path, status: :see_other
  end

  private

  def create_book_params
    params.expect(book: [:title, :author, :note, :finished])
  end

  def update_book_params
    params.expect(book: [:title, :author, :note, :finished])
  end
end
