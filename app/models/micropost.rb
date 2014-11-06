class Micropost < ActiveRecord::Base
  MAX_CONTENT_LENGTH = 140

  attr_accessible :content

  validates :user_id, presence: true
  validates :content, presence: {present: 'yes', message: "Must have content that is neither empty nor blank"}
  validates :content, length: {maximum: MAX_CONTENT_LENGTH, message: "Cannot exceed #{MAX_CONTENT_LENGTH} chars"}

  belongs_to :user

  default_scope order: 'microposts.created_at desc'

  def self.from_users_followed_by (user)
    where('user_id in (?) or user_id = (?)', user.followed_user_ids, user.id)
  end
end
