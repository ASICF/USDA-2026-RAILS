class ApplicationController < ActionController::Base

  protect_from_forgery with: :exception
  before_action :reset_session_if_destroyed
  helper_method :project_archived?
  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path
  end

  def project_archived?
    return Rails.application.secrets.project_archived
  end

  protected

  def reset_session_if_destroyed
    if current_user && current_user.marked_as_destroyed?
      flash.alert = 'Your account was disabled.'
      sign_out(current_user)
    end
  end
end