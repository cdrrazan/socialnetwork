FactoryBot.define do
  # +user+ follows +friend+.
  factory :friendship do
    user
    association :friend, factory: :user
  end
end
