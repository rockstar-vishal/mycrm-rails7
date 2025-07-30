class InternalController < ActionController::API
  before_action :check_internal

  def check_internal
    return true
  end
end