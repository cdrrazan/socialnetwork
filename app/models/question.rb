class Question < ApplicationRecord
  belongs_to :user
  has_many :answers, dependent: :destroy

  validates :title, presence: true, length: { maximum: 255 }
  validates :body, presence: true, length: { maximum: 65_535 }

  scope :newest_first, -> { order(created_at: :desc) }

  def to_param
    "#{id} #{title}".parameterize
  end

  # Attributes the ActiveAdmin filters may search on (Ransack allowlist).
  def self.ransackable_attributes(_auth_object = nil)
    %w[id title body created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
