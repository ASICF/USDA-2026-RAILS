class BatchProcess < ApplicationRecord
    include Concerns::Archive
    require 'fileutils'

    # Associations
    has_many :batch_process_logs, dependent: :destroy
    has_many :historic_assocs, as: :historicable, dependent: :destroy
    has_many :histories, through: :historic_assocs
    belongs_to :creator, class_name: 'User'

    # Scopes
    scope :active, -> { includes(:batch_process_logs).where(end_datetime: nil).where.not(batch_process_logs: {error: true}) }
    scope :has_errors, -> { includes(:batch_process_logs).where(batch_process_logs: {error: true}) }

    def has_errors?
        batch_process_logs.where(error: true).count > 0 ? true : false
    end

end
