class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: %i[show edit update destroy upvote downvote]

  def index
    authorize Post
    @posts = policy_scope(Post).includes(:user, :tags).newest_first
    @posts = @posts.tagged_with(params[:tag]) if params[:tag].present?
  end

  def show
    @comments = @post.comments.includes(:user).chronological
    @comment = Comment.new
    @similar_posts = @post.similar_posts
  end

  def new
    @post = authorize Post.new
  end

  def create
    @post = authorize current_user.posts.build(post_params)

    if verify_captcha(@post) && @post.save
      @post.create_activity :create, owner: current_user
      redirect_to @post, notice: "Your post was published."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "Post updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @post.destroy!
    redirect_to posts_path, notice: "Post deleted.", status: :see_other
  end

  def upvote
    @post.upvote_from current_user
    redirect_back_or_to @post
  end

  def downvote
    @post.downvote_from current_user
    redirect_back_or_to @post
  end

  private

  def set_post
    @post = Post.find(params[:id])
    authorize @post, action_policy
  end

  def action_policy
    %w[upvote downvote].include?(action_name) ? :vote? : :"#{action_name}?"
  end

  def post_params
    params.expect(post: [ :title, :body, :tag_list ])
  end

  # reCAPTCHA is only enforced when keys are configured (see .env.example).
  def verify_captcha(post)
    return true if Recaptcha.configuration.site_key.blank?

    verify_recaptcha(model: post)
  end
end
