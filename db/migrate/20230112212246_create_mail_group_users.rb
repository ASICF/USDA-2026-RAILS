class CreateMailGroupUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :mail_group_users do |t|
      t.belongs_to :mail_group
      t.belongs_to :user
    end
  end
end
