class PageController < ApplicationController
  include PageHelper

  before_filter :maybe_require_sign_in

  def initialize
    super
    @sign_in_required = true # By default, all pages require sign in.
  end
end
