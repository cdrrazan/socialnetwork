class QuestionPolicy < ApplicationPolicy
  def index? = true
  def show? = true
  def create? = signed_in?
  def update? = owner_or_admin?
  def destroy? = owner_or_admin?
end
