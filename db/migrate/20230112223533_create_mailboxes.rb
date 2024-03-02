class CreateMailboxes < ActiveRecord::Migration[5.2]
  def change
    create_table :mailboxes do |t|
      t.string :subject, nil: false
      t.text :message, nil: false
      t.datetime :sent_at, nil: false
      t.datetime :opened_at, nil: false
      t.string :token, index: true
      t.references :user
      t.timestamps
    end
  end
end
