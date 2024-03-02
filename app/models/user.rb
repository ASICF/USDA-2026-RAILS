class User < ApplicationRecord
  extend Enumerize
  # devise :trackable, :rememberable, :omniauthable, omniauth_providers: [:google_oauth2]
  devise :database_authenticatable, :recoverable, :rememberable, :lockable, :validatable, :trackable

  # Associations
  has_many :historic_assocs, as: :historicable, dependent: :destroy
  has_many :histories, through: :historic_assocs
  has_many :mail_group_users
  has_many :mail_groups, through: :mail_group_users
  has_many :mailboxes

  # Validations
  validate :password_complexity

  # Scopes
  scope :admins, -> { where(role: "Admin") }
  scope :managers, -> { where(role: "Manager") }
  scope :producers, -> { where(role: "Production") }

  scope :approved, -> { where(approved: true) }
  scope :not_approved, -> { where(approved: false) }
  scope :destroyed, -> { where(marked_as_destroyed: true) }

  # Constants
  ROLES = ["Admin", "Manager", "Reviewer", "Production"]

  # Callbacks
  before_save :check_marked_as_destroyed

  def check_marked_as_destroyed
    self.approved = false if self.marked_as_destroyed
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def admin?
    role == "Admin"
  end

  def manager?
    role == "Manager"
  end

  def reviewer?
    role == "Reviewer"
  end

  def production?
    role == "Production"
  end

  def role?(role)
    self.roles.include? role
  end

  def self.create_new_user params
    # Create a new user without a password for verification
    u = User.new(params)
    if u.save(validate: false)
      u.send_reset_password_instructions
      return {
        state: true
      }
    else
      return {
        state: false,
        message: u.errors.full_messages.to_sentence
      }
    end
  
  end

  private

  def password_complexity
    # Regexp extracted from https://stackoverflow.com/questions/19605150/regex-for-password-must-contain-at-least-eight-characters-at-least-one-number-a
    return if password.blank? || password =~ /^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,30}$/

    errors.add :password, 'Complexity requirement not met. Length should be 8-30 characters and include: 1 uppercase, 1 lowercase, 1 numeric and 1 special character'
  end

end
