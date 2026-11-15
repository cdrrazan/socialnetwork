class StaticController < ApplicationController
  before_action :authenticate_user!, only: %i[profile settings]

  def index
  end

  def about
  end

  def contact
  end

  def profile
    @posts = current_user.posts.newest_first
    @questions = current_user.questions.newest_first
    @following = current_user.friends
    @followers = current_user.inverse_friends
  end

  def settings
  end
end
