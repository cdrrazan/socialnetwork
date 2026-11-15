require "rails_helper"

RSpec.describe "Friendships" do
  let(:alice) { create(:user) }
  let(:bob) { create(:user, username: "bob") }

  it "requires sign-in" do
    post friendships_path(friend_id: bob.id)
    expect(response).to redirect_to(new_user_session_path)
  end

  context "when signed in" do
    before { sign_in alice }

    it "follows someone" do
      expect { post friendships_path(friend_id: bob.id) }.to change(alice.friends, :count).by(1)
      expect(alice.following?(bob)).to be(true)
      expect(flash[:notice]).to eq("You are now following bob.")
      expect(response).to redirect_to(my_friends_path)
    end

    it "returns to the previous page" do
      post friendships_path(friend_id: bob.id), headers: { "HTTP_REFERER" => users_url }
      expect(response).to redirect_to(users_url)
    end

    it "explains why following twice fails" do
      create(:friendship, user: alice, friend: bob)
      expect { post friendships_path(friend_id: bob.id) }.not_to change(Friendship, :count)
      expect(flash[:alert]).to eq("Friend has already been taken")
    end

    it "won't follow yourself" do
      expect { post friendships_path(friend_id: alice.id) }.not_to change(Friendship, :count)
      expect(flash[:alert]).to eq("Friend can't be yourself")
    end

    it "returns 404 for a missing member" do
      post friendships_path(friend_id: 0)
      expect(response).to have_http_status(:not_found)
    end

    it "unfollows" do
      create(:friendship, user: alice, friend: bob)
      expect { delete friendship_path(bob) }.to change(Friendship, :count).by(-1)
      expect(response).to have_http_status(:see_other)
      expect(flash[:notice]).to eq("You unfollowed bob.")
    end

    it "can only remove your own follows" do
      create(:friendship, user: bob, friend: alice)
      delete friendship_path(alice)
      expect(response).to have_http_status(:not_found)
      expect(bob.following?(alice)).to be(true)
    end
  end
end
