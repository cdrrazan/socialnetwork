require "rails_helper"

RSpec.describe "Comments" do
  let(:post_record) { create(:post) }
  let(:author) { create(:user) }
  let(:member) { create(:user) }
  let(:moderator) { create(:user, :moderator) }
  let!(:comment) { create(:comment, post: post_record, user: author, body: "First!") }

  describe "POST /posts/:post_id/comments" do
    it "requires sign-in" do
      post post_comments_path(post_record), params: { comment: { body: "Hi" } }
      expect(response).to redirect_to(new_user_session_path)
    end

    context "when signed in" do
      before { sign_in member }

      it "adds a comment by the current member and records the activity" do
        expect { post post_comments_path(post_record), params: { comment: { body: "Nice post" } } }
          .to change(post_record.comments, :count).by(1)
          .and change(PublicActivity::Activity, :count).by(1)

        expect(post_record.comments.order(:id).last).to have_attributes(user: member, body: "Nice post")
        expect(post_record.reload.comments_count).to eq(2)
        expect(response).to redirect_to(post_path(post_record))
        expect(flash[:notice]).to eq("Comment added.")
      end

      it "rejects a blank comment with an explanation" do
        expect { post post_comments_path(post_record), params: { comment: { body: " " } } }
          .not_to change(Comment, :count)
        expect(flash[:alert]).to eq("Your comment could not be saved: Body can't be blank.")
      end

      it "can't be used to comment as someone else or on another post" do
        other_post = create(:post)
        post post_comments_path(post_record), params: { comment: { body: "Sneaky", user_id: author.id, post_id: other_post.id } }
        expect(Comment.order(:id).last).to have_attributes(user: member, post: post_record)
      end

      it "returns 404 for a missing post" do
        post post_comments_path(post_id: 0), params: { comment: { body: "Hi" } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "editing" do
    it "lets the author edit and update" do
      sign_in author
      get edit_post_comment_path(post_record, comment)
      expect(page_html).to have_field("Comment", with: "First!")

      patch post_comment_path(post_record, comment), params: { comment: { body: "Edited" } }
      expect(comment.reload.body).to eq("Edited")
      expect(response).to redirect_to(post_path(post_record))
    end

    it "re-renders the form when the update is invalid" do
      sign_in author
      patch post_comment_path(post_record, comment), params: { comment: { body: "" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(comment.reload.body).to eq("First!")
    end

    it "is denied to moderators and other members" do
      [ member, moderator ].each do |user|
        sign_in user
        patch post_comment_path(post_record, comment), params: { comment: { body: "Changed" } }
        expect(response).to redirect_to(root_path)
      end
      expect(comment.reload.body).to eq("First!")
    end

    it "only finds comments that belong to the post in the URL" do
      sign_in author
      get edit_post_comment_path(create(:post), comment)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /posts/:post_id/comments/:id" do
    it "lets the author delete" do
      sign_in author
      expect { delete post_comment_path(post_record, comment) }.to change(Comment, :count).by(-1)
      expect(response).to have_http_status(:see_other)
      expect(post_record.reload.comments_count).to eq(0)
    end

    it "lets moderators delete" do
      sign_in moderator
      expect { delete post_comment_path(post_record, comment) }.to change(Comment, :count).by(-1)
    end

    it "is denied to other members" do
      sign_in member
      expect { delete post_comment_path(post_record, comment) }.not_to change(Comment, :count)
    end
  end
end
