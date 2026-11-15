class Post < ApplicationRecord
  include PublicActivity::Common

  belongs_to :user
  has_many :comments, dependent: :destroy

  acts_as_votable
  acts_as_taggable_on :tags

  validates :title, :body, presence: true

  # Posts created by users have no state; posts created from the admin panel
  # are drafted as "unpublished" until an admin publishes them.
  scope :published, -> { where(state: [nil, "published"]) }
  scope :unpublished, -> { where(state: "unpublished") }
  scope :newest_first, -> { order(created_at: :desc) }

  def publish!
    update!(state: "published")
  end

  def to_param
    "#{id} #{title}".parameterize
  end

  # Posts most similar to this one, by TF-IDF cosine similarity of their bodies.
  def similar_posts(limit: 5)
    PostRecommender.new(self).similar(limit: limit)
  end

  # Attributes the ActiveAdmin filters may search on (Ransack allowlist).
  def self.ransackable_attributes(_auth_object = nil)
    %w[id title body state created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
