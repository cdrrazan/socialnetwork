class Comment < ApplicationRecord
  include PublicActivity::Common

  belongs_to :post
  belongs_to :user

  validates :body, presence: true

  scope :chronological, -> { order(created_at: :asc) }
end
