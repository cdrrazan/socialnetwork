class PersonalMessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :find_conversation!

  def new
    return redirect_to(@conversation) if @conversation

    @personal_message = current_user.personal_messages.build
  end

  def create
    @conversation ||= Conversation.create!(author: current_user, receiver: @receiver)
    @personal_message = current_user.personal_messages.build(personal_message_params.merge(conversation: @conversation))

    if @personal_message.save
      redirect_to @conversation, notice: "Your message was sent."
    else
      redirect_to @conversation, alert: "Message can't be blank."
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
