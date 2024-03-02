class CreateDoqqFootprints < ActiveRecord::Migration[5.2]
  def change
    create_table :doqq_footprints do |t|
      t.belongs_to :doqq
      t.belongs_to :footprint
      t.timestamps
    end
  end
end
