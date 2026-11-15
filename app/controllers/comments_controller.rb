class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post
  before_action :set_comment, only: %i[edit update destroy]

  def create
    @comment = @post.comments.build(comment_params.merge(user: current_user))
    authorize @comment

    if @comment.save
      @comment.create_activity :create, owner: current_user
      redirect_to @post, notice: "Comment added."
    else
      redirect_to @post, alert: "Your comment could not be saved: #{@comment.errors.full_messages.to_sentence}."
    end
  end

  def edit
  end

  def update
    if @comment.update(comment_params)
      redirect_to @post, notice: "Comment updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @comment.destroy!
    redirect_to @post, notice: "Comment deleted.", status: :see_other
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def set_comment
    @comment = @post.comments.find(params[:id])
    authorize @comment
  end

  def comment_params
    params.expect(comment: [ :body ])
  end
end
