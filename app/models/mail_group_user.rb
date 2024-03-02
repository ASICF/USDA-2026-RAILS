class MailGroupUser < ApplicationRecord

    # Associations
    belongs_to :mail_group
    belongs_to :user

end
