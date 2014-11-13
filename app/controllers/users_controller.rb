class UsersController < PageController
  before_filter :block_unauthorized_deletion, only: [:destroy]
  before_filter :block_unauthorized_modification, only: [:edit, :update]

  def new
    @user ||= User.new
  end

  def show
    @user = User.find(params[:id])
    @posts = @user.microposts.paginate(page: params[:page])
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:success] = 'Welcome to the Sample App!'
      sign_in @user
      redirect_to @user
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(params[:user])
      flash[:success] = "Profile updated"
      sign_in @user
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = 'User deleted'
    redirect_to users_path
  end

  def following
    @title = 'Following'
    @user = User.find(params[:id])
    @users = @user.followed_users.paginate(page: params[:page])
    render 'show_follow'
  end

  def followers
    @title = 'Followers'
    @user = User.find(params[:id])
    @users = @user.followers.paginate(page: params[:page])
    render 'show_follow'
  end

  # Cause the current user to follow the user whose id is params[:id]
  def follow
    @user = User.find(params[:id])
    current_user.follow!(@user) unless @user == current_user
    respond_to do |format|
      format.html {redirect_to :back}
      format.js do
        if @user == current_user
          render 'follow_button' # don't toggle button if we attempted to follow_button ourselves
        else
          render 'unfollow_button'
        end
      end
    end
  end

  # Cause the current user to unfollow the user whose id is params[:id]
  def unfollow
    @user = User.find(params[:id])
    current_user.unfollow!(@user)
    respond_to do |format|
      format.html {redirect_to :back}
      format.js do
        render 'follow_button'
      end
    end
  end


  private

  # In general, a user may only alter his own data, not the data of another, unless the user
  # is also an admin.
  def block_unauthorized_modification
    @user = User.find(params[:id])

    if !current_user?(@user) && !current_user.admin?
      redirect_to root_path, notice: 'You cannot alter data of another user.'
    end
  end

  # Only an admin can delete another user.
  # No user can delete himself.
  def block_unauthorized_deletion
    @user = User.find(params[:id])

    if !current_user.admin?
      redirect_to root_path, notice: 'Only an admin can delete another user.'
    end

    if current_user?(@user)
      redirect_to root_path, notice: 'No user can delete himself.'
    end
  end
end
