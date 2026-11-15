# Base Pundit policy. Everything is denied unless a subclass allows it.
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index? = false
  def show? = false
  def create? = false
  def new? = create?
  def update? = false
  def edit? = update?
  def destroy? = false

  private

  def signed_in?
    user.present?
  end

  def admin?
    user&.admin? || false
  end

  def owner?
    signed_in? && record.respond_to?(:user_id) && record.user_id == user.id
  end

  def owner_or_admin?
    owner? || admin?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end

    private

    attr_reader :user, :scope
  end
end
