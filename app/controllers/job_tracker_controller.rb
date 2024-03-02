class JobTrackerController < ApplicationController

    def index
        response = []

        Job.includes(:creator).last(20).reverse.each do |job|
            response << {
                active: job.active,
                success:  job.success,
                created_at: job.created_at,
                started_at: job.started_at,
                finished_at: job.finished_at,
                process_type: job.process_type,
                message: job.message,
                error_message: job.error_message,
                creator:  "#{job.creator.first_name} #{job.creator.last_name}",
                filename: job.filename,
                id: job.id,
            }
        end

        render json: { records: response, active: Job.active.count > 0 ? true : false }
    end

end
