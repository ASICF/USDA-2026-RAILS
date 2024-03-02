class WebLog < ApplicationRecord

    # Associations
    belongs_to :web_log_upload
    belongs_to :web_log_summary
    belongs_to :vector_metadatum, optional: true

    def self.test

        WebLog.all.each do |log|

            summary = WebLogSummary.find_or_create_by(
                project: log.project,
                log_date: log.logged_at,
                service: log.service,
                ip_address: log.ip_address,
                domain: log.domain,
            )

            p summary

            log.update(web_log_summary: summary)

        end

        WebLogSummary.all.each {|wls| wls.update(count: wls.web_logs.count)}

    end

end
