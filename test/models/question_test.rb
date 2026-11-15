require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  test "requires title and body" do
    question = Question.new(user: users(:alice))
    assert_not question.valid?
    assert question.errors[:title].any?
    assert question.errors[:body].any?
  end

  test "destroying a question removes its answers" do
    assert_difference "Answer.count", -1 do
      questions(:minitest).destroy
    end
  end

  test "answers belong to questions" do
    answer = answers(:bobs_answer)
    assert_equal questions(:minitest), answer.question
    assert_not Answer.new(user: users(:bob), body: "orphan").valid?
  end
end
