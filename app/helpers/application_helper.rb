module ApplicationHelper

  # ================= Auxiliaries


  # ================================

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
    if current_user && ((current_user == post.user) || current_user.admin?)
      link_to('Delete',
              {
                controller:   'pages',
                action:       'delete_post',
                micropost_id: post
              },
              method: :delete,
              confirm: 'Really delete this post?',
              title: post.content
      )
    end
  end

  SECURE_USER_TOKEN_SYMBOL = :secure_user_token

  def secure_user_token
    cookies[:SECURE_USER_TOKEN_SYMBOL]
  end

  def sign_in (user)
    cookies.permanent[:SECURE_USER_TOKEN_SYMBOL] = user.remember_token
    self.current_user = user
  end

  def sign_out
    self.current_user = nil
    cookies.delete(:SECURE_USER_TOKEN_SYMBOL)
  end

  def current_user= (u)
    @current_user = u
  end

  def current_user
    @current_user ||= secure_user_token && User.find_by_remember_token(secure_user_token)
  end



  # Take the user to the saved ":return_to" page, or to the specified default
  # page if there is no :return_to page saved for the session.
  def redirect_to_requested_url (default)
    redirect_to(session[:requested_url] || default)
    session.delete(:requested_url)
  end

  # Save the requested path to the :return_to key on the session, for access later.
  def cache_requested_url
    session[:requested_url] = request.fullpath
  end


  def gravatar_for (user, options = {size: 50})
    gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
    gravatar_url = "http://www.gravatar.com/avatar/#{gravatar_id}?s=#{options[:size]}"
    image_tag(gravatar_url, alt: user.name, class: "gravatar")
  end

end
