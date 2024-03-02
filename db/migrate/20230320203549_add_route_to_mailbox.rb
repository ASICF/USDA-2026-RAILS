class AddRouteToMailbox < ActiveRecord::Migration[5.2]
  def change
    add_column :mailboxes, :route, :string
  end
end
