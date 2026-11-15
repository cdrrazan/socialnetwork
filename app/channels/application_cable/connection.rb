module ApplicationCable
  # Authenticates WebSocket connections (used by Turbo Streams) with the same
  # Devise session as normal requests. Anonymous visitors are rejected.
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      env["warden"]&.user(:user) || reject_unauthorized_connection
    end
  end
end
