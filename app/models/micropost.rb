class Micropost < ActiveRecord::Base
  MAX_CONTENT_LENGTH = 140

  attr_accessible :content

  validates :user_id, presence: true
  validates :content, presence: {present: 'yes', message: "must neither be empty nor blank"}
  validates :content, length: {maximum: MAX_CONTENT_LENGTH, message: "Cannot exceed #{MAX_CONTENT_LENGTH} chars"}

  belongs_to :user

  default_scope order: 'microposts.created_at desc'

  def self.from_users_followed_by (user)
    followed_user_ids = %Q(select followed_id
                           from relationships
                           where follower_id  = :user_id)
    where("user_id in (#{followed_user_ids}) or user_id = :user_id", user_id: user.id)
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

