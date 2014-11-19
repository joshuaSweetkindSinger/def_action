class ApplicationController < ActionController::Base
  protect_from_forgery
  include ApplicationHelper

  before_filter :get_object_references
  before_filter :check_permission_for_action


  # Get ids from the params object, like :user_id, and turn them into
  # actual objects, lik @user
  def get_object_references
    @user = (User.find(params[:user_id]) if params[:user_id]) ||
            (User.find(params[:user][:id]) if params[:user] && params[:user][:id]) ||
            current_user
    @post = Micropost.find(params[:micropost_id]) if params[:micropost_id]
  end

    # ============ Action Definition Logic
  # This section defines constructs for specifying a controller action based on the following framework:
  # an action has these parts:
  #  - a permission check, which, if it does not pass, results in the action not being executed.
  #  - a main body, which executes the api-level logic of the controller action.
  #  - a ui body, which updates the user interface after the main action has taken place.
  #
  # This section also defines def_action, a modified form of def that allows one to define the above parts
  # all in the same place. Below is an example.
  #
  # def_action :home do |action|
  #   action.permitted? {authorize_action_on_self} # specify that all (signed-in) users can request this action.
  #   action.main do  # specify the main body of the action before handing off to view.
  #     @micropost = current_user.microposts.build # empty micropost for form template
  #     @posts     = current_user.feed.paginate(page: params[:page])
  #   end
  #
  #   # This is an optional section that specifies ui actions.
  #   action.ui do
  #     render 'home_page'
  #   end
  #
  #   action.route(path: '/user_profile/:id') # this is an optional route specification. If not supplied, a default is generated.
  # end


  # This is the toplevel method for defining an action that knows how to specify its own
  # permission checks, main body, and ui components.
  def self.def_action (action)
    spec = ActionSpec.new(self, action) # This crucially holds information about controller class and action name.
    yield spec  # This defines the various action methods: permissions check, main action, ui action.

    # This combines the ui and main methods defined in the yield above into a single method with the proper name.
    # It does not wrap up the permission check, which is handled separately by a before_filter. This implementation is important, because
    # there is no guarantee that a developer will use def_action to create his/her actions. Using a before_filter
    # guarantees that all controller actions are subject to permissions checks.
    main = main_action_name(action)
    ui   = ui_action_name(action)
    define_method(action) do
      send main if respond_to?(main)
      send ui if respond_to?(ui)
    end

    @routes[action] ||= RouteSpec.new(action)
  end

  # This is a helper class that holds information about the action that is being defined via def_action.
  class ActionSpec
    def initialize (controller_class, action_name)
      @controller_class = controller_class
      @action_name      = action_name
    end

    # Define the permission-checking method of the action.
    def permitted? (&block)
      @controller_class.def_permission(@action_name, &block)
    end

    # Define the main-body method of the action.
    def main (&block)
      @controller_class.def_main_action(@action_name, &block)
    end

    # Define the ui-body method of the action.
    def ui (&block)
      @controller_class.def_ui_action(@action_name, &block)
    end

    def route (keyword_args = {})
      @controller_class.routes[@action_name] = RouteSpec.new(@action_name, keyword_args)
    end
  end


  def self.main_action_name (action)
    "#{action}_main"
  end


  def self.def_main_action (action, &block)
    define_method(main_action_name(action)) do
      instance_eval(&block)
    end
  end

  def self.ui_action_name (action)
    "#{action}_ui"
  end


  def self.def_ui_action (action, &block)
    define_method(ui_action_name(action)) do
      instance_eval(&block)
    end
  end


  # ========= Routes

  def self.routes
    @routes
  end

  # A helper class for specifying route information.
  # Example: route = RouteSpec.new(:user_profile, path: '/user_profile/:id')
  #
  # Aliases
  # The :verb component can also be specified using the :via keyword.
  # The :name component can also be specified using the :as keyword
  #
  # Defaults
  # The :verb, :name , :to, and :path keyword args are defaulted if no name or path is supplied.
  # :verb value defaults to :get
  # :name value defaults to action
  # :to value defaults to 'pages/<action>'
  # :path value defaults to /<name>
  #
  # If nothing is specified except the action, say :foo, then the default route generated is
  # match '/foo', via: :get, to: 'pages#foo', as: :foo
  class RouteSpec
    attr_reader :action, :controller, :verb, :to, :name, :path

    def initialize(action, keyword_args = {})
      @action = action
      @controller = 'pages'
      @verb = keyword_args[:via]  || keyword_args[:verb] || :get
      @to   = keyword_args[:to]   || "#{@controller}##{action}"
      @name = keyword_args[:name] || keyword_args[:as] ||  action
      @path = keyword_args[:path] || "/#{@name}"
    end

    def via
      @verb
    end

    def as
      @name
    end

    def to_s
      "match '#{path}', via: :#{verb}, to: '#{to}', as: :#{name}"
    end

    def to_proc
      proc {match path, via: verb, to: to, as: name}
    end
  end

  # ============== Permission Logic
  # Many actions require the current user to have special permissions before
  # they can be executed. This section defines helpers
  # to aid in determining whether the current user has correct permissions to execute the requested action.
  # Use def_permission to define the permission conditions pertaining to an action.
  # If no permission conditions are specified, the action will not be allowed by default.

  # Associate the specified permission block with the specified action.
  # When the controller is called upon to execute an action like :create_post,
  # it first calls the associated permission block in the context of the controller object
  # to see whether the current user has sufficient permission to take
  # the action. If the block returns true, then the action can be taken.
  #
  # IMPLEMENTATION: We define a method whose name is a function of action and whose body is the one supplied.
  def self.def_permission (action, &block)
    define_method(permission_check_name(action)) do
      instance_eval(&block)
    end
  end

  def self.permission_check_name (action)
    "check_permission_for_#{action}_action"
  end


  # Short-circuit the running of the currently requested controller action if it is not authorized.
  # Note: action_name() is a method that is defined in the context of the controller.
  # It returns params[:action_name], which is the name of the action being requested.
  def check_permission_for_action
    is_permitted = action_permitted?(action_name)

    case
      # Action is not permitted without sign in
      when !current_user && !is_permitted
        cache_requested_url
        redirect_to sign_in_path, notice: 'Please sign in.'

      # Action is not permitted
      when current_user && !is_permitted
        redirect_back default_path: root_path, notice: 'You do not have permission to execute this action.'

      # Action is permitted (no need to do anything)
    end
  end


  # Return true if the current user has permission to execute the requested controller action.
  # The parameter action is a symbol naming the action, e.g., :create_user
  def action_permitted? (action)
    permission_check = self.class.permission_check_name(action)
    respond_to?(permission_check) && send(permission_check)
  end


  # ========== Authorization Condition methods
  # These methods define typical cases for permitting an action. Note that virtually all
  # authorization methods require there to be a current user (i.e. ,a signed-in user), and they
  # must explicitly check for this. They can't assume that there is a signed-in user.

  # The current user and admin can both take actions on @user.
  def permit_action_on_self
    (current_user == @user) || current_user.admin? if current_user
  end

  # The owner of a micropost or an admin can both manipulate a post.
  def permit_post_owner
    current_user.admin? || (current_user == @post.user) if current_user
  end

  # Allow admin to operate on @user so long as @user is not the admin himself.
  def permit_admin_when_not_user
    current_user.admin? && (current_user != @user) if current_user
  end

  # Allow anyone to operate on @user so long as @user is not the current user himself.
  def permit_all_when_not_user
    (current_user != @user) if current_user
  end

# ============================ MISC

  # Redirect the user back to the previous page (http-referer).
  # This method takes various optional keyword arguments that can alter its behavior.
  # :default_path -- if there is no :back to go to (no http-referer), then redirect to this path instead.
  # :default_page -- if there is no :back, and no :default_path was specified, then, instead of redirecting, render the specified page.
  # :notice, :error -- these are passed to redirect_to as keyword args (in the event that we actually redirect)
  def redirect_back (keyword_args = {})
    redirect_key_args = {}
    [:notice, :error].each do |key|
      redirect_key_args[key] = keyword_args[key]
    end

    redirect_path = request.referrer.present? ? :back : keyword_args[:default_path] # Calculate the redirect path

    # We found a redirect-path--Go there
    if redirect_path
      redirect_to redirect_path, redirect_key_args

    # Couldn't find a redirect path--go to default page instead
    elsif keyword_args[:default_page]
      render keyword_args[:default_page]

    # No default page was specified--give up.
    else
      render plain: 'The app encountered a problem.'
    end
  end
end

