# Timeline of what the people you follow have been doing.
class ActivitiesController < ApplicationController
  before_action :authenticate_user!

  def index
    @activities = PublicActivity::Activity
                    .where(owner_type: "User", owner_id: current_user.friends.select(:id))
                    .includes(:owner, :trackable)
                    .order(created_at: :desc)
                    .limit(100)
  end
end
