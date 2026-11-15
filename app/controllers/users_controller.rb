class UsersController < ApplicationController
  before_action :authenticate_user!

  def index
    @users = User.where.not(id: current_user.id).search(params[:search]).alphabetical
    @following_ids = current_user.friendships.pluck(:friend_id).to_set
  end

  def show
    @user = User.find(params[:id])
    @posts = @user.posts.published.newest_first
    @followers = @user.inverse_friends
    @following = @user.friends
  end

  def my_friends
    @following = current_user.friends.with_attached_avatar
    @followers = current_user.inverse_friends.with_attached_avatar
  end
end
