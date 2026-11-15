class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include PublicActivity::StoreController

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :username ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :username, :avatar ])
  end

  private

  def user_not_authorized
    redirect_back_or_to root_path, alert: "You are not authorized to perform this action."
  end
end
