class AddResendAttemptsToMailbox < ActiveRecord::Migration[5.2]
  def change
    add_column :mailboxes, :retry_count, :integer, default: 0, nil: false
  end
end
