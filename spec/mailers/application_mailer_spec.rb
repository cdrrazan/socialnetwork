require "rails_helper"

RSpec.describe ApplicationMailer do
  describe ".default_sender" do
    it "uses MAILER_FROM when set" do
      stub_const("ENV", ENV.to_h.merge("MAILER_FROM" => "Team <team@example.org>"))
      expect(described_class.default_sender).to eq("Team <team@example.org>")
    end

    it "builds a no-reply address from APP_HOST" do
      stub_const("ENV", ENV.to_h.except("MAILER_FROM").merge("APP_HOST" => "devstory.example"))
      expect(described_class.default_sender).to eq("DevStory <no-reply@devstory.example>")
    end

    it "falls back to localhost" do
      stub_const("ENV", ENV.to_h.except("MAILER_FROM", "APP_HOST"))
      expect(described_class.default_sender).to eq("DevStory <no-reply@localhost>")
    end
  end

  it "is the parent of Devise's mailer" do
    expect(Devise::Mailer.superclass).to eq(described_class)
  end

  it "wraps mail in the shared layout" do
    mail = Devise::Mailer.reset_password_instructions(create(:user), "token")
    expect(mail.body.encoded).to include("<html>")
    expect(mail[:from].to_s).to eq(described_class.default_sender)
  end
end
