class Company < ApplicationRecord
    include Concerns::Archive

    # Associations
    has_many :planes, dependent: :destroy
    has_many :cameras, dependent: :destroy
    has_many :historic_assocs, as: :historicable, dependent: :destroy
    has_many :histories, through: :historic_assocs
    has_many :footprints, foreign_key: :flown_by_id
    has_many :tiles, foreign_key: :flown_by_id
    has_many :doqqs, foreign_key: :flown_by_id
    has_many :rejected_tiles, foreign_key: :flown_by_id

    # Validations
    validates :name, presence: true

    # def self.generate_sub_billing

    #     result = []

    #     Company.includes(cameras: [tiles: [:state]]).where.not(cameras: {tiles: {camera_id: nil}}).order("companies.name DESC").each do |company|

    #         company.cameras.each do |camera|

    #             camera.tiles.flown == 0 ? next : nil

    #             # p camera.tiles.count
    #             # p camera.tiles.includes(:state).pluck(:state_id).uniq.map{|s| State.find(s).abv}
    #             # p camera.tiles.pluck(:psn).uniq

    #             camera.tiles.pluck(:psn).uniq.each do |psn|

    #                 camera.tiles.includes(:state).where(psn: psn).pluck(:state_id).uniq.map{|s| State.find(s)}.each do |state|

                            # TODO -> Update this logic to not use Sum with child associations, iterate and build totals

    #                     shipped_easements = camera.tiles.shipped.where(state: state, psn: psn).group(:easement_id).count
    #                     shipped_acres = camera.tiles.shipped.includes(:easement).where(state: state, psn: psn).group(:easement_id).sum("easements.acres").values.sum

    #                     # p "Shipped Easements: #{shipped_easements}"
    #                     # p "Shipped Easements: #{shipped_acres}"

    #                     result << {
    #                         state: state.abv,
    #                         sensor: camera.name,
    #                         company: company.name,
    #                         billing_per_acre: camera.amount,
    #                         shipped_easements: shipped_easements.values.sum,
    #                         shipped_acres: shipped_acres,
    #                         psn: psn,
    #                         sub_billing_amount: shipped_acres * camera.amount
    #                     }

    #                 end
    #             end
    #         end
    #     end

    #     result = result.sort_by { |r| r[:state] }

    # end

    def self.generate_sub_billing

        result = []

        Company.all.each do |company|

            company.packing_slips.each do |packing_slip|

                packing_slip.tiles.pluck(:camera_id).uniq.map{|c| Camera.find(c)}.each do |camera|

                    states = packing_slip.tiles.pluck(:state_id).uniq.map{|s| State.find(s)}.each do |state|

                        # sum doesn't work due to a bug with Postgres and Rails so iterate the tiles and calculate the totals
                        ids = []
                        shipped_easements = 0
                        shipped_acres = 0
                        packing_slip.tiles.shipped.includes(:easement).where(state: state, camera: camera).each do |tile|
                            # if the tile id exists in the ids array then skip it
                            if ids.include? tile.easement_id
                                next
                            else
                                # calculate the easement counts and acres by adding the tile easement acreage
                                shipped_easements += 1
                                shipped_acres += tile.easement.acres
                                ids << tile.easement_id
                            end
                        end

                        result << {
                            state: state.abv,
                            sensor: camera.name,
                            company: company.name,
                            billing_per_acre: camera.amount,
                            shipped_easements: shipped_easements,
                            shipped_acres: shipped_acres,
                            psn: packing_slip.name,
                            sub_billing_amount: shipped_acres * camera.amount
                        }

                    end

                end

            end

        end

        result = result.sort_by { |r| r[:state] }

    end

end