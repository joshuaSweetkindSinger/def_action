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

      # Action
      @user = User.find_by_email(params[:email])
      @authenticated = @user && @user.authenticate(params[:password])
      sign_in @user if @authenticated

      # UI
      if @authenticated
        redirect_back_or root_path
      else
        flash[:error] = 'Invalid email/password combination'
        redirect_to sign_in_path
      end
    end
  end

  # Cause the user to be signed out.
  def_authorization(:sign_out_of_session) {true}
  def sign_out_of_session
    sign_out
    redirect_to sign_in_path
  end

  # Create a new micropost from the home page.
  def_authorization :create_post, &:permit_action_on_self
  def create_post
    # Action
    @post, @success = @user.create_post(params[:micropost])

    # UI
    flash[:error] = @post.errors.full_messages.join(',') if !@success
    redirect_to :back
  end

  # Destroy a micropost
  def_authorization :delete_post, &:permit_post_owner
  def delete_post
    # Action
    Micropost.find(params[:micropost_id]).destroy

    # UI
    flash[:success] = 'Post deleted'
    redirect_to :back
  end

  def_authorization(:help) {true}
  def help
  end

  def_authorization :about do true; end
  def about
  end

  def_authorization :contact do true; end
  def contact
  end

  def_authorization :sign_in_page do true; end
  def sign_in_page
  end


  # ================== Users

  def_authorization :sign_up do true; end
  def sign_up
    @user ||= User.new
  end


  def_authorization :user_profile do true; end
  def user_profile
    @posts = @user.microposts.paginate(page: params[:page])
  end

  def_authorization :create_user do true; end
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

  def_authorization :edit_user, &:permit_action_on_self
  def edit_user
  end

  def_authorization :update_user, &:permit_action_on_self
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

  def_authorization :delete_user, &:permit_admin_when_not_user
  def delete_user
    # Action
    @user.destroy

    # UI
    flash[:success] = 'User deleted'
    redirect_to controller: PagesController, action: :users_index
end

  def_authorization :users_being_followed do true; end
  def users_being_followed
    @title = 'Following'
    @users = @user.followed_users.paginate(page: params[:page])
  end

  def_authorization :followers do true; end
  def followers
    @title = 'Followers'
    @users = @user.followers.paginate(page: params[:page])
  end

  # Cause the current user to follow the user whose id is params[:user_id]
  def_authorization :follow_user, &:permit_all_when_not_user
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
  def_authorization :unfollow_user do true; end
  def unfollow_user
    current_user.unfollow!(@user)
    respond_to do |format|
      format.html {redirect_to :back}
      format.js
    end
  end

  def_authorization :users_index do true; end
  def users_index
    @users = User.paginate(page: params[:page], per_page: 10)
  end
end
