require 'spec_helper'

describe "Micropost pages" do
  subject {page}

  let(:user) {FactoryGirl.create(:user)}

  before {sign_in_using_form user}

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

  describe "micropost destruction" do
    before {FactoryGirl.create(:micropost, user: user)}

    describe "as correct user" do
      before {visit root_path}

      it "should delete a micropost" do
        expect {click_link 'Delete'}.should change(Micropost, :count).by(-1)
      end
    end
  end

  describe "when attempting to delete a micropost" do

    describe "when signed in as correct user" do
      before do
        FactoryGirl.create(:micropost, user: user)
        visit root_path
        @delete_post_action = expect {click_link('Delete')}
      end

      it "post should be deleted" do
        @delete_post_action.should change(Micropost, :count).by(-1)
      end
    end
  end
end
