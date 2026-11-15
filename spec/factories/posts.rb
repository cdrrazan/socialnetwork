FactoryBot.define do
  factory :post do
    user
    sequence(:title) { |n| "Post number #{n}" }
    body { "<p>#{Faker::Lorem.paragraph(sentence_count: 3)}</p>" }

    # Drafted from the admin panel, awaiting publication.
    trait :draft do
      state { "unpublished" }
    end

    trait :explicitly_published do
      state { "published" }
    end

    trait :tagged do
      tag_list { "ruby, rails" }
    end
  end
end
