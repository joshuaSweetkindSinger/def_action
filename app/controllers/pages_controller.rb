# This is the one and only controller for the application.
# Each method, except "initialize", is a controller action with a
# corresponding route named /<action>. For example, the method "home" is a controller action
# invoked via the route "/home".
#
# Most of the actions cannot be invoked unless the user has signed in, which action
# makes him become the current_user().
#
# Many of the actions cannot be invoked unless the user has signed in and has appropriate
# authorization to invoke the action. These checks are handled by before filters, which
# take a strict view, disallowing all actions unless the action has explicitly been declared
# to be allowable without signin, or unless the action has explicitly been declared
# to be authorized for the current user. Making declarations regarding sign-in and authorization
# is handled by the functions def_sign_in() and def_authorization()

class PagesController < ApplicationController
  before_filter :check_sign_in_requirements_for_action
  before_filter :check_authorization_for_action

  def initialize
    super
    @sign_in_conditions = {} # Maps action symbols to methods which, when run, return true if the action is allowed without signin.
    @authorization_conditions = {} # Maps action symbols to methods which, when run, return true if the action is authorized for the current user.
  end

  # Show the home page
  def_authorization :home, :authorize_all
  def home
    @micropost = current_user.microposts.build # empty micropost for form template
    @posts     = current_user.feed.paginate(page: params[:page])
  end

  # Cause the user to be signed in with the supplied credentials
  def_sign_in :sign_in_to_session, :sign_in_not_required
  def sign_in_to_session
    @user = User.find_by_email(params[:email])
    @authenticated = @user && @user.authenticate(params[:password])
    sign_in user if @authenticated
  end

  # Cause the user to be signed out.
  def_sign_in :sign_out_of_session, :sign_in_not_required
  def sign_out_of_session
    sign_out
  end

  # Create a new micropost from the home page.
  def_authorization :create_post, :authorize_current_user_or_admin
  def create_post
    @post, @success = @user.create_post(params[:micropost])
  end

  # Destroy a micropost
  def_authorization :destroy_post, :authorize_post_owner_or_admin
  def delete_post
    Micropost.find(params[:micropost_id]).destroy
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
    @user = User.find(params[:user_id])
    @posts = @user.microposts.paginate(page: params[:page])
  end

  def_sign_in :create_user_from_new_user_form, :sign_in_not_required
  def create_user_from_new_user_form
    @user    = User.new(params[:user])
    @success = @user.save
    sign_in @user if @success
  end

  def_authorization :edit_user, :authorize_current_user_or_admin
  def edit_user
  end

  def_authorization :edit_user, :authorize_current_user_or_admin
  def update_user_from_edit_user_form
    @success = @user.update_attributes(params[:user])
  end

  def_authorization :delete_user, :authorize_admin_when_not_user
  def delete_user
    @user.destroy
  end

  def_authorization :show_users_being_followed, :authorize_all
  def show_users_being_followed
    @title = 'Following'
    @users = @user.followed_users.paginate(page: params[:page])
  end

  def_authorization :show_followers, :authorize_all
  def show_followers
    @title = 'Followers'
    @users = @user.followers.paginate(page: params[:page])
  end

  # Cause the current user to follow the user whose id is params[:user_id]
  def_authorization :follow, :authorize_all_when_not_user
  def follow
    current_user.follow!(@user)
    respond_to do |format|
      format.html
      format.js
    end
  end

  # Cause the current user to unfollow the user whose id is params[:user_id]
  def_authorization :follow, :authorize_all
  def unfollow
    @user = User.find(params[:user_id])
    current_user.unfollow!(@user)
    respond_to do |format|
      format.html {redirect_to :back}
      format.js
    end
  end

  def_authorization :follow, :authorize_all
  def users_index
    @users = User.paginate(page: params[:page], per_page: 10)
  end
end
