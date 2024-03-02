class ReportHistory < ApplicationRecord

    # ASsociations
    belongs_to :user

    # Validation
    validates :name, :user_id, presence: true

    def self.build_report name
        # get the reports
        records = []
        ReportHistory.includes(:user).where(name: name).order(created_at: :DESC).limit(30).each do |record|

            # get the user
            user = record.user

            records << {
                id: record.id,
                name: record.name,
                user_id: record.user_id,
                user_name: "#{user.first_name} #{user.last_name}",
                created_at: record.created_at
            }
        end

        if records.size == 0
            return {
                state: false, 
                message: "No Records found that match #{name}"
            }
        end

        # build the calendar object
        calendar_data = {
            values: {},
            until: records.first[:created_at].strftime("%F")
        }

        # add the 

        # build the calendar data
        records.each do |record|

            # create the calendar property if it's not set
            calendar_data[:values][record[:created_at].strftime("%F")] = 0 if calendar_data[:values][record[:created_at].strftime("%F")].nil?

            calendar_data[:values][record[:created_at].strftime("%F")] += 1
        end

        return {
            state: true,
            message: "Successfully queried #{records.size} records that match \"#{name}\"",
            records: records,
            calendar: calendar_data
        }

    end

end
