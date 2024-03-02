class PostmasterMailer < ApplicationMailer

    def notify user, message, subject="USDA #{Rails.application.secrets.project_year}", token=nil, url=root_url

        p "------"
        p user
        p message
        p subject
        p token
        p url
        p "------"

        @message = message
        @token = token
        @url = url
        @url = root_url if url.nil?

        mail(to: user.email, subject: subject)
    end

end
