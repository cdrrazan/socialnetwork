class Answer < ApplicationRecord
  belongs_to :question
  belongs_to :user

  validates :body, presence: true

  scope :chronological, -> { order(created_at: :asc) }
end
