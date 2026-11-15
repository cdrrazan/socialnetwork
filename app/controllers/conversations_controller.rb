class ConversationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @conversations = policy_scope(Conversation)
                       .includes(:author, :receiver, :personal_messages)
                       .order(updated_at: :desc)
  end

  def show
    @conversation = Conversation.find(params[:id])
    authorize @conversation
    @personal_message = PersonalMessage.new
  end
end
