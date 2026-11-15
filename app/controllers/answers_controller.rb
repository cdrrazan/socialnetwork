class AnswersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_question

  def create
    @answer = @question.answers.build(answer_params.merge(user: current_user))
    authorize @answer

    if @answer.save
      redirect_to @question, notice: "Your answer was submitted."
    else
      redirect_to @question, alert: "Your answer could not be saved: #{@answer.errors.full_messages.to_sentence}."
    end
  end

  def destroy
    @answer = @question.answers.find(params[:id])
    authorize @answer
    @answer.destroy!
    redirect_to @question, notice: "Answer deleted.", status: :see_other
  end

  private

  def set_question
    @question = Question.find(params[:question_id])
  end

  def answer_params
    params.expect(answer: [ :body ])
  end
end
