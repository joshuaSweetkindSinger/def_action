class UsersIndexPageController < PageController
  def show
    @users = User.paginate(page: params[:page], per_page: 10)
    render 'static_pages/users_index'
  end
end