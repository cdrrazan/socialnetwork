class Comment < ApplicationRecord
  include PublicActivity::Common

  belongs_to :post, counter_cache: true
  belongs_to :user

  validates :body, presence: true, length: { maximum: 10_000 }

  scope :chronological, -> { order(created_at: :asc) }
end
