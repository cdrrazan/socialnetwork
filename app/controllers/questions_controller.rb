class QuestionsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_question, only: %i[show edit update destroy]

  def index
    @questions = Question.includes(:user).newest_first
  end

  def show
    @answers = @question.answers.includes(:user).chronological
    @answer = Answer.new
  end

  def new
    @question = authorize current_user.questions.build
  end

  def create
    @question = authorize current_user.questions.build(question_params)

    respond_to do |format|
      if @question.save
        format.html { redirect_to @question, notice: "Question was successfully created." }
        format.json { render :show, status: :created, location: @question }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @question.errors, status: :unprocessable_content }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @question.update(question_params)
        format.html { redirect_to @question, notice: "Question was successfully updated." }
        format.json { render :show, status: :ok, location: @question }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @question.errors, status: :unprocessable_content }
      end
    end
  end

  def destroy
    @question.destroy!

    respond_to do |format|
      format.html { redirect_to questions_path, notice: "Question was successfully deleted.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_question
    @question = Question.find(params[:id])
    authorize @question
  end

  def question_params
    params.expect(question: [ :title, :body ])
  end
end
