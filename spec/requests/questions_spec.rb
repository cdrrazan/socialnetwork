require "rails_helper"

RSpec.describe "Questions" do
  let(:author) { create(:user, username: "asker") }
  let(:member) { create(:user) }
  let(:moderator) { create(:user, :moderator) }
  let!(:question) { create(:question, user: author, title: "How do I run one test?", body: "Details here") }

  describe "GET /questions" do
    it "is public and lists questions newest first with answer counts" do
      create(:question, title: "Older question", created_at: 1.week.ago)
      create(:answer, question: question)

      get questions_path

      expect(response).to have_http_status(:ok)
      titles = page_html.all(".list-group-item strong").map(&:text)
      expect(titles).to eq([ "How do I run one test?", "Older question" ])
      expect(page_html.find("#question_#{question.id}")).to have_text("asked by asker · 1 answer")
    end

    it "shows an empty state" do
      Question.destroy_all
      get questions_path
      expect(page_html).to have_text("No questions yet.")
    end

    it "serves JSON" do
      get questions_path(format: :json)
      expect(response.media_type).to eq("application/json")
      expect(response.parsed_body).to contain_exactly(
        a_hash_including("id" => question.id, "title" => "How do I run one test?", "author" => "asker",
                         "url" => question_url(question, format: :json))
      )
    end
  end

  describe "GET /questions/:id" do
    it "shows the question and its answers in order" do
      create(:answer, question: question, body: "Second answer", created_at: 1.minute.ago)
      create(:answer, question: question, body: "First answer", created_at: 1.hour.ago)

      get question_path(question)

      expect(page_html).to have_css("h1", text: "How do I run one test?")
      expect(page_html).to have_css("h2", text: "2 answers")
      expect(page_html.all(".card-body p").map(&:text)).to eq([ "First answer", "Second answer" ])
    end

    it "invites visitors to log in instead of showing the answer form" do
      get question_path(question)
      expect(page_html).to have_link("Log in")
      expect(page_html).to have_no_button("Post answer")
    end

    it "shows the answer form to members" do
      sign_in member
      get question_path(question)
      expect(page_html).to have_button("Post answer")
    end

    it "serves JSON" do
      get question_path(question, format: :json)
      expect(response.parsed_body).to include("title" => "How do I run one test?", "body" => "Details here")
    end

    it "returns 404 for a missing question" do
      get question_path(id: 0)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "asking a question" do
    it "requires sign-in" do
      get new_question_path
      expect(response).to redirect_to(new_user_session_path)
    end

    context "when signed in" do
      before { sign_in member }

      it "shows the form" do
        get new_question_path
        expect(page_html).to have_button("Ask question")
      end

      it "creates the question" do
        expect { post questions_path, params: { question: { title: "Why?", body: "Because." } } }
          .to change(member.questions, :count).by(1)
        expect(response).to redirect_to(question_path(Question.order(:id).last))
        expect(flash[:notice]).to eq("Question was successfully created.")
      end

      it "re-renders the form when invalid" do
        post questions_path, params: { question: { title: "", body: "" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(page_html).to have_text("can't be blank")
      end

      it "creates via JSON" do
        post questions_path(format: :json), params: { question: { title: "API?", body: "Yes." } }
        expect(response).to have_http_status(:created)
        expect(response.parsed_body).to include("title" => "API?")
        expect(response.location).to eq(question_url(Question.order(:id).last))
      end

      it "returns errors via JSON" do
        post questions_path(format: :json), params: { question: { title: "" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to include("title" => [ "can't be blank" ], "body" => [ "can't be blank" ])
      end
    end
  end

  describe "editing" do
    it "lets the author update" do
      sign_in author
      get edit_question_path(question)
      expect(page_html).to have_button("Update question")

      patch question_path(question), params: { question: { title: "Updated?" } }
      expect(question.reload.title).to eq("Updated?")
      expect(response).to redirect_to(question_path(question))
    end

    it "lets moderators update" do
      sign_in moderator
      patch question_path(question), params: { question: { title: "Tidied up?" } }
      expect(question.reload.title).to eq("Tidied up?")
    end

    it "re-renders the form when invalid" do
      sign_in author
      patch question_path(question), params: { question: { title: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "updates via JSON" do
      sign_in author
      patch question_path(question, format: :json), params: { question: { title: "JSON?" } }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["title"]).to eq("JSON?")
    end

    it "returns errors via JSON" do
      sign_in author
      patch question_path(question, format: :json), params: { question: { body: "" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("body" => [ "can't be blank" ])
    end

    it "is denied to other members" do
      sign_in member
      get edit_question_path(question)
      expect(response).to redirect_to(root_path)
      patch question_path(question), params: { question: { title: "Hijacked" } }
      expect(question.reload.title).to eq("How do I run one test?")
    end
  end

  describe "DELETE /questions/:id" do
    it "lets the author delete it along with its answers" do
      create(:answer, question: question)
      sign_in author

      expect { delete question_path(question) }.to change(Question, :count).by(-1).and change(Answer, :count).by(-1)
      expect(response).to redirect_to(questions_path)
      expect(response).to have_http_status(:see_other)
    end

    it "deletes via JSON" do
      sign_in author
      delete question_path(question, format: :json)
      expect(response).to have_http_status(:no_content)
    end

    it "is denied to other members" do
      sign_in member
      expect { delete question_path(question) }.not_to change(Question, :count)
    end
  end
end
