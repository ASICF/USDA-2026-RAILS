class PackingSlip < ApplicationRecord
    include Concerns::Archive

    # Associations
    belongs_to :invoice, optional: true
    belongs_to :state
    has_many :tiles
    has_many :doqqs
    has_many :rejected_tiles
    has_many :historic_assocs, as: :historicable, dependent: :destroy
    has_many :histories, through: :historic_assocs

    # Validations
    # validates :name, uniqueness: { case_sensitive: false }
    # validates_uniqueness_of :name, :case_sensitive => false
    validates :name, uniqueness: { scope: :project }, :case_sensitive => false

    # Scopes
    scope :sl, -> { where(project: "SL") }
    scope :naip, -> { where(project: "NAIP") }
    scope :invoiced, -> { where.not(invoice_id: nil) }
    scope :not_invoiced, -> { where(invoice_id: nil) }

    def completed
        tiles.count == tiles.usda_accepted.count
    end

    def active
        tiles.count != tiles.usda_accepted.count
    end

    def self.usda_approve params
        # p params
        # p params[:packing_slips]

        # create an Error array to hold any messages
        output = {
            pass: false,
            errors: [],
            count: 0
        }

        user = params[:user]

        if params[:approved_date].blank?
            output[:errors] << "Approved Date is not provided"
            return output
        end

        packing_slips = params[:packing_slips] || []

        if packing_slips.count == 0
            output[:errors] << "No Packing Slips were provided"
            return output
        end

        # p packing_slips

        completed_ps = []
    
        ActiveRecord::Base.transaction do
            begin

                packing_slips.each do |ps_id|
                    p ps_id

                    ps = PackingSlip.find(ps_id)

                    p ps

                    # Update the negative packing slip's Approve Date
                    ps.approved_date = params[:approved_date]

                    if ps.changed?

                        ps.save

                        output[:count] += 1

                        # add upload to history
                        history = History.new
                        history.message = "Approved Packing Slip: #{ps.name} for Negatives"
                        history.action_type = "Approved Packing Slip"
                        history.creator = user
                        history.save

                        p history.errors

                        # add the packing slip to the history
                        history.packing_slips << ps

                        # Add the post flight records to the history record
                        history.tiles << ps.tiles

                        completed_ps << ps

                    end

                    ps.tiles.not_usda_accepted.update(
                        usda_accepted_date: params[:approved_date]
                    )

                end

                # add upload to history
                if output[:count] == 0
                    output[:errors] << "No Packing Slips were approved"
                else
                    # Build a list for the html
                    html = '<ul class="ui list">'
                    completed_ps.each do |ps|
                        html += "<li>#{ps.name}</li>"
                    end
                    html += '</ul>'

                    # Log and send email
                    Mailbox.ship({
                        users: MailGroup.find_by(name: "USDA Approved").users | [user],
                        subject: "USDA Approved Packing Slips",
                        message: "USDA approved the following Packing Slips:<br/>#{html}<br/>Click Link Below to view Packing Slip Worksheet Report".html_safe,
                        route: Rails.application.routes.url_helpers.packing_slip_worksheets_url(only_path: false, host: Rails.application.secrets.host)
                    })

                    # # Send email notifying that the USDA has been approved
                    # Rails.application.secrets.usda_approved_users.each do |user|
                    #     next if User.find_by(user).nil?
                    #     PostmasterMailer.notify(User.find_by(user), "USDA #{Rails.application.secrets.project_year}: USDA approved the following Packing Slips:<br/>#{html}".html_safe).deliver
                    # end
                end

            rescue ActiveRecord::StatementInvalid => exception
                output[:errors] << exception.message
            end

        end

        if output[:errors].count == 0
            output[:pass] = true
        end

        return output

    end

    def self.fix_psns batchProcess, contentFileName

        errors = []

        # Iterate the batch process logs and update the 
        batchProcess.batch_process_logs.each do |log|
            tile = log.tile
            # iF the tile does not have a packign slip then set it
            if tile.packing_slip_id.nil?
                # find the packing slip or create it
                psn = PackingSlip.find_by(name: contentFileName, company: tile.camera.company)
                if psn.nil?
                    psn = PackingSlip.create(name: contentFileName, company: tile.camera.company)
                end

                tile.packing_slip = psn

                if tile.valid?
                    tile.save
                else
                    errors << tile.errors.full_messages.to_sentence
                end
            end
        end

        errors

    end

    # def self.find_packing_slips_with_partial_counties

    #     obj = {}

    #     # Iterate the packing slips
    #     PackingSlip.sl.order(:created_at).each do |ps|

    #         # obj[ps.name] = {
    #         #     # completed_counties: [], 
    #         #     partial_counties: []
    #         # }

    #         arr = []

    #         # pluck the counties from the associated tiles
    #         counties = ps.tiles.pluck(:county_id).uniq

    #         # Iterate the counties and compare the tiles
    #         County.includes(:tiles).where(id: counties).each do |county|
    #             next if ["GA", "IN", "WI", "MN", "OH", "WV"].include? county.state.abv

    #             if county.tiles.count == county.tiles.shipped.where(packing_slip_id: ps.id).count
    #                 # obj[ps.name][:completed_counties] << county.id 
    #             else
    #                 # obj[ps.name][:partial_counties] << county.id
    #                 arr << county.id
    #             end
    #         end

    #         if arr.size > 0
    #             obj[ps.name] = {
    #                 # completed_counties: [], 
    #                 partial_counties: arr
    #             }
    #         end

    #     end

    #     pp obj 

    # end

    # def self.find_full_counties

    #     states = ["GA", "IN", "OH", "MN", "WI"]

    #     State.exclude_geom.includes(:counties).where(abv: states).each do |state|

    #         partial_counties = []
    #         state.counties.includes(:tiles).exclude_geom.active.each do |county|

    #             partial_counties << {name: county.name, state: county.state.name, shipped: county.tiles.shipped.count, total: county.tiles.count} if county.tiles.count != county.tiles.shipped.count

    #         end

    #         p "#{state.abv} | #{partial_counties}"

    #     end

    #     p "done"

    # end

    # def self.test

    #     psns = []
    #     PackingSlip.includes(:tiles).sl.each do |ps|
    #         counties_id = ps.tiles.pluck(:county_id)

    #         arr = []
    #         counties_id.each do |county_id|
    #             arr << county_id if ps.tiles.where(county_id: county_id).count != Tile.where(county_id: county_id).count
    #         end

    #         if arr.size > 0
    #             # psns << {name: ps.name, counties: arr}
    #             psns << ps.name
    #         end
    #     end

    #     pp psns
    #     p "done"

    # end

    # def self.check_counties

    #     partial = []

    #     County.exclude_geom.active.includes(:tiles, :state).order(:state_id).each do |county|

    #         next if ["GA", "IN", "WI", "MN", "OH"].include? county.state.abv

    #         # Get the psn ids
    #         psns = county.tiles.pluck(:packing_slip_id).uniq
    #         next if psns.size == 0

    #         # find the counties that have multiple packing slips and the county tile counts are all flown
    #         # if county.tiles.shipped.count == county.tiles.count && psns.size > 1
    #         #     partial << {name: county.name, psns: psns, total: county.tiles.count}
    #         # end

    #         # Find counties that have any tiles marked as shipped but not the full county. 
    #         if county.tiles.shipped.count > 0 && county.tiles.shipped.count != county.tiles.count
    #             partial << {name: county.name, state_name: county.state.name,  psns: psns, total: county.tiles.count}
    #         end

    #     end

    #     pp partial

    # end

    def self.assign_state
        invoice = Invoice.last
        PackingSlip.all.each do |ps|
            tile = ps.tiles.first
            # ps.update!(state_id: tile.state_id, state_abv: tile.state_abv, invoice_id: invoice.id)
            ps.update!(state_abv: tile.state_abv)
        end
    end

end
