require "test_helper"

class QuestionsControllerTest < ActionDispatch::IntegrationTest
  setup { @question = questions(:minitest) }

  test "index and show are public" do
    get questions_path
    assert_response :success
    assert_select "strong", @question.title

    get question_path(@question)
    assert_response :success
    assert_select "h2", "1 answer"
  end

  test "json" do
    get question_path(@question, format: :json)
    assert_equal @question.title, response.parsed_body["title"]
  end

  test "new requires sign-in" do
    get new_question_path
    assert_redirected_to new_user_session_path
  end

  test "create" do
    sign_in users(:bob)
    assert_difference("Question.count") do
      post questions_path, params: { question: { title: "Why?", body: "Because." } }
    end
    assert_redirected_to question_path(Question.order(:id).last)
  end

  test "create with invalid params" do
    sign_in users(:bob)
    post questions_path, params: { question: { title: "", body: "" } }
    assert_response :unprocessable_content
  end

  test "owner can update" do
    sign_in users(:alice)
    patch question_path(@question), params: { question: { title: "Updated" } }
    assert_redirected_to question_path(@question.reload)
    assert_equal "Updated", @question.title
  end

  test "non-owner cannot edit or destroy" do
    sign_in users(:bob)
    get edit_question_path(@question)
    assert_redirected_to root_path

    assert_no_difference("Question.count") { delete question_path(@question) }
  end

  test "owner can destroy" do
    sign_in users(:alice)
    assert_difference("Question.count", -1) { delete question_path(@question) }
    assert_redirected_to questions_path
  end
end
