# == Schema Information
#
# Table name: users
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  email      :string(255)
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

class User < ActiveRecord::Base
  attr_accessible :email, :name, :password, :password_confirmation
  has_secure_password

  has_many :microposts, dependent: :destroy
  has_many :relationships, foreign_key: 'follower_id', dependent: :destroy
  has_many :followed_users, through: :relationships, source: :followed
  has_many :reverse_relationships, foreign_key: 'followed_id', dependent: :destroy, class_name: 'Relationship'
  has_many :followers, through: :reverse_relationships

  before_save {|user| user.email = email.downcase}
  before_save :create_member_token

  validates :name, presence: true, length: {maximum: 50}
  validates :password, length: {minimum: 6}
  validates :password_confirmation, presence: true

  VALID_EMAIL_REGEX = /\A[\w\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: {with: VALID_EMAIL_REGEX},
            uniqueness: {case_sensitive: false}

  def feed
    Micropost.from_users_followed_by(self)
  end

  def following? (followed_user)
    followed_users.include?(followed_user)
  end

  def follow! (followed_user)
    followed_users << followed_user
  end

  def unfollow! (followed_user)
    followed_users.delete(followed_user)
  end

  private
  def create_member_token
    self.remember_token = SecureRandom.urlsafe_base64
  end
end
