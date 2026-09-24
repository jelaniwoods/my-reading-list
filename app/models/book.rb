class Book < ApplicationRecord
  validates :title, presence: true
  validates :author, presence: true
  validates :finished, inclusion: {in: [true, false]}
end
