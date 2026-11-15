class AnswerPolicy < ApplicationPolicy
  def create? = signed_in?
  def destroy? = owner_or_admin?
end
