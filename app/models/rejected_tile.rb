class RejectedTile < ApplicationRecord
    include Concerns::Archive

    # Associations
    belongs_to :easement
    belongs_to :plane, optional: true
    belongs_to :camera, optional: true
    belongs_to :packing_slip, optional: true
    belongs_to :state
    belongs_to :county
    belongs_to :tile
    belongs_to :flown_by, class_name: 'Company', optional: true
    belongs_to :contract_award, optional: true
    belongs_to :production_rate, class_name: 'ContractRate', optional: true
    belongs_to :flight_rate, class_name: 'ContractRate', optional: true
    has_many :historic_assocs, as: :historicable, dependent: :destroy
    has_many :histories, through: :historic_assocs
    has_many :rejected_tile_footprints
    has_many :rejected_footprints, through: :rejected_tile_footprints

    # Scopes
    # => Date Baed Status Scopes
    scope :sl,                      -> { where(project: "SL") }
    scope :nri,                     -> { where(project: "NRI") }
    scope :rejection_not_reported,  -> { where(rejection_report_date: nil) }
    scope :rejection_reported,      -> { where.not(rejection_report_date: nil) }
    scope :flown,                   -> { where.not(flight_date: nil) }
    scope :not_flown,               -> { where(flight_date: nil) }
    scope :county_flown,            -> { where.not(county_flown_date: nil) }
    scope :county_not_flown,        -> { where(county_flown_date: nil) }
    scope :county_due_set,          -> { where.not(county_due_date: nil) }
    scope :county_due_date_not_set, -> { where(county_due_date: nil) }
    scope :not_reported,            -> { where(report_date: nil) }
    scope :reported,                -> { where.not(report_date: nil) }
    scope :asi_accepted,            -> { where(asi_rejected_date: nil).where.not(flight_date: nil) }
    scope :asi_rejected,            -> { where.not(asi_rejected_date: nil) }
    scope :usda_accepted,           -> { where.not(usda_accepted_date: nil) }
    scope :not_usda_accepted,       -> { where(usda_accepted_date: nil) }
    scope :usda_rejected,           -> { where.not(usda_rejected_date: nil) }
    scope :not_usda_rejected,       -> { where(usda_rejected_date: nil) }
    scope :at_started,              -> { where.not(at_start_date: nil) }
    scope :not_at_started,          -> { where(at_start_date: nil, at_done_date: nil) }
    scope :at_in_process,           -> { where.not(at_start_date: nil).where(at_done_date: nil) }
    scope :at_done,                 -> { where.not(at_start_date: nil, at_done_date: nil) }
    scope :dumped,                  -> { where.not(dump_date: nil) }
    scope :not_dumped,              -> { where(dump_date: nil) }
    scope :ortho_processing,        -> { where.not(ortho_proc_date: nil) }
    scope :ortho_processed,         -> { where.not(ortho_proc_date: nil) }
    scope :shipped,                 -> { where.not(ship_date: nil) }
    scope :not_shipped,             -> { where(ship_date: nil) }
    scope :has_rejections,          -> { includes(:rejected_tiles).where.not(rejected_tiles: { id: nil }) }
    scope :exclude_geom,            -> { select( Tile.attribute_names - ['geom'] ) }
    scope :covered,                 -> { where(covered: true) }

    def self.reject tile, type="ASI Reject", skip_coverage=false

        # Start a Transaction Block
        ActiveRecord::Base.transaction(joinable: false, requires_new: true) do
            begin

                # create a copy of the tile to store in the Rejected Tile
                new_tile = tile.as_json
                new_tile.delete("id")
                new_tile.delete("review_desc")
                new_tile.delete("upload_id")
                new_tile.delete("covered")
                new_tile.delete("associate_date")
                new_tile["rejected_date"] = Time.now
                new_tile["rejection_type"] = type

                # Create the rejected tile
                rejected_tile = tile.rejected_tiles.new(new_tile)

                if !rejected_tile.save
                    Rails.logger.error "Rejected Tile Error"
                    Rails.logger.error rejected_tile.errors.full_messages.to_sentence
                    raise Exception, rejected_tile.errors.full_messages.to_sentence
                end

                # Update any existing RTFs
                RejectedTileFootprint.where(
                    flight_date: tile.flight_date,
                    tile_id: tile.id, 
                    camera_id: tile.camera_id,
                    flown_by_id: tile.flown_by_id,
                    rejected_tile_id: nil
                ).update_all(rejected_tile_id: rejected_tile.id)

                # Iterate the tile's tile_footprint
                # Check if the rtf exists
                # if not then create it
                tile.footprints.each do |footprint|

                    # See if the the rtf exists or not (would have been created by the footprint)
                    if RejectedTileFootprint.find_by(
                        flight_date: tile.flight_date,
                        strip_frame: footprint.strip_frame,
                        tile_id: tile.id, 
                        camera_id: tile.camera_id,
                        flown_by_id: tile.flown_by_id,
                        original_footprint_id: footprint.id
                    ).nil?
                        rejected_tile.rejected_tile_footprints.create(
                            flight_date: tile.flight_date,
                            strip_frame: footprint.strip_frame,
                            tile_id: tile.id, 
                            camera_id: tile.camera_id,
                            flown_by_id: tile.flown_by_id,
                            original_footprint_id: footprint.id,
                            rejected_footprint_id: nil
                        )
                    end
                end

                # Check if the tile has a covered date and if so then revert all the tiles in the county
                if tile.county_flown_date && tile.ship_date.nil?
                    tile.county.tiles.update(
                        county_flown_date: nil,
                        county_due_date: nil
                    )
                end

                # Update the tile's rejected_date
                tile.update(
                    filename: nil,
                    psn: nil,
                    flight_date: nil,
                    county_flown_date: nil,
                    county_due_date: nil,
                    median_flight_date_time: nil,
                    report_date: nil,
                    at_start_date: nil, 
                    at_done_date: nil, 
                    ortho_proc_date: nil, 
                    dump_date: nil, 
                    ship_date: nil, 
                    asi_rejected_date: nil, 
                    usda_rejected_date: nil, 
                    flown_by_name: nil,
                    flown_by_alias: nil,
                    pilot: nil,
                    sensor_operator: nil,
                    plane_name: nil,
                    camera_name: nil,
                    notes: nil,
                    camera_id: nil,
                    plane_id: nil,
                    packing_slip_id: nil,
                    usda_accepted_date: nil,
                    flown_by_id: nil, 
                    production_upload_date: nil,
                    covered: false,
                    flight_amount: nil,
                    production_amount: nil,
                    total_amount: nil,
                    sub_flight_cost: nil,
                    sub_production_cost: nil,
                    sub_total_cost: nil,
                    production_rate_id: nil,
                    flight_rate_id: nil
                )

                # Update the Flight Times for the Tile since it is no marked as ready to fly
                tile.generate_sun_angles Date.tomorrow, 6

                # update the contract rate
                tile.set_contract_rate

                # pass value to skip for coverage check of easements from specific automated processes
                if !skip_coverage

                    # check if the tile has any coverage other than it's associated footprints
                    coverage = tile.find_covered rejected_tile.flight_date

                    # Check if the coverage size is greater than zero
                    if coverage[:result].size > 0
                        tile.update(covered: true)

                        html = "<p>The Tile <b>#{tile.poly_id}</b> has been rejected but there are other footprints that completely cover the associated Easement. Please verify if the Footprints are valid or not and update the Tile in the Easements with Multiple Coverages. The Easement is marked as Ready to Fly and will be included in future Sites to Fly exports.</p>"
                        html += "<p>Possible Footprint Associations:</p>" 

                        html += '<ul>'
                        coverage[:result].each do |record|
                            html += "<li>#{record[:strip_frames].size} Footprints flown by #{record[:flown_by_alias]} on #{Date.strptime(record[:flight_date], "%F").strftime("%m/%d/%Y")}</li>"
                        end
                        html += '</ul>'

                        # Log and send email
                        Mailbox.ship({
                            users: MailGroup.find_by(name: "Easements with Multiple Coverages").users,
                            subject: "#{tile.project} Easements with Multiple Coverages",
                            message: html,
                            route: Rails.application.routes.url_helpers.easements_with_multiple_coverages_url(only_path: false, host: Rails.application.secrets.host)
                        })

                        # # send email about how the tile that has no associations currently has coverage
                        # Rails.application.secrets.multiple_covered_users.each do |user_obj|
                        #     record = User.find_by(user_obj)
                        #     next if record.nil?
                        #     PostmasterMailer.notify(record, "The Tile <b>#{tile.poly_id}</b> has been rejected but there are footprints that completely cover the associated Easement. Please verify if the Footprints are valid or not and update the Tile in the Easements with Multiple Coverages. The Easement is marked as Ready to Fly and will be included in future Sites to Fly exports".html_safe, "USDA #{Rails.application.secrets.project_year}: Rejected Tile has Covered Footprints - #{Time.now.strftime("%m/%d/%Y")}", Rails.application.routes.url_helpers.easements_with_multiple_coverages_url(only_path: false, host: Rails.application.secrets.host)).deliver
                        # end
                    end
                end

                # reset the associated footprint
                tile.footprints = []

                return rejected_tile

            rescue => exception
                Rails.logger.error "Rejected Tiles Error: #{exception.message}"
                raise ActiveRecord::Rollback
            end
        end
    end

    def unreject current_user

        # Find the Rejected Tile
        # Match the tile has the same polyid
        if self.poly_id != self.tile.poly_id
            return {
                status: false,
                message: "Rejeced PolyID does not match the existing Tile PolyID"
            }
        end

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                # Check if the current tile has a flight date or not
                # => If it does then we need to reject the current tile so that we can track those changes
                if self.tile.flown
                
                    # Create a new History record
                    history = History.new
                    history.action_type = "Rejected Tiles"
                    history.creator = current_user
                    history.save

                    # Reject the tiles
                    rejection_output, history = Rejection.reject_tiles [self.tile.poly_id], self.tile.flight_date, history

                    history.update(message: "Manually Rejected #{history.rejected_tiles.count} Tiles, #{history.rejected_footprints.count} Footprints, and #{history.rejected_frame_centers.count} Frame Centers")
                end

                # #get the rejected tile as json
                rt = self.as_json

                # # Remove unnecessary fields
                rt.delete("id")
                # rt.delete("upload")
                rt.delete("rejected_date")
                rt.delete("rejection_type")
                rt.delete("tile_id")
                rt.delete("rejection_report_date")
                
                # # update the tile
                self.tile.update(rt)
                
                # Update the easement's flight date
                self.easement.update(flight_date: self.flight_date)

                # Remove the flight times from the restored tile
                self.tile.flight_times.destroy_all

                # Create a new History record
                history = History.new
                history.message = "Rejected Tile with PolyID of #{tile.poly_id} and flight date of #{tile.flight_date.strftime("%m/%d/%Y")} has been restored."
                history.action_type = "Unreject Tile"
                history.creator = current_user
                history.save

                # add records to polymorphic association
                history.tiles << self.tile
                history.rejected_tiles << self

                # Check if there is any unrejected tile footprints that match footprints that were not rejected
                self.rejected_tile_footprints.each do |rtf|
                    # p "+++"
                    # p rtf
                    # p "+++"

                    # check if the rejected tile footprint has a rejected footprint
                    if rtf.rejected_footprint_id.present?

                        # Unreject the footprint
                        footprint = rtf.rejected_footprint.unreject

                        # p rtf.rejected_footprint.rejected_frame_center.present?

                        if rtf.rejected_footprint.rejected_frame_center.present?

                            # Unreject the rejected footprint's rejected frame center
                            frame_center = rtf.rejected_footprint.rejected_frame_center.unreject footprint

                            # Delete the rejected frame centers
                            rtf.rejected_footprint.rejected_frame_center.destroy

                            # history.rejected_frame_centers << rtf.rejected_footprint.rejected_frame_center
                            history.frame_centers << frame_center
                        end

                        # Check if the rejected footprint is associated to any other rejected tile
                        if rtf.rejected_footprint.rejected_tiles.where.not(tile_id: self.id).count == 0
                            rtf.rejected_footprint.destroy
                        end

                        # Push the footprint and rejected footprint to history
                        history.rejected_footprints << rtf.rejected_footprint

                    else

                        # Find the footprint and make sure it matches the same fields
                        footprint = Footprint.find_by(
                            id: rtf.original_footprint_id,
                            strip_frame: rtf.strip_frame,
                            flight_date: rtf.flight_date,
                            camera_id: rtf.camera_id,
                            flown_by_id: rtf.flown_by_id
                        )

                    end

                    if footprint.present?

                        # Push footprint to history
                        history.footprints << footprint

                        # Associate the Footprint to the tile
                        tile.footprints << footprint

                    end

                    # Destroy the Rejected Tile Footprint
                    rtf.destroy

                end

                # once the tile has been restored check if the county is fully flown
                Tile.delay.check_fully_flown_counties self.tile.project

                # Destroy the Rejected Tile
                self.class.destroy(self.id)

                # cleanup
                # Check if the rejected footprints have any other associated Rejected Tiles
                # => if not then remove them
                # Remove the associated Rejected Frame Centers
                # Remove the rejected footprint

                return {
                    status: true,
                    message: "Successfully restored Rejected Tile"
                }
            rescue ActiveRecord::StatementInvalid => exception
                return {
                    status: false,
                    message: exception.message
                }
            end
        end

    end

    def self.fix_unmatched_footprints poly_ids

        # # Iterate the unrejected tiles
        Tile.where(poly_id: poly_ids).each do |tile|
      
            rejected_tile = tile.rejected_tiles.first

            p "TILE: #{tile.poly_id}"

            rejected_tile.rejected_tile_footprints.each do |rtf|

                if rtf.rejected_footprint_id.nil?

                     # Find the footprint and make sure it matches the same fields
                     footprint = Footprint.find_by(
                        id: rtf.original_footprint_id,
                        strip_frame: rtf.strip_frame,
                        flight_date: rtf.flight_date,
                        camera_id: rtf.camera_id,
                        flown_by_id: rtf.flown_by_id
                    )

                    if footprint.present?
                        p "- Found footprint #{footprint.id}"
                        tile.footprints << footprint
                    else
                        p "- Could not find footprint"
                    end

                end

            end

        end
        return false
    end

    # def self.rejection_check

    #     match = []
    #     RejectedTile.all.each do |rt|
    #         match << rt.poly_id if rt.tile.flight_date == rt.flight_date
    #     end

    #     p match
    #     p match.count

    # end

end