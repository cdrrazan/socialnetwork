class PostPolicy < ApplicationPolicy
  def index? = signed_in?
  def show? = signed_in? && (record.state != "unpublished" || owner_or_admin?)
  def create? = signed_in?
  def update? = owner_or_admin?
  def destroy? = owner_or_admin?
  def vote? = show?

  class Scope < Scope
    def resolve
      scope.published
    end
  end
end
