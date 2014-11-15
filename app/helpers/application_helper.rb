module ApplicationHelper
  module ClassMethods
    @@sign_in_conditions = {}
    @@authorization_conditions = {}

    # Associate the specified sign-in-condition method with the specified action.
    # When the controller is called upon to execute an action like :create_post,
    # it first calls the associated method to see whether the user can take
    # the action without being signed in first.
    # If the method returns true, then the action can be taken without signin.
    def def_sign_in (action, method)
      @@sign_in_conditions ||= {}
      @@sign_in_conditions[action] = method
    end

    # Associate the specified authorization method with the specified action.
    # When the controller is called upon to execute an action like :create_post,
    # it first calls the associated method to see whether the user has sufficient permission to take
    # the action. If the method returns true, then the action can be taken.
    def def_authorization (action, method)
      @@authorization_conditions ||= {}
      @@authorization_conditions[action] = method
    end
  end


  # Add the class methods to any class that includes this module.
  def self.included (base)
    base.extend(ClassMethods)
  end

  # ============ Sign In Logic
  # Most actions require a user to be signed in first. This section defines helpers
  # to aid in determining whether a user needs to be signed in. Use def_sign_in to
  # define conditions under which an action requires sign in. If no conditions are specified,
  # the default is to require sign in before an action can be executed.


  # Check to see whether the requested action requires sign in first, and,
  # if so, redirect a not-yet-signed in user to the sign in page.
  def check_sign_in_requirements_for_action
    if !signed_in? && !action_allowed_without_sign_in?
      cache_requested_url
      redirect_to sign_in_path, notice: 'Please sign in.'
    end
  end

  # Return true if the current action is allowed without sign in.
  # Implementation: @sign_in_conditions is a hash mapping action names
  # to methods. Find the method associated with the current action and call it.
  # If this method returns true, then the action is allowed without signin. If no method
  # is associated with the current action, then sign in is required by default.
  def action_allowed_without_sign_in?
    sign_in_condition = @@sign_in_conditions[action_name.to_sym]
    sign_in_condition && send(sign_in_condition)
  end

  # This method is used to declare that an action is allowed without signin.
  # It returns true to indicate that fact.
  def sign_in_not_required
    true
  end


  # ============== Authorization Logic
  # Many actions require the user to have special permissions before
  # they can be executed. This section defines helpers
  # to aid in determining whether a user has correct permissions to execute the requested action.
  # Use def_authorization to define the authorization conditions pertaining to an action.
  # If no authorization conditions are specified, the action will not be allowed by default, unless
  # there are no sign-in conditions, in which case the default is to allow the action. (If the action
  # can be taken without sign in, then there's no reason to prohibit it. Checking permissions would
  # require sign in first anyway.)

  def check_authorization_for_action
    if !action_authorized?
      redirect_to :back, notice: 'You do not have permission to execute this action.'
    end
  end

  def action_authorized?
    action_allowed_without_sign_in? || ((authorization_condition = @@authorization_conditions[action_name.to_sym]) && send(authorization_condition))
  end


  # The current user and admin can both take actions on @user.
  def authorize_current_user_or_admin
    @user = User.find(params[:user_id]) || current_user
    current_user?(@user) || current_user.admin?
  end

  # The owner of a micropost or an admin can both manipulate a post.
  def authorize_post_owner_or_admin
    @user = User.find(params[:user_id])
    @post = Micropost.find(params[:post_id])
    current_user.admin? || current_user?(@post.user)
  end

  # Allow admin to operate on @user so long as @user is not the admin himself.
  def authorize_admin_when_not_user
    @user = User.find(params[:user_id])

    current_user.admin? && !current_user?(@user)
  end

  # Allow anyone to operate on @user so long as @user is not the current user himself.
  def authorize_all_when_not_user
    @user = User.find(params[:user_id])
    !current_user?(@user)
  end

  # This operation has no authorization restrictions
  def authorize_all
    true
  end


# ========================= Auxiliaries



  # Returns the full title on a per-page basis.
  def full_title(page_title)
    base_title = "Sample App"
    if page_title.empty?
      base_title
    else
      "#{ base_title} | #{ page_title}"
    end
  end

  # Generate a delete button that allows the specified post to be deleted,
  # if the current user has privileges; otherwise, return the empty string.
  def gen_button_for_delete_post (post)
    return '' if !signed_in?

    if current_user?(post.user) || current_user.admin?
      link_to('Delete',
              {
                controller: 'static_pages',
                action:     'destroy_post',
                id:         post
              },
              method: :delete,
              confirm: 'Really delete this post?',
              title: post.content
      )
    end
  end

  def sign_in (user)
    cookies.permanent[:remember_token] = user.remember_token
    self.current_user = user
  end

  def sign_out
    self.current_user = nil
    cookies.delete(:remember_token)
  end

  def current_user= (u)
    @current_user = u
  end

  def current_user
    @current_user ||= signed_in? && User.find_by_remember_token(remember_token)
  end

  # Returns true when the specified user is the current user; otherwise, false.
  def current_user? (u)
    u == current_user
  end

  def signed_in?
    remember_token
  end

  def remember_token
    cookies[:remember_token]
  end

  # Take the user to the saved ":return_to" page, or to the specified default
  # page if there is no :return_to page saved for the session.
  def redirect_back_or (default)
    redirect_to(session[:return_to] || default)
    session.delete(:return_to)
  end

  # Save the requested path to the :return_to key on the session, for access later.
  def cache_requested_url
    session[:return_to] = request.fullpath
  end

  # Save the path of the current url so that we can return to it on redirect_to
  # For example, when deleting a micropost from a page, we delete the post and then
  # issue a redirect back to the current page.
  def cache_current_url
    session[:current_url] = request.fullpath
  end

  def gravatar_for (user, options = {size: 50})
    gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
    gravatar_url = "http://www.gravatar.com/avatar/#{gravatar_id}?s=#{options[:size]}"
    image_tag(gravatar_url, alt: user.name, class: "gravatar")
  end

end
