# This module provides utility functions for managing a session:
# sign-in, sign-out, setting and querying about the current_user.

module SessionsHelper
  def sign_in (user)
    cookies.permanent[:remember_token] = user.remember_token
    self.current_user = user
  end

  def require_sign_in
    unless signed_in?
      cache_requested_url
      redirect_to signin_path, notice: 'Please sign in.'
    end
  end

  def sign_out
    self.current_user = nil
    cookies.delete(:remember_token)
  end

  def current_user= (u)
    @current_user = u
  end

  def current_user
    @current_user ||= User.find_by_remember_token(cookies[:remember_token])
  end


  # Returns true when the specified user is the current user; otherwise, false.
  def current_user? (u)
    u == current_user
  end

  def signed_in?
    !current_user.nil?
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
end
