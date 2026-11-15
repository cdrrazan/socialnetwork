class ApplicationMailer < ActionMailer::Base
  # Override with MAILER_FROM, e.g. "DevStory <hello@devstory.example>".
  def self.default_sender
    ENV.fetch("MAILER_FROM") { "DevStory <no-reply@#{ENV.fetch("APP_HOST", "localhost")}>" }
  end

  default from: -> { ApplicationMailer.default_sender }
  layout "mailer"
end
