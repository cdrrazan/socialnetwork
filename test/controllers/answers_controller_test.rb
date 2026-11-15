require "test_helper"

class AnswersControllerTest < ActionDispatch::IntegrationTest
  setup { @question = questions(:minitest) }

  test "create requires sign-in" do
    post question_answers_path(@question), params: { answer: { body: "Hi" } }
    assert_redirected_to new_user_session_path
  end

  test "create" do
    sign_in users(:carol)
    assert_difference("@question.answers.count") do
      post question_answers_path(@question), params: { answer: { body: "Use -n" } }
    end
    assert_redirected_to question_path(@question)
  end

  test "only the author can delete" do
    answer = answers(:bobs_answer)

    sign_in users(:alice)
    assert_no_difference("Answer.count") { delete question_answer_path(@question, answer) }

    sign_in users(:bob)
    assert_difference("Answer.count", -1) { delete question_answer_path(@question, answer) }
  end
end
