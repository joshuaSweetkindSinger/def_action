class StaticPagesController < ApplicationController
  before_filter :block_unauthorized_post_deletion, only: [:destroy_post]


  # Create a new micropost from the home page.
  def create_post
    @micropost, success = current_user.create_post(params[:micropost])
    flash[:error] = @micropost.errors.full_messages.join(',') if !success
    redirect_to :back
  end

  # Destroy a micropost
  def destroy_post
    Micropost.find(params[:id]).destroy
    flash[:success] = 'Post deleted'
    redirect_to :back
  end

  def help
  end

  def about
  end

  def contact
  end

  private

  # Only the owner of a micropost or an admin can delete the micropost.
  def block_unauthorized_post_deletion
    @micropost = Micropost.find(params[:id])

    if !current_user.admin? && !current_user?(@micropost.user)
      redirect_to :back, notice: 'Only an admin or the owner of a post can delete a post.'
    end
  end

end