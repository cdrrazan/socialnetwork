class ConversationPolicy < ApplicationPolicy
  def index? = signed_in?
  def show? = signed_in? && record.participates?(user)

  class Scope < Scope
    def resolve
      scope.participating(user)
    end
  end
end
