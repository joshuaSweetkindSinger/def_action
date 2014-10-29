require 'spec_helper'

describe "Micropost pages" do
  subject {page}

  let(:user) {FactoryGirl.create(:user)}

  before {sign_in user}

  describe "micropost creation" do
    before {visit root_path}

    describe "with invalid information" do
      it "should not create a micropost" do
        expect {click_button "Post"}.should_not change(Micropost, :count)
      end

      describe "error messages" do
        before {click_button "Post"}
        it {should have_content('error')}
      end
    end

    describe "with valid information" do
      before {fill_in 'micropost_content', with: 'This is a micropost'}
      it "should create a micropost" do
        expect {click_button "Post"}.should change(Micropost, :count).by(1)
      end
    end
  end

  describe "when attempting to delete a micropost" do
    let(:user1) {FactoryGirl.create(:user)}
    let(:user2) {FactoryGirl.create(:user)}
    let(:admin) {FactoryGirl.create(:admin)}
    let(:post1) {FactoryGirl.create(:micropost, user: user1)}
    let (:post2) {FactoryGirl.create(:micropost, user: user2)}

    before {sign_in user2}

    describe "when not signed in" do
      it "post should not be deleted" do
      end
    end

    describe "when signed in" do
      it "post should be deleted" do
      end
    end

  end
end
