FactoryGirl.define do
  factory :school do
    name "Factory High"
    domain_name "factory"
    low_grade 9
    high_grade 12
    teacher_limit 100
  end

  factory :term do
    association :school
    low_period 1
    high_period 6
  end

  factory :teacher do
    association :school
    first_name "John"
    last_name "Doe"
  end

  factory :student do
    association :school
    first_name "Anon"
    last_name "Student"
  end

  factory :parent do
    association :school
    first_name "Adult"
    last_name "Student"
  end

  factory :staffer do
    association :school
    first_name "Staff"
    last_name "Staff"
  end

  factory :user do
    association :school
    first_name "Generic"
    last_name "User"
  end

  factory :department do
    association :school
    name "Math"
  end

  factory :event do
    name 'event'
    invitable_type 'Section'
    date Date.today
  end
end

