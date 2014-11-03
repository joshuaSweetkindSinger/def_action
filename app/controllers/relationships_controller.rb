class RelationshipsController < ApplicationController
  before_filter :require_sign_in

  # Called by the "Follow" button on a user's page to create a follow relationship from
  # the current user to the user being viewed.
  def create
    rel = params[:relationship]
    @relationship = Relationship.new(followed_id: rel[:followed_id])
    @relationship.follower_id = rel[:follower_id]
    @relationship.save

    @user = User.find(@relationship.followed_id) # This is needed by the view that will re-render the current page.
    respond_to do |format|
      format.html {redirect_to :back}
      format.js
    end
  end

  # Called by the "Unfollow" button on a user's page to remove a follow relationship from the current user
  # to the user being viewed.
  def destroy
    rel = Relationship.find(params[:id])
    rel.delete
    @user = User.find(rel.followed_id)
    respond_to do |format|
      format.html {redirect_to :back}
      format.js
    end
  end
end