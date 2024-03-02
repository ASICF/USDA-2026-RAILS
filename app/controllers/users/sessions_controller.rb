class Users::SessionsController < ApplicationController
  def destroy
    flash.notice = t('devise.sessions.signed_out') if sign_out(:user) && is_navigational_format?

    respond_to do |format|
      format.all { head :no_content }
      format.html { redirect_to root_path }
    end
  end
end