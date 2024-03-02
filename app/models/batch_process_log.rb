class BatchProcessLog < ApplicationRecord
    include Concerns::Archive

    # Associations
    belongs_to :batch_process
    belongs_to :tile, optional: true

end
