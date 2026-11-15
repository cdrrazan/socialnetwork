FactoryBot.define do
  factory :question do
    user
    sequence(:title) { |n| "How do I do thing number #{n}?" }
    body { Faker::Lorem.paragraph }
  end
end
