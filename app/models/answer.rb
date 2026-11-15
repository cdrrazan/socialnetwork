class Answer < ApplicationRecord
  belongs_to :question
  belongs_to :user

  validates :body, presence: true

  scope :chronological, -> { order(created_at: :asc) }

  # Attributes the ActiveAdmin filters may search on (Ransack allowlist).
  def self.ransackable_attributes(_auth_object = nil)
    %w[id body created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
