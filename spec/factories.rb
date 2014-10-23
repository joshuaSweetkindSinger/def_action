FactoryGirl.define do
  factory :user do
    name 'tester'
    email 'tester@gmail.com'
    password 'foobar'
    password_confirmation 'foobar'
  end
end