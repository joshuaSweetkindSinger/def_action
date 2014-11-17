class ApplicationController < ActionController::Base
  protect_from_forgery
  include ApplicationHelper

  before_filter :get_object_references
  before_filter :check_authorization_for_action


  # Get ids from the params object, like :user_id, and turn them into
  # actual objects, lik @user
  def get_object_references
    @user = (User.find(params[:user_id]) if params[:user_id]) || current_user
    @post = Micropost.find(params[:micropost_id]) if params[:micropost_id]
  end

  # ============ Action Definition Logic
  # This section defines def_action, which is a modified form of def that takes, in addition to the main body
  # of the method, a spec called for_authorization. This specifies the conditions under which the
  # action may legitimately be executed. The example below defines a controller action named 'home'
  # that that allows all users to invoke it (once signed in).
  #
  # def_action :home do |action|
  #   action.for_authorization {authorize_action_on_self} # specify that all (signed-in) users can request this action.
  #   action.main do  # specify the main body of the action before handing off to view.
  #     @micropost = current_user.microposts.build # empty micropost for form template
  #     @posts     = current_user.feed.paginate(page: params[:page])
  #   end
  # end


  # This is the toplevel method for defining an action that knows how to specify its own
  # conditions for sign in and action-authorization. Implementation-wise, it just serves
  # as syntactic syntactic wrapping to give lexical scope to the <name> of the action.
  def self.def_action (action_name)
    puts "defining action #{action_name}"
    yield ActionSpec.new(self, action_name)
  end

  # This is a helper class that holds information about the action that is being defined via def_action.
  class ActionSpec
    def initialize (controller_class, action_name)
      puts "creating action spec #{controller_class}, #{action_name}"
      @controller_class = controller_class
      @action_name      = action_name
    end

    # This language construct is used inside of def_action to specify the sign-in conditions under which
    # the action can be executed. It should take a block that, when executed in the context of the action,
    # which means that params will be defined, returns true if the action is permitted.
    def for_authorization (&authorization_condition_block)
      puts "creating authorization #{@controller_class}, #{@action_name}"
      @controller_class.def_authorization(@action_name, authorization_condition_block)
    end

    # This language construct specifies the main body of the controller action being defined.
    def main (&action_block)
      puts "creating main #{@controller_class}, #{@action_name}"
      __action_name__ = @action_name # make this lexically visible to the method being defined below, because class_eval changes our binding environment.
      @controller_class.class_eval do
        define_method(__action_name__) do
          puts "Calling main method for #{__action_name__} with block #{action_block}"
          action_block.call
        end
      end
    end

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

  # Associate the specified authorization proc with the specified action.
  # When the controller is called upon to execute an action like :create_post,
  # it first calls the associated proc to see whether the current user has sufficient permission to take
  # the action. If the proc returns true, then the action can be taken.
  # IMPLEMENTATION: We store the proc on a hash table with associated key <action>, which is the name
  # of the controller action to be executed. Then, at run time, the before_filter check_authorization_for_action
  # calls up the proc and runs it to determine whether the action is allowed.
  @@authorization_conditions = {}
  def self.def_authorization (action, proc)
    @@authorization_conditions ||= {}
    @@authorization_conditions[action] = proc
  end

  # Short-circuit the running of the currently requested controller action if it is not authorized.
  # Note: action_name() is a method that is defined in the context of the controller.
  # It returns params[:action_name], which is the name of the action being requested.
  def check_authorization_for_action
    if !action_authorized?(action_name.to_sym)
      redirect_to :back, notice: 'You do not have permission to execute this action.'
    end
  end

  # Return true if the current user has permission to execute the requested controller action.
  # The parameter action is a symbol naming the action, e.g., :create_user
  def action_authorized? (action)
    if (authorization_condition = @@authorization_conditions[action])
      authorization_condition.call
    end
  end

  # ========== Authorization Condition methods
  # These methods define typical cases for permitting an action. Note that virtually all
  # authorization methods require there to be a current user (i.e. ,a signed-in user), and they
  # must explicitly check for this. They can't assume that there is a signed-in user.

  # The current user and admin can both take actions on @user.
  def authorize_action_on_self
    current_user?(@user) || current_user.admin? if current_user
  end

  # The owner of a micropost or an admin can both manipulate a post.
  def authorize_post_owner
    current_user.admin? || current_user?(@post.user) if current_user
  end

  # Allow admin to operate on @user so long as @user is not the admin himself.
  def authorize_admin_when_not_user
    current_user.admin? && !current_user?(@user) if current_user
  end

  # Allow anyone to operate on @user so long as @user is not the current user himself.
  def authorize_all_when_not_user
    !current_user?(@user) if current_user
  end

  # This operation has no authorization restrictions
  def authorize_all
    true
  end

end
