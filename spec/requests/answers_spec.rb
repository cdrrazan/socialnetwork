require "rails_helper"

RSpec.describe "Answers" do
  let(:question) { create(:question) }
  let(:author) { create(:user) }
  let(:member) { create(:user) }

  describe "POST /questions/:question_id/answers" do
    it "requires sign-in" do
      post question_answers_path(question), params: { answer: { body: "Try this" } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "adds an answer by the current member" do
      sign_in member
      expect { post question_answers_path(question), params: { answer: { body: "Use -n" } } }
        .to change(question.answers, :count).by(1)

      expect(question.answers.last).to have_attributes(user: member, body: "Use -n")
      expect(question.reload.answers_count).to eq(1)
      expect(response).to redirect_to(question_path(question))
      expect(flash[:notice]).to eq("Your answer was submitted.")
    end

    it "explains why a blank answer wasn't saved" do
      sign_in member
      expect { post question_answers_path(question), params: { answer: { body: "" } } }.not_to change(Answer, :count)
      expect(flash[:alert]).to eq("Your answer could not be saved: Body can't be blank.")
    end

    it "returns 404 for a missing question" do
      sign_in member
      post question_answers_path(question_id: 0), params: { answer: { body: "x" } }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /questions/:question_id/answers/:id" do
    let!(:answer) { create(:answer, question: question, user: author) }

    it "lets the author delete" do
      sign_in author
      expect { delete question_answer_path(question, answer) }.to change(Answer, :count).by(-1)
      expect(response).to have_http_status(:see_other)
      expect(flash[:notice]).to eq("Answer deleted.")
    end

    it "lets moderators delete" do
      sign_in create(:user, :moderator)
      expect { delete question_answer_path(question, answer) }.to change(Answer, :count).by(-1)
    end

    it "is denied to other members, including the question's author" do
      [ member, question.user ].each do |user|
        sign_in user
        expect { delete question_answer_path(question, answer) }.not_to change(Answer, :count)
      end
    end

    it "only finds answers that belong to the question in the URL" do
      sign_in author
      delete question_answer_path(create(:question), answer)
      expect(response).to have_http_status(:not_found)
    end
  end
end
