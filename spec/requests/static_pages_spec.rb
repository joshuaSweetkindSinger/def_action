require 'spec_helper'

describe "Static pages" do
  subject {page}
  describe "Home page" do
    before {visit root_path}
    it {should have_selector('h1', text: 'Welcome to the Sample App')}
    it {should have_selector('title', text: full_title(''))}
  end

  describe "Help page" do
    before {visit help_path}
    it {should have_selector('h1', text: "Help")}
    it {should have_selector('title', text: full_title('Help'))}
  end

  describe "About page" do
    before {visit about_path}
    it {should have_selector('h1', text: 'About Us')}
    it {should have_selector('title', text: full_title('About Us'))}
  end

  describe "Contact page" do
    before {visit contact_path}
    it {should have_selector('h1', text: 'Contact Us')}
    it {should have_selector('title', text: full_title('Contact Us'))}
  end

  describe "for signed-in users" do
    let(:user) {FactoryGirl.create(:user)}
    before do
      FactoryGirl.create(:micropost, user: user, content: "this is a micropost")
      FactoryGirl.create(:micropost, user: user, content: "this is another micropost")
      sign_in(user)
      visit root_path
    end

    it "should render the user's feed" do
      user.feed.each do |item|
      page.should have_selector("li##{item.id}", text: item.content)
      end
    end
  end
end
