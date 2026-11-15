# Following and unfollowing other users.
class FriendshipsController < ApplicationController
  before_action :authenticate_user!

  def create
    friend = User.find(params[:friend_id])
    friendship = current_user.friendships.build(friend: friend)

    if friendship.save
      redirect_back_or_to my_friends_path, notice: "You are now following #{friend.display_name}."
    else
      redirect_back_or_to my_friends_path, alert: friendship.errors.full_messages.to_sentence
    end
  end

  # +params[:id]+ is the id of the followed user.
  def destroy
    friendship = current_user.friendships.find_by!(friend_id: params[:id])
    friendship.destroy!
    redirect_back_or_to my_friends_path, notice: "You unfollowed #{friendship.friend.display_name}.", status: :see_other
  end
end
