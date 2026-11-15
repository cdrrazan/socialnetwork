# ActiveAdmin configuration. See the full list of options at
# https://activeadmin.info/1-general-configuration.html
ActiveAdmin.setup do |config|
  config.site_title = "DevStory"
  config.footer = "DevStory admin"

  # Admins are a separate Devise model (AdminUser), mounted at /admin.
  config.authentication_method = :authenticate_admin_user!
  config.current_user_method = :current_admin_user
  config.logout_link_path = :destroy_admin_user_session_path
  config.logout_link_method = :delete

  # Internal admin comments on resources are not used.
  config.comments = false

  config.batch_actions = true
  config.localize_format = :long
  config.filter_attributes = [ :encrypted_password, :password, :password_confirmation ]
end
