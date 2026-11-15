# A one-directional "follow": +user+ follows +friend+.
class Friendship < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: "User"

  validates :friend_id, uniqueness: { scope: :user_id }
  validate :cannot_follow_self

  private

  def cannot_follow_self
    errors.add(:friend, "can't be yourself") if user_id.present? && user_id == friend_id
  end
end
