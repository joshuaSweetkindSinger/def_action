FactoryGirl.define do
  factory :user do
    name "Joshua Singer"
    email "joshua@singer.com"
    password "foobar"
    password_confirmation "foobar"
  end
end