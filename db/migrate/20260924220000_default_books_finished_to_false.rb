class DefaultBooksFinishedToFalse < ActiveRecord::Migration[8.1]
  def change
    change_column_default :books, :finished, from: nil, to: false
  end
end
