# This file contains helper methods for our rspec tests, which are defined in ../requests.
# RSpec automatically includes all the files in the "support" directory that this file lives in.

include ApplicationHelper

def sign_in (user)
  visit signin_path
  fill_in "Email", with: user.email
  fill_in "Password", with: user.password
  click_button 'Sign in'
  cookies[:remember_token] = user.remember_token # Sign in when not using capybara as well.
end

RSpec::Matchers.define :have_error_message do |message|
  match do |page|
    page.should have_selector('div.alert.alert-error', text: message)
  end
end



