class PostPolicy < ApplicationPolicy
  def index? = signed_in?
  def show? = signed_in?
  def create? = signed_in?
  def update? = owner_or_admin?
  def destroy? = owner_or_admin?
  def vote? = signed_in?

  class Scope < Scope
    def resolve
      scope.published
    end
  end
end
