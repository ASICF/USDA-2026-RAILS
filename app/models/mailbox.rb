class Mailbox < ApplicationRecord

    # Assocations
    belongs_to :user

    # Validations
    validates :subject, :message, presence: true

    # Callbacks
    after_create :send_message

    # Scopes
    scope :sent,        -> { where.not(sent_at: nil) }
    scope :not_sent,    -> { where(sent_at: nil) }
    scope :opened,      -> { where.not(opened_at: nil) }
    scope :not_opened,  -> { where(opened_at: nil) }

    # Methods
    def self.ship params=nil

        # Check the parameters for required values
        if params.nil?
            raise Exception, "Mailbox Error: No object "
        elsif params[:subject].blank?
            raise Exception, "Mailbox Error: No Subject found"
        elsif params[:message].blank?
            raise Exception, "Mailbox Error: No Message found"
        elsif params[:users].blank?
            raise Exception, "Mailbox Error: No array of Users provided"
        elsif params[:route].blank?
            params[:route] = nil
        end

        users = params[:users]

        # If in development send to developer
        if Rails.env.development?
            users = User.where(email: Rails.application.secrets.admin[:email])
        end

        # Iterate over the users
        users.each do |user|
            # create the record
            Mailbox.create(
                subject: params[:subject],
                message: params[:message],
                # sent_at: Time.now,
                token: rand(36**12).to_s(36),
                route: params[:route],
                user: user
            )
        end

        p "done"
    end

    def send_message
        begin
            # set the current time
            self.update(sent_at: Time.now)

            mail_user = self.user

            # If in development send to developer
            if Rails.env.development?
                mail_user = User.where(email: Rails.application.secrets.admin[:email]).first
            end

            # Send the mail
            PostmasterMailer.notify(
                mail_user, 
                self.message.html_safe, 
                "USDA #{Rails.env.development? ? "DEV " : ""}#{Rails.application.secrets.project_year}: #{self.subject} - #{Time.now.strftime("%m/%d/%Y")}", 
                self.token,
                self.route
            ).deliver

            return true
        rescue
            p "failed to send message"

            # clear the sent at date since it did not send
            self.update(sent_at: nil)

            return false
        end
    end

    def self.check_unsent_emails
        # part of crontab task that runs ever 5 minutes
        # filter out messages that do not have sent_at date set
        # attempt to send and if it fails again then increment the retry attempt by 1
        # after 3 retries then it is added to history that it could not send. 

        # testing
        # Mailbox.last.update(sent_at: nil)

        Mailbox.not_sent.where("retry_count < 3").each do |mail|

            response = mail.send_message

            # if it fails to send
            if !response

                # increment the retries
                retries = mail.retry_count + 1

                # update the record's retry count
                mail.update(retry_count: retries)

                # if the retires are greater than 3 then create a history record
                if retries == 3
                    # Create a new History record
                    history = History.new
                    history.message = "Failed to send email after 3 retry attempts (id: #{mail.id})"
                    history.action_type = "Mailbox"
                    history.creator = mail.user
                    history.save
                end
            end

        end

    end

end
