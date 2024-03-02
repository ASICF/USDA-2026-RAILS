class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.secrets.mailer_sender
  layout 'mailer'
end
