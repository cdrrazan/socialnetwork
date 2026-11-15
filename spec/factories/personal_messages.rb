FactoryBot.define do
  factory :personal_message do
    conversation
    user { conversation.author }
    body { Faker::Lorem.sentence }
  end
end
