class Ability
  include CanCan::Ability

  def initialize(user)
    @user = user || User.new # for guest
    if @user.approved?
      approved
      if @user.admin?
        admin
      elsif @user.manager?
        manager
      elsif @user.production? || @user.reviewer?
        production
      end
    else
      guest
    end
  end

  def guest
  end

  def approved
    can :read, :all
  end

  def admin
    can :manage, :all
  end

  def manager
    can :manage, :all
    cannot :approve, User do |user|
      user.approved?
    end
  end

  def production
  end

end