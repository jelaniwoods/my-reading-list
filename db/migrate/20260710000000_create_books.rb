class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table "books", id: :uuid, default: -> { "uuidv7()" } do |t|
      t.string "title", null: false
      t.string "author", null: false
      t.text "note"
      t.boolean "finished", null: false
      t.timestamps null: false
    end
  end
end
