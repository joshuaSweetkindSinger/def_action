class MicropostsController < ApplicationController
  before_filter :require_sign_in
  before_filter :block_unauthorized_deletion, only: [:destroy]

  def create
    @micropost = current_user.microposts.build(params[:micropost])
    if @micropost.save
      flash[:success] = 'Micropost created!'
      redirect_to root_path
    else
      @feed_items = []
      render 'static_pages/home'
    end
  end

  def destroy
    Micropost.find(params[:id]).destroy
    flash[:success] = 'Post deleted'
    redirect_to :back
  end

  private

  # Only the owner of a micropost or an admin can delete the micropost.
  def block_unauthorized_deletion
    @micropost = Micropost.find(params[:id])

    if !current_user.admin? && !current_user?(@micropost.user)
      redirect_to root_path, notice: 'Only an admin or the owner of a post can delete a post.'
    end
  end
end
