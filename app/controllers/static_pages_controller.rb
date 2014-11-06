class StaticPagesController < ApplicationController
  def home
    if signed_in?
      @micropost = current_user.microposts.build # empty micropost for form template
      @feed_items = current_user.feed.paginate(page: params[:page])
    end
  end

  def help
  end

  def about
  end

  def contact
  end
end