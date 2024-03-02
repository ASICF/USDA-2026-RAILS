class MailGroup < ApplicationRecord

    # Associations
    has_many :mail_group_users
    has_many :users, -> { distinct }, through: :mail_group_users

    # Validation
    validates :name, :description, presence: true

end
