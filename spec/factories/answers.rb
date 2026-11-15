FactoryBot.define do
  factory :answer do
    question
    user
    body { Faker::Lorem.paragraph }
  end
end
