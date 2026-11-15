FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "member#{n}" }
    email { "#{username}@example.com" }
    password { "password" }
    password_confirmation { password }

    # A member with moderator rights (the users.admin flag).
    trait :moderator do
      admin { true }
    end

    trait :with_avatar do
      after(:build) do |user|
        user.avatar.attach(
          io: Rails.root.join("spec/fixtures/files/avatar.png").open,
          filename: "avatar.png",
          content_type: "image/png"
        )
      end
    end
  end
end
