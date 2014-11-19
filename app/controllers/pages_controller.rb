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

  # ======================= DEFINED ROUTES
  def_action :routes do |a|
    a.permitted? {true}
    a.main {@routes = ApplicationController.routes}
  end
  # ======================= SIGN IN / SIGN OUT / SIGN UP

  def_action :sign_in_page do |a|
    a.permitted? {true}
    a.route(name: :sign_in)
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
        redirect_to_requested_url root_path
      else
        redirect_to sign_in_path, flash: {error: 'Invalid email/password combination'}
      end
    end

    action.route(via: :post)
  end

  def_action :sign_out_page do |a|
    a.permitted? {true}
    a.main {render 'sign_out_page', layout: false}
    a.route(name: :sign_out_page)
  end

  # Cause the user to be signed out.
  def_action :sign_out_of_session do |a|
    a.permitted? {true}
    a.main {sign_out}
    a.ui {redirect_to sign_in_path}
    a.route(name: :sign_out, via: :delete)
  end

  def_action :sign_up do |a|
    a.permitted? {true}
    a.main {@user ||= User.new}
  end



  # ================ MICROPOST ACTIONS

  # Create a new micropost from the home page.
  def_action :create_post do |a|
    a.permitted? {permit_action_on_self}
    a.main {@post, @success = @user.create_post(params[:micropost])}
    a.ui do
      flash[:error] = @post.errors.full_messages.join(',') if !@success
      redirect_back
    end

    a.route(via: :post)
  end

  # Destroy a micropost
  def_action :delete_post do |a|
    a.permitted? {permit_post_owner}
    a.main {Micropost.find(params[:micropost_id]).destroy}
    a.ui do
      flash[:success] = 'Post deleted'
      redirect_back
    end
    a.route(via: :delete)
  end

  # ================== INFO PAGES
  def_action :help do |a|
    a.permitted? {true}
  end

  def_action :about do |a|
    a.permitted? {true}
  end

  def_action :contact do |a|
    a.permitted? {true}
  end

  # ================== USER ACTIONS

  # Show the home page
  def_action :home do |a|
    a.permitted? {permit_action_on_self}

    a.main do
      @micropost = current_user.microposts.build # empty micropost for form template
      @posts     = current_user.feed.paginate(page: params[:page])
    end

    a.route(name: :root, path: '/')
  end


  def_action :user_profile do |a|
    a.permitted? {true}
    a.main {@posts = @user.microposts.paginate(page: params[:page])}
    a.route(path: '/user_profile/:user_id')
  end


  def_action :create_user do |a|
    a.main do
      @user    = User.new(params[:user])
      @success = @user.save
      sign_in @user if @success && !current_user
    end

    a.ui do
      if @success
        flash[:success] = 'Welcome to the Sample App!'
        redirect_to root_path
      else
        flash[:errors] = @user.errors.full_messages
        redirect_to :sign_up
      end
    end

    a.route(via: :post)
  end

  def_action :edit_user do |a|
    a.permitted? {permit_action_on_self}
    a.route(path: '/edit_user/:user_id')
  end

  def_action :update_user do |a|
    a.permitted? {permit_action_on_self}

    a.main do
      @success = @user.update_attributes(params[:user])
      sign_in @user if (@success && (current_user == @user)) # Updating our own attributes will assign a new secure token,
                                                             # which would otherwise cause us to be logged out when current_user is evaluated on the next request,
                                                             # unless we log back in again using the new secure token.
    end

    a.ui do
      if @success
        redirect_to user_profile_path(@user), flash: {success: 'Profile Updated'}
      else
        render :edit_user
      end
    end

    a.route(via: :put)
  end


  def_action :delete_user do |a|
    a.permitted? {permit_admin_when_not_user}
    a.main {@user.destroy}
    a.ui do
      flash[:success] = 'User deleted'
      redirect_to controller: PagesController, action: :users_index
    end
    a.route(via: :delete)
  end

  def_action :users_being_followed do |a|
    a.permitted? {true}
    a.main do
      @title = 'Following'
      @users = @user.followed_users.paginate(page: params[:page])
    end
    a.route(path: '/users_being_followed/:user_id')
  end

  def_action :followers do |a|
    a.permitted? {true}
    a.main do
      @title = 'Followers'
      @users = @user.followers.paginate(page: params[:page])
    end
    a.route(path: '/followers/:user_id')
  end

  # Cause the current user to follow the user whose id is params[:user_id]
  def_action :follow_user do |a|
    a.permitted? {permit_all_when_not_user}

    a.main do
      current_user.follow!(@user)
      respond_to do |format|
        format.html do
          redirect_back
        end

        format.js
      end
    end

    a.route(via: :post)
  end

  # Cause the current user to unfollow the user whose id is params[:user_id]
  def_action :unfollow_user do |a|
    a.permitted? {true}

    a.main do
      current_user.unfollow!(@user)
      respond_to do |format|
        format.html {redirect_back}
        format.js
      end
    end

    a.route(via: :delete)
  end

  def_action :users_index do |a|
    a.permitted? {permit_action_on_self}
    a.main {@users = User.paginate(page: params[:page], per_page: 10)}
  end
end
