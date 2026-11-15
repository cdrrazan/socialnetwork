class Post < ApplicationRecord
  include PublicActivity::Common

  belongs_to :user
  has_many :comments, dependent: :destroy

  acts_as_votable
  acts_as_taggable_on :tags

  # Posts created by members have no state; posts created from the admin panel
  # are drafted as "unpublished" until an admin publishes them. The database
  # enforces the same values with the posts_valid_state check constraint.
  STATES = %w[published unpublished].freeze

  validates :title, presence: true, length: { maximum: 255 }
  validates :body, presence: true, length: { maximum: 65_535 }
  validates :state, inclusion: { in: STATES }, allow_nil: true

  scope :published, -> { where(state: [ nil, "published" ]) }
  scope :unpublished, -> { where(state: "unpublished") }
  scope :newest_first, -> { order(created_at: :desc) }
  # Ranked by net votes (cached_votes_score), then by recency.
  scope :top_rated, -> { order(cached_votes_score: :desc, created_at: :desc) }

  def publish!
    update!(state: "published")
  end

  def published?
    state.nil? || state == "published"
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
