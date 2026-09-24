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
class Book < ApplicationRecord
  validates :title, presence: true
  validates :author, presence: true
  validates :finished, inclusion: {in: [true, false]}
end
