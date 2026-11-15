class User < ApplicationRecord
  # Others available are: :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :questions, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :personal_messages, dependent: :destroy

  has_many :authored_conversations, class_name: "Conversation", foreign_key: :author_id,
                                    inverse_of: :author, dependent: :destroy
  has_many :received_conversations, class_name: "Conversation", foreign_key: :receiver_id,
                                    inverse_of: :receiver, dependent: :destroy

  # People this user follows, and people following this user.
  has_many :friendships, dependent: :destroy
  has_many :friends, through: :friendships
  has_many :inverse_friendships, class_name: "Friendship", foreign_key: :friend_id,
                                 inverse_of: :friend, dependent: :destroy
  has_many :inverse_friends, through: :inverse_friendships, source: :user

  acts_as_voter

  # Profile picture (Active Storage; previously a Paperclip attachment)
  has_one_attached :avatar do |attachable|
    attachable.variant :thumbnail, resize_to_fill: [200, 250]
    attachable.variant :medium, resize_to_limit: [300, 300]
    attachable.variant :large, resize_to_limit: [600, 600]
  end

  validates :username, presence: true, uniqueness: { case_sensitive: false },
                       format: { with: /\A[a-zA-Z0-9_.-]+\z/, message: "may only contain letters, numbers, _ . and -" }
  validate :avatar_is_an_image

  before_save :assign_permalink

  scope :alphabetical, -> { order(:username) }

  def self.search(query)
    return all if query.blank?

    pattern = "%#{sanitize_sql_like(query)}%"
    where("email LIKE :q OR username LIKE :q", q: pattern)
  end

  def following?(user)
    friendships.exists?(friend_id: user.id)
  end

  def display_name
    username.presence || email
  end

  # Attributes the ActiveAdmin filters may search on (Ransack allowlist).
  def self.ransackable_attributes(_auth_object = nil)
    %w[id username email admin created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  private

  def avatar_is_an_image
    return unless avatar.attached?

    errors.add(:avatar, "must be an image") unless avatar.content_type.to_s.start_with?("image/")
  end

  def assign_permalink
    self.permalink = username.downcase if username.present?
  end
end
