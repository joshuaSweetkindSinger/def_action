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
# is handled by the functions def_sign_in() and def_authorization()

# Two very common objects in this app are @user and @micropost. They are dereferenced
# from the params by a before_filter and are available to each action defined below,
# so long as :user_id and/or :micropost_id are given in params, respectively.

class PagesController < ApplicationController
  def initialize
    super
    @sign_in_conditions = {} # Maps action symbols to methods which, when run, return true if the action is allowed without signin.
    @authorization_conditions = {} # Maps action symbols to methods which, when run, return true if the action is authorized for the current user.
  end

  # Show the home page
  def_authorization :home, :authorize_all
  def_action home do
    for_sign_in {require_sign_in}

    for_authorization {authorize_all}

    for_action do
      @micropost = current_user.microposts.build # empty micropost for form template
      @posts     = current_user.feed.paginate(page: params[:page])
    end
  end

  # Cause the user to be signed in with the supplied credentials
  def_sign_in :sign_in_to_session, :sign_in_not_required
  def sign_in_to_session

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

  # Cause the user to be signed out.
  def_sign_in :sign_out_of_session, :sign_in_not_required
  def sign_out_of_session
    sign_out
    redirect_to sign_in_path
  end

  # Create a new micropost from the home page.
  def_authorization :create_post, :authorize_action_on_self
  def create_post
    # Action
    @post, @success = @user.create_post(params[:micropost])

    # UI
    flash[:error] = @post.errors.full_messages.join(',') if !@success
    redirect_to :back
  end

  # Destroy a micropost
  def_authorization :delete_post, :authorize_post_owner
  def delete_post
    # Action
    Micropost.find(params[:micropost_id]).destroy

    # UI
    flash[:success] = 'Post deleted'
    redirect_to :back
  end

  def_sign_in :help, :sign_in_not_required
  def help
  end

  def_sign_in :about, :sign_in_not_required
  def about
  end

  def_sign_in :contact, :sign_in_not_required
  def contact
  end

  def_sign_in :sign_in_page, :sign_in_not_required
  def sign_in_page
  end


  # ================== Users

  def_sign_in :sign_up, :sign_in_not_required
  def sign_up
    @user ||= User.new
  end


  def_sign_in :user_profile, :sign_in_not_required
  def user_profile
    @posts = @user.microposts.paginate(page: params[:page])
  end

  def_sign_in :create_user, :sign_in_not_required
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

  def_authorization :edit_user, :authorize_action_on_self
  def edit_user
  end

  def_authorization :update_user, :authorize_action_on_self
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

  def_authorization :delete_user, :authorize_admin_when_not_user
  def delete_user
    # Action
    @user.destroy

    # UI
    flash[:success] = 'User deleted'
    redirect_to controller: PagesController, action: :users_index
end

  def_authorization :users_being_followed, :authorize_all
  def users_being_followed
    @title = 'Following'
    @users = @user.followed_users.paginate(page: params[:page])
  end

  def_authorization :followers, :authorize_all
  def followers
    @title = 'Followers'
    @users = @user.followers.paginate(page: params[:page])
  end

  # Cause the current user to follow the user whose id is params[:user_id]
  def_authorization :follow_user, :authorize_all_when_not_user
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
  def_authorization :unfollow_user, :authorize_all
  def unfollow_user
    current_user.unfollow!(@user)
    respond_to do |format|
      format.html {redirect_to :back}
      format.js
    end
  end

  def_authorization :users_index, :authorize_all
  def users_index
    @users = User.paginate(page: params[:page], per_page: 10)
  end
end
