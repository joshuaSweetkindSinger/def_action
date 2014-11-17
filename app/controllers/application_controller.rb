class ApplicationController < ActionController::Base
  protect_from_forgery
  include ApplicationHelper

  before_filter :get_object_references
  before_filter :check_sign_in_requirements_for_action
  before_filter :check_authorization_for_action


  # Get ids from the params object, like :user_id, and turn them into
  # actual objects, lik @user
  def get_object_references
    @user = (User.find(params[:user_id]) if params[:user_id]) || current_user
    @post = Micropost.find(params[:micropost_id]) if params[:micropost_id]
  end

  # ============ Action Definition Logic
  # This section defines def_action, which is a modified form of def that takes, in addition to the main body
  # of the method, specs called for_sign_in and for_authorization. These specify the conditions under which the
  # action may legitimately be executed. Example:
  #
  # def_action home do
  #   for_sign_in {require_sign_in} # specify that the user must be signed in before the action can be executed
  #   for_authorization {authorize_action_on_self} # specify that the current user can operate on his own record.
  #   for_action do  # specify the main body of the action before handing off to view.
  #     @micropost = current_user.microposts.build # empty micropost for form template
  #     @posts     = current_user.feed.paginate(page: params[:page])
  #   end
  # end

  # This is the toplevel method for defining an action that knows how to specify its own
  # conditions for sign in and action-authorization. Implementation-wise, it just serves
  # as syntactic syntactic wrapping to give lexical scope to the <name> of the action.
  def self.def_action (name)
    yield
  end

  # This language construct is used inside of def_action to specify the sign-in conditions under which
  # the action can be executed. It should take a block that, when executed in the context of the action,
  # which means that params will be defined, returns true if the action is permitted without sign in.
  def self.for_sign_in (&sign_in_condition_block)
    def_sign_in(name, sign_in_condition_block)
  end

  # ============ Sign In Logic
    # Most actions require a user to be signed in first. This section defines helpers
    # to aid in determining whether a user needs to be signed in. Use def_sign_in to
    # define conditions under which an action requires sign in. If no conditions are specified,
    # the default is to require sign in before an action can be executed.

    # Associate the specified sign-in-condition proc with the specified action.
    # When the controller is called upon to execute an action like :create_post,
    # it first calls the associated proc to see whether the user can take
    # the action without being signed in first.
    # If the proc returns true, then the action can be taken without signin.
    #
    @@sign_in_conditions = {}
    def self.def_sign_in (action, proc)
      @@sign_in_conditions[action] = proc
    end

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
      sign_in_condition && call(sign_in_condition)
    end

    # This method is used to declare that an action is allowed without signin.
    # It returns true to indicate that fact.
    def sign_in_not_required
      true
    end

  # ============== Authorization Logic
  # Many actions require the current user to have special permissions before
  # they can be executed. This section defines helpers
  # to aid in determining whether the current user has correct permissions to execute the requested action.
  # Use def_authorization to define the authorization conditions pertaining to an action.
  # If no authorization conditions are specified, the action will not be allowed by default, unless
  # there are no sign-in conditions, in which case the default is to allow the action. (If the action
  # can be taken without sign in, then there's no reason to prohibit it. Checking permissions would
  # require sign in first anyway.)

  # Associate the specified authorization method with the specified action.
  # When the controller is called upon to execute an action like :create_post,
  # it first calls the associated method to see whether the current user has sufficient permission to take
  # the action. If the method returns true, then the action can be taken.
  @@authorization_conditions = {}
  def self.def_authorization (action, proc)
    @@authorization_conditions ||= {}
    @@authorization_conditions[action] = proc
  end

  def check_authorization_for_action
    if !action_authorized?
      redirect_to :back, notice: 'You do not have permission to execute this action.'
    end
  end

  # Return true if the current user has permission to execute the requested action.
  # If there is no current user (not signed in), then only execute the requested action
  # if it is allowed without sign-in.
  def action_authorized?
    action_allowed_without_sign_in? ||
      ((authorization_condition = @@authorization_conditions[action_name.to_sym]) && call(authorization_condition))
  end

  # ========== Authorization Condition methods
  # These methods define typical cases for permitting an action.

  # The current user and admin can both take actions on @user.
  def authorize_action_on_self
    current_user?(@user) || current_user.admin?
  end

  # The owner of a micropost or an admin can both manipulate a post.
  def authorize_post_owner
    current_user.admin? || current_user?(@post.user)
  end

  # Allow admin to operate on @user so long as @user is not the admin himself.
  def authorize_admin_when_not_user
    current_user.admin? && !current_user?(@user)
  end

  # Allow anyone to operate on @user so long as @user is not the current user himself.
  def authorize_all_when_not_user
    !current_user?(@user)
  end

  # This operation has no authorization restrictions
  def authorize_all
    true
  end

end
