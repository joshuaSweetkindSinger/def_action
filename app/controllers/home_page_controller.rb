class HomePageController < PageController
  # Show the user's home page
  def show
    @micropost = current_user.microposts.build # empty micropost for form template
    @posts     = current_user.feed.paginate(page: params[:page])
    render 'static_pages/home'
  end
end