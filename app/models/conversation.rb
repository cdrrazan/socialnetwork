# A private, two-person message thread.
class Conversation < ApplicationRecord
  belongs_to :author, class_name: "User"
  belongs_to :receiver, class_name: "User"

  has_many :personal_messages, -> { order(created_at: :asc) }, dependent: :destroy

  validates :author, uniqueness: { scope: :receiver }

  scope :participating, ->(user) { where(author: user).or(where(receiver: user)) }
  scope :between, lambda { |sender_id, receiver_id|
    where(author_id: sender_id, receiver_id: receiver_id)
      .or(where(author_id: receiver_id, receiver_id: sender_id))
  }

  # The other participant, from +user+'s point of view.
  def with(user)
    author == user ? receiver : author
  end

  def participates?(user)
    author == user || receiver == user
  end
end
