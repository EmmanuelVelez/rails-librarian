FactoryBot.define do
  factory :borrowing do
    association :user
    association :book
    borrowed_at { Time.current }

    trait :returned do
      returned_at { Time.current }
    end

    trait :overdue do
      borrowed_at { 30.days.ago }
      due_date { 16.days.ago }
    end
  end
end
