class PersonalMessage < ApplicationRecord
  belongs_to :conversation, touch: true
  belongs_to :user

  validates :body, presence: true, length: { maximum: 5_000 }
end
