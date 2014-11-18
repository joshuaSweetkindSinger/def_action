# This is the one and only controller for the application.
# Each method, except "initialize", is a controller action with a
# corresponding route named /<action>. For example, the method "home" is a controller action
# invoked via the route "/home".
#
# Most of the actions cannot be invoked unless the user has signed in, which action
# makes him become the current_user(). This check is handled by a before_filter defined on the
# parent ApplicationController, which takes a strict view, requiring sign in for all things
# that are not explicitly allowed without sign in.
#
# Many of the actions cannot be invoked unless the user has signed in and has appropriate
# authorization to invoke the action. These checks are handled by before filters on
# # the parent ApplicationController, which
# take a strict view, disallowing all actions unless the action has explicitly been declared
# to be allowable without signin, or unless the action has explicitly been declared
# to be authorized for the current user. Making declarations regarding sign-in and authorization
# is handled by the functions def_authorization() and def_authorization()

# Two very common objects in this app are @user and @micropost. They are dereferenced
# from the params by a before_filter and are available to each action defined below,
# so long as :user_id and/or :micropost_id are given in params, respectively.

class PagesController < ApplicationController
  def initialize
    super
  end

  # Show the home page
  def_action :home do |action|
    action.permitted? {permit_action_on_self}

    action.main do
      @micropost = current_user.microposts.build # empty micropost for form template
      @posts     = current_user.feed.paginate(page: params[:page])
    end
  end


  # Cause the user to be signed in with the supplied credentials
  def_action :sign_in_to_session do |action|
    action.permitted? {true}

    action.main do
      @user = User.find_by_email(params[:email])
      @authenticated = @user && @user.authenticate(params[:password])
      sign_in @user if @authenticated
    end

    action.ui do
      if @authenticated
        redirect_to root_path # redirect_back_or root_path
      else
        flash[:error] = 'Invalid email/password combination'
        redirect_to sign_in_path
      end
    end
  end

  # Cause the user to be signed out.
  def_action :sign_out_of_session do |a|
    a.permitted? {true}
    a.main {sign_out}
    a.ui {redirect_to sign_in_path}
  end

  # Create a new micropost from the home page.
  def_action :create_post do |a|
    a.permitted? {permit_action_on_self}
    a.main {@post, @success = @user.create_post(params[:micropost])}
    a.ui do
      flash[:error] = @post.errors.full_messages.join(',') if !@success
      redirect_to :back
    end
  end

  # Destroy a micropost
  def_action :delete_post do |a|
    a.permitted? {permit_post_owner}
    a.main {Micropost.find(params[:micropost_id]).destroy}
    a.ui do
      flash[:success] = 'Post deleted'
      redirect_to :back
    end
  end

  def_permission(:help) {true}
  def help
  end

  def_permission :about do true; end
  def about
  end

  def_permission :contact do true; end
  def contact
  end

  def_permission :sign_in_page do true; end
  def sign_in_page
  end


  # ================== Users

  def_permission :sign_up do true; end
  def sign_up
    @user ||= User.new
  end


  def_permission :user_profile do true; end
  def user_profile
    @posts = @user.microposts.paginate(page: params[:page])
  end

  def_permission :create_user do true; end
  def create_user
    # Action
    @user    = User.new(params[:user])
    @success = @user.save
    sign_in @user if @success

    # UI
    if @success
      flash[:success] = 'Welcome to the Sample App!'
      redirect_to root_path
    else
      flash[:errors] = @user.errors.full_messages
      redirect_to :sign_up
    end

  end

  def_permission :edit_user, &:permit_action_on_self
  def edit_user
  end

  def_permission :update_user, &:permit_action_on_self
  def update_user
    # Action
    @success = @user.update_attributes(params[:user])

    # UI
    if @success
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      redirect_to :edit_user
    end
  end

  def_permission :delete_user, &:permit_admin_when_not_user
  def delete_user
    # Action
    @user.destroy

    # UI
    flash[:success] = 'User deleted'
    redirect_to controller: PagesController, action: :users_index
end

  def_permission :users_being_followed do true; end
  def users_being_followed
    @title = 'Following'
    @users = @user.followed_users.paginate(page: params[:page])
  end

  def_permission :followers do true; end
  def followers
    @title = 'Followers'
    @users = @user.followers.paginate(page: params[:page])
  end

  # Cause the current user to follow the user whose id is params[:user_id]
  def_permission :follow_user, &:permit_all_when_not_user
  def follow_user
    current_user.follow!(@user)
    respond_to do |format|
      format.html do
        redirect_to :back
      end

      format.js
    end
  end

  # Cause the current user to unfollow the user whose id is params[:user_id]
  def_permission :unfollow_user do true; end
  def unfollow_user
    current_user.unfollow!(@user)
    respond_to do |format|
      format.html {redirect_to :back}
      format.js
    end
  end

  def_permission :users_index, &:permit_action_on_self
  def users_index
    @users = User.paginate(page: params[:page], per_page: 10)
  end
end
