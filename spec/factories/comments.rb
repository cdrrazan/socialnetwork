FactoryBot.define do
  factory :comment do
    post
    user
    body { Faker::Lorem.sentence }
  end
end
