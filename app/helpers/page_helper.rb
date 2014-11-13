# This file contains helper methods used by all
# page controllers.

module PageHelper
  # Return true if this page requires sign-in.
  def sign_in_required?
    @sign_in_required
  end

  # Check to see whether the page being loaded requires sign in first, and,
  # if so, redirect a not-yet-signed in user to the sign in page.
  def maybe_require_sign_in
    if !signed_in? && sign_in_required?
      cache_requested_url
      redirect_to signin_path, notice: 'Please sign in.'
    end
  end
end