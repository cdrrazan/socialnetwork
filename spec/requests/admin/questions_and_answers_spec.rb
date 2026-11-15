require "rails_helper"

RSpec.describe "Admin questions and answers" do
  let!(:question) { create(:question, title: "Admin visible?") }
  let!(:answer) { create(:answer, question: question, body: "An answer that is fairly long " * 5) }

  before { sign_in create(:admin_user) }

  it "lists questions with answer counts" do
    get admin_questions_path
    expect(page_html).to have_text("Admin visible?")
  end

  it "edits a question" do
    patch admin_question_path(question), params: { question: { title: "Edited by admin?" } }
    expect(question.reload.title).to eq("Edited by admin?")
  end

  it "filters questions" do
    create(:question, title: "Something else")
    get admin_questions_path(q: { title_cont: "Admin" })
    expect(page_html).to have_text("Admin visible?")
    expect(page_html).to have_no_text("Something else")
  end

  it "lists answers with a link to their question and a truncated body" do
    get admin_answers_path
    expect(page_html).to have_link("Admin visible?", href: admin_question_path(question))
    expect(page_html).to have_text("...")
  end

  it "deletes an answer" do
    expect { delete admin_answer_path(answer) }.to change(Answer, :count).by(-1)
  end
end
