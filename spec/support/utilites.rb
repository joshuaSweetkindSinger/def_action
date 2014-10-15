# This file contains helper methods for our rspec tests, which are defined in ../requests.
# RSpec automatically includes all the files in the "support" directory that this file lives in.

def full_title(page_title)
  base_title = "Sample App"
  if page_title.empty?
    base_title
  else
    "#{ base_title} | #{ page_title}"
  end
end

