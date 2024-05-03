class ApplicationPolicy
  DEFAULT_ACTIONS = %i[new create edit update destroy show index].freeze
  RAILS_SUPER_ADMIN_ACTIONS =
    %i[dashboard index show new edit destroy export show_in_app synchronize_maps clone edit_page].freeze
  RAILS_ADMIN_ACTIONS = %i[history].freeze

  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    true
  end

  def list?
    index?
  end

  def show?
    scope.where(id: record.id).exists?
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    user_is_superadmin?
  end

  def edit?
    update?
  end

  def destroy?
    user_is_superadmin?
  end

  def create_promotions_widget?
    user_is_superadmin? && record.respond_to?(:widgets) && record.respond_to?(:promotions)
  end

  def create_events_widget?
    user_is_superadmin? && record.respond_to?(:widgets) && record.respond_to?(:events)
  end

  def toggle_follow?
    record.respond_to?(:followings) && user.present?
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  def rails_admin?(action)
    if RAILS_SUPER_ADMIN_ACTIONS.include?(action)
      user&.is_superadmin?
    elsif RAILS_ADMIN_ACTIONS.include?(action)
      user&.admin?
    else
      raise ::Pundit::NotDefinedError, "unable to find policy #{action} for #{record}."
    end
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end

  private

  def available?; end

  def user_is_superadmin?
    user&.superadmin?
  end

  def user_is_owner?(resource = record)
    return false if user.blank?

    case resource.owner
    when Teams::Team
      resource.owner.users.exists?(user)
    when User
      resource.owner == user
    else
      false
    end
  end
end
