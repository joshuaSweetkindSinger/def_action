require 'spec_helper'

describe UsersController do
  let(:user) {FactoryGirl.create(:user)}
  let(:other_user) {FactoryGirl.create(:user)}

  before {sign_in_using_form user}

  describe "When following a user" do
    it "should increment the relationship count" do
      expect do
        xhr :post, :follow, id: other_user.id
      end.should change(Relationship, :count).by(1)
    end

    it "should respond with success" do
        xhr :post, :follow, id: other_user.id
        response.should be_success
    end
  end

  describe "When attempting to follow oneself" do
    it "should not increment the relationship count" do
      expect do
        xhr :post, :follow, id: user.id
      end.should change(Relationship, :count).by(0)
    end

    it "should respond with failure" do
      xhr :post, :follow, id: user.id
      response.should_not be_success
    end
  end

  describe "When unfollowing a user" do
    before {user.follow!(other_user)}

    it "should decrement the relationship count" do
      expect do
        xhr :delete, :unfollow, id: other_user.id
      end.should change(Relationship, :count).by(-1)
    end

    it "should respond with success" do
      xhr :delete, :unfollow, id: other_user.id
      response.should be_success
    end
  end
end