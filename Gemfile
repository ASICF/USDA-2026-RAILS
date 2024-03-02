source 'https://rubygems.org'
#ruby=2.6.2
#ruby-gemset=rails522

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.2.1'
gem 'pg'
gem 'activerecord-postgis-adapter'
gem 'normalize-rails'
gem 'semantic-ui-sass', github: 'doabit/semantic-ui-sass'
gem 'kaminari'
gem 'puma', '~> 3.12'
gem 'rgeo'
gem 'rgeo-geojson'
gem 'rgeo-activerecord'
gem "rgeo-proj4", '~> 2.0.1'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
# gem 'omniauth-google-oauth2'
gem 'devise'
gem 'cancancan'
gem 'enumerize'
gem 'public_activity'
gem 'solar', git: 'https://github.com/Bongs/solar.git', branch: 'fix_ajd'
gem 'timezone', '~> 1.0'
gem 'rgeo-shapefile'
gem 'axlsx'
gem 'react-rails', '~> 1.8.2'
gem 'paper_trail'
gem 'delayed_job_active_record'
gem 'daemons'
gem 'whenever', require: false
gem 'zip-zip'
gem 'csv', '~> 3.0.0'
gem 'pg_search'
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'
gem 'mimemagic', '~> 0.3.10'
gem 'webpacker'
gem 'business_time'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'pry-rails'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  # gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
