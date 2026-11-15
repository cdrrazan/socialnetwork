class Answer < ApplicationRecord
  belongs_to :question, counter_cache: true
  belongs_to :user

  validates :body, presence: true, length: { maximum: 20_000 }

  scope :chronological, -> { order(created_at: :asc) }

  # Attributes the ActiveAdmin filters may search on (Ransack allowlist).
  def self.ransackable_attributes(_auth_object = nil)
    %w[id body created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
