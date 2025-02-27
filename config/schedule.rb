# env :PATH, ENV['PATH']
# env :GEM_PATH, ENV['GEM_PATH']

set :output, {
  error: "/tmp/usda_crontab_error.log",
  standard: '/tmp/usda_crontab_standard.log'
}

job_type :envcommand, 'cd :path && RAILS_ENV=:environment :task'

# Every time the server is rebooted it *should* start up the delayed job service
# every :reboot do
#   envcommand 'RAILS_ENV=production bin/delayed_job start'
# end

# Problems with RVM so set bundle_command and create a new runner
if @environment == 'development'
  set :bundle_command, '/home/booshwa/.rvm/rubies/ruby-2.6.2/bin/bundle exec'
else
  set :bundle_command, '/home/booshwa/.rvm/rubies/ruby-2.6.2/bin/bundle exec'
end

job_type :bundle_runner, "cd :path && DISABLE_SPRING=true :bundle_command rails runner -e :environment ':task' :output"

# Perform every 30 minutes
every 30.minutes do 
  # Run a database stability check every 5 minutes
  bundle_runner "Audit.quick_audit"
end

# Perform every 5 minutes
every 5.minutes do 
  # Check if there is any mail that did not get sent
  bundle_runner "Mailbox.check_unsent_emails"
end

# Run every weekday at 8am
every '0 8 * * *' do
  bundle_runner "Tile.ready_to_ship_notifier"
  bundle_runner "Tile.notify_easements_with_multiple_coverages"
  bundle_runner "Task.sanity_check"
end

# run every night at 11pm
every '10 23 * * *' do
  bundle_runner "Tile.generate_wip_by_state_export"
end

# run every night at midnight
every '10 0 * * *' do
  bundle_runner "Audit.nightly_audit"
end

# Update the flight times everyday at 1am
every '10 1 * * *' do
  bundle_runner "Task.add_new_flight_time"
end

# Run every sunday at 3am
every '10 3 * * 0' do
  bundle_runner "Task.update_search_terms"
end

# Every weekday at 2pm check for pending Daily Progress Reports
every :weekday, at: '2pm' do
  runner "DailyProgressReport.daily_check"
end