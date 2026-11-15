class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable #:confirmable

  before_save :create_permalink
  
  has_many :posts, dependent: :destroy
  has_many :comments,dependent: :destroy
  has_many :questions,dependent: :destroy
  has_many :answers,dependent: :destroy

  acts_as_voter

  has_many :authored_conversations, class_name: 'Conversation', foreign_key: 'author_id'
  has_many :received_conversations, class_name: 'Conversation', foreign_key: 'receiver_id'

  has_many :personal_messages, dependent: :destroy

  def self.search(search)
    if search
      where(["email LIKE ?","%#{search}%"])
    else
      all
    end
  end

  # Profile picture (Active Storage; previously a Paperclip attachment)
  has_one_attached :avatar do |attachable|
    attachable.variant :thumbnail, resize_to_fill: [200, 250]
    attachable.variant :medium, resize_to_limit: [300, 300]
    attachable.variant :large, resize_to_limit: [600, 600]
  end
  validate :avatar_is_an_image

  has_many :friendships
  has_many :friends, through: :friendships
  has_many :inverse_friendships, class_name: "Friendship",foreign_key: "friend_id"
  has_many :inverse_friends,through: :inverse_friendships, source: :user

  def not_friends_with?(friend_id)
    friendships.where(friend_id: friend_id).count < 1
  end

  def except_current_user(users)
    users.reject { |user| user.id == self.id }
  end


  # def to_param
  #   permalink
  #   # "#{id} #{email}".parameterize
  # end

  private

  def avatar_is_an_image
    return unless avatar.attached?
    errors.add(:avatar, "must be an image") unless avatar.content_type.to_s.start_with?("image/")
  end

  def create_permalink
    if username
      self.permalink = username.downcase
    end
  end
  
end
