class AddWebServiceDates < ActiveRecord::Migration[5.2]
  def change
    add_column :footprints, :provisional_upload_date, :date, index: true
    add_reference :footprints, :vector_metadatum, index: true
    add_column :rejected_footprints, :provisional_upload_date, :date, index: true
    add_reference :rejected_footprints, :vector_metadatum, index: true

    # add_column :tiles, :production_upload_date, :date, index: true
    # add_reference :tiles, :vector_metadatum, index: true
    # add_column :rejected_tiles, :production_upload_date, :date, index: true
    # add_reference :rejected_tiles, :vector_metadatum, index: true

    # add_column :doqqs, :production_upload_date, :date, index: true
    # add_reference :doqqs, :vector_metadatum, index: true
  end
end
