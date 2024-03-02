Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.default_queue_name = 'default'
Delayed::Worker.max_attempts = 1
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))
# Do not run delayed jobs in development
Delayed::Worker.delay_jobs = Rails.env.development? ? false : true