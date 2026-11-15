FactoryBot.define do
  factory :conversation do
    association :author, factory: :user
    association :receiver, factory: :user

    trait :with_messages do
      after(:create) do |conversation|
        create(:personal_message, conversation: conversation, user: conversation.author, body: "Hello!")
        create(:personal_message, conversation: conversation, user: conversation.receiver, body: "Hi there!")
      end
    end
  end
end
