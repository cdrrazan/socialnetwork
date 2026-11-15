class CommentPolicy < ApplicationPolicy
  def create? = signed_in?
  def update? = owner?
  def destroy? = owner_or_admin?
end
