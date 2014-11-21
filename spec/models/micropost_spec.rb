require 'spec_helper'

describe Micropost do

  let(:user) {FactoryGirl.create(:user)}

  before {@micropost = user.microposts.build(content: 'here is a micropost')}

  subject {@micropost}

  describe "basic api" do
    it {should respond_to(:user_id)}
    it {should respond_to(:content)}
    it {should respond_to(:user)}
    its(:user) {should == user}

    it {should be_valid}
  end

  describe "accessible attributes" do
    it "should not allow access to user id" do
      expect do
        Micropost.new(user_id: user.id)
      end.should raise_error(ActiveModel::MassAssignmentSecurity::Error)
    end
  end

  describe "when user_id is not present" do
    before {@micropost.user_id = nil}
    it {should_not be_valid}
  end

  describe "with blank content" do
    before {@micropost.content = '  '}
    it {should_not be_valid}
  end

  describe "with empty content" do
    before {@micropost.content = ''}
    it {should_not be_valid}
  end

  describe "with over-long post" do
    before {@micropost.content = 'a' * (Micropost::MAX_CONTENT_LENGTH + 1)}
    it {should_not be_valid}
  end

  describe "when attempting to delete a micropost" do

    let(:user1) {FactoryGirl.create(:user)}
    let(:user2) {FactoryGirl.create(:user)}
    let(:admin) {FactoryGirl.create(:admin)}
    let(:post1) {FactoryGirl.create(:micropost, user: user1)}
    let (:post2) {FactoryGirl.create(:micropost, user: user2)}

    describe "when not an admin or an owner of the micropost" do
      it "post should not be deleted" do
      end
    end

    describe "when owner of the micropost" do
      it "post should be deleted" do
      end
    end

    describe "when an admin" do
      it "post should be deleted" do
      end
    end
  end
end
# == Schema Information
#
# Table name: microposts
#
#  id         :integer         not null, primary key
#  content    :string(255)
#  user_id    :integer
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

