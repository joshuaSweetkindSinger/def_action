module ApplicationHelper

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
                controller: 'pages',
                action:     'delete_post',
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
