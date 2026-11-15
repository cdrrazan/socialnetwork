class PersonalMessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :find_conversation!

  def new
    return redirect_to(@conversation) if @conversation

    @personal_message = current_user.personal_messages.build
  end

  def create
    @personal_message = current_user.personal_messages.build(personal_message_params)
    # A brand-new conversation is saved together with its first message, so a
    # blank first message doesn't leave an empty conversation behind.
    @personal_message.conversation = @conversation || Conversation.new(author: current_user, receiver: @receiver)

    if @personal_message.save
      redirect_to @personal_message.conversation, notice: "Your message was sent."
    elsif @conversation
      redirect_to @conversation, alert: "Message can't be blank."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def personal_message_params
    params.expect(personal_message: [ :body ])
  end

  def find_conversation!
    if params[:receiver_id]
      @receiver = User.find(params[:receiver_id])
      return redirect_to(users_path, alert: "You can't message yourself.") if @receiver == current_user

      @conversation = Conversation.between(current_user.id, @receiver.id).first
    else
      @conversation = Conversation.find(params[:conversation_id])
      authorize @conversation, :show?
    end
  end
end
