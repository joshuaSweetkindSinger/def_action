module ComponentsHelper
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
end


