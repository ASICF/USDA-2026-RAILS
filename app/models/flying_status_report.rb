class FlyingStatusReport < ApplicationRecord

    def self.other project, state, date_flown_from, date_flown_end

        result = []

        Tile.where(state_id: state.id, flight_date: date_flown_from..date_flown_end, project: project).select(:flown_by_name, :camera_name, :county_name).distinct.to_a.sort_by(&:county_name).each do |group|

            # Get the totals
            scoped_tiles = state.tiles.includes(:easement).where(flight_date: date_flown_from..date_flown_end, flown_by_name: group[:flown_by_name], camera_name: group[:camera_name], county_name: group[:county_name], project: project)
            rejected_tiles = state.rejected_tiles.where(flight_date: date_flown_from..date_flown_end, flown_by_name: group[:flown_by_name], camera_name: group[:camera_name], county_name: group[:county_name], project: project)
            total_flown = scoped_tiles.count + rejected_tiles.count
  
            result << {
                project: project,
                flown_by: group[:flown_by_name],
                county_name: group[:county_name],
                camera_name: group[:camera_name],
                total_flown: total_flown,
                acres: scoped_tiles.map {|tile| tile.easement.acres}.inject(:+).to_f.round(2),
                asi_accepted: scoped_tiles.count,
                asi_rejected: rejected_tiles.count,
                usda_accepted: scoped_tiles.usda_accepted.count,
                usda_rejected: scoped_tiles.usda_rejected.count,
                asi_accepted_percentage: (scoped_tiles.count.to_f / total_flown.to_f * 100).round(2),
                asi_rejected_percentage: (rejected_tiles.count.to_f / total_flown.to_f * 100).round(2),
                usda_accepted_percentage: (scoped_tiles.usda_accepted.count.to_f / total_flown * 100).round(2),
                usda_rejected_percentage: (scoped_tiles.usda_rejected.count.to_f / total_flown * 100).round(2)
            }
  
          end

          result

    end

    def self.otherNaip state, date_flown_from, date_flown_end

        obj = {}
        ids = []

        doqq_ids = Doqq.select(:id).where(state_id: state.id, flight_date: date_flown_from..date_flown_end).pluck(:id)
        DoqqFootprint.includes(:doqq, :footprint).where(doqq_id: doqq_ids).order("footprints.flown_by_name DESC, camera_name DESC").each do |df|

            next if ids.include? df.doqq.id

            obj[df.footprint.flown_by_name] = {} if obj[df.footprint.flown_by_name].nil?
            obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"] = {} if obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"].nil?

            if obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"].empty?
                obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"] = {
                    flown_by: df.footprint.flown_by_name,
                    camera_name: df.footprint.camera_name,
                    total_flown: 1,
                    sq_miles: df.doqq.sq_miles,
                    asi_accepted: 1,
                    asi_rejected: RejectedDoqq.where(qq_apfo_name: df.doqq.qq_apfo_name).count,
                    usda_accepted: df.doqq.usda_accepted ? 1 : 0,
                    usda_rejected: 0,
                    asi_accepted_percentage: 0,
                    asi_rejected_percentage: 0,
                    usda_accepted_percentage: 0,
                    usda_rejected_percentage: 0,
                } 
            else
                obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"][:total_flown] += 1
                obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"][:sq_miles] += df.doqq.sq_miles
                obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"][:asi_accepted] += 1
                obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"][:asi_rejected] += RejectedDoqq.where(qq_apfo_name: df.doqq.qq_apfo_name).count
                obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"][:usda_accepted] += df.doqq.usda_accepted ? 1 : 0
                obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"][:usda_rejected] += 0
            end

            ids << df.doqq.id

        end

        result = obj.flatten.select { |record| record.class == Hash && !record.empty? }

        result.each do |record|

            record[:sq_miles] = record[:sq_miles].to_f.round(2)
            record[:asi_accepted_percentage] = (record[:asi_accepted].to_f / record[:total_flown].to_f * 100).round(2)
            record[:asi_rejected_percentage] = (record[:usda_rejected].to_f / record[:total_flown].to_f * 100).round(2)
            record[:usda_accepted_percentage] =  (record[:usda_accepted].to_f / record[:total_flown] * 100).round(2)
            record[:usda_rejected_percentage] = (record[:usda_rejected].to_f / record[:total_flown] * 100).round(2)

        end

        result

    end

    def self.AllSitesByContractor project, date_flown_from, date_flown_end

        result = []

        Tile.where(flight_date: date_flown_from..date_flown_end, project: project).select(:flown_by_name, :camera_name).distinct.to_a.sort { |a, b| [a[:flown_by_name], a[:camera_name]] <=> [b[:flown_by_name], b[:camera_name]] }.each do |group|

            # Get the totals
            scoped_tiles = Tile.includes(:easement).where(flight_date: date_flown_from..date_flown_end, flown_by_name: group[:flown_by_name], camera_name: group[:camera_name], project: project)
            rejected_tiles = RejectedTile.where(flight_date: date_flown_from..date_flown_end, flown_by_name: group[:flown_by_name], camera_name: group[:camera_name], project: project)
            total_flown = scoped_tiles.count + rejected_tiles.count
  
            result << {
                project: project,
                flown_by: group[:flown_by_name],
                camera_name: group[:camera_name],
                total_flown: total_flown,
                acres: scoped_tiles.map {|tile| tile.easement.acres}.inject(:+).to_f.round(2),
                asi_accepted: scoped_tiles.count,
                asi_rejected: rejected_tiles.count,
                usda_accepted: scoped_tiles.usda_accepted.count,
                usda_rejected: scoped_tiles.usda_rejected.count,
                asi_accepted_percentage: (scoped_tiles.count.to_f / total_flown.to_f * 100).round(2),
                asi_rejected_percentage: (rejected_tiles.count.to_f / total_flown.to_f * 100).round(2),
                usda_accepted_percentage: (scoped_tiles.usda_accepted.count.to_f / total_flown * 100).round(2),
                usda_rejected_percentage: (scoped_tiles.usda_rejected.count.to_f / total_flown * 100).round(2)
            }

        end

        result

    end

    def self.AllSitesByContractorNAIP date_flown_from, date_flown_end

        obj = {}
        ids = []

        doqq_ids = Doqq.select(:id).where(flight_date: date_flown_from..date_flown_end).pluck(:id)
        DoqqFootprint.includes(:doqq, :footprint).where(doqq_id: doqq_ids).order("footprints.flown_by_name DESC, camera_name DESC").each do |df|

            next if ids.include? df.doqq.id

            obj[df.footprint.flown_by_name] = {} if obj[df.footprint.flown_by_name].nil?
            obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"] = {} if obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"].nil?

            if obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"].empty?
                obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"] = {
                    flown_by: df.footprint.flown_by_name,
                    camera_name: df.footprint.camera_name,
                    total_flown: 1,
                    sq_miles: df.doqq.sq_miles,
                    asi_accepted: 1,
                    asi_rejected: RejectedDoqq.where(qq_apfo_name: df.doqq.qq_apfo_name).count,
                    usda_accepted: df.doqq.usda_accepted ? 1 : 0,
                    usda_rejected: 0,
                    asi_accepted_percentage: 0,
                    asi_rejected_percentage: 0,
                    usda_accepted_percentage: 0,
                    usda_rejected_percentage: 0,
                } 
            else
                obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"][:total_flown] += 1
                obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"][:sq_miles] += df.doqq.sq_miles
                obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"][:asi_accepted] += 1
                obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"][:asi_rejected] += RejectedDoqq.where(qq_apfo_name: df.doqq.qq_apfo_name).count
                obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"][:usda_accepted] += df.doqq.usda_accepted ? 1 : 0
                obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"][:usda_rejected] += 0
            end

            ids << df.doqq.id

        end

        result = obj.flatten.select { |record| record.class == Hash && !record.empty? }

        result.each do |record|

            record[:sq_miles] = record[:sq_miles].to_f.round(2)
            record[:asi_accepted_percentage] = (record[:asi_accepted].to_f / record[:total_flown].to_f * 100).round(2)
            record[:asi_rejected_percentage] = (record[:usda_rejected].to_f / record[:total_flown].to_f * 100).round(2)
            record[:usda_accepted_percentage] =  (record[:usda_accepted].to_f / record[:total_flown] * 100).round(2)
            record[:usda_rejected_percentage] = (record[:usda_rejected].to_f / record[:total_flown] * 100).round(2)

        end

        result

    end

    def self.AllSitesByState project, date_flown_from, date_flown_end

        result = []

        if project == "NRI"
             states = State.includes(:tiles).exclude_geom.active_nri
        elsif project == "SL"
            states = State.includes(:tiles).exclude_geom.active_sl
        end

        states.each do |state|

            # Get the totals
            scoped_tiles = state.tiles.includes(:easement).where(flight_date: date_flown_from..date_flown_end, project: project)
            rejected_tiles = state.rejected_tiles.where(flight_date: date_flown_from..date_flown_end, project: project)
            total_flown = scoped_tiles.count + rejected_tiles.count
  
            asi_accepted_percentage = (scoped_tiles.count.to_f / total_flown.to_f * 100).round(2)
            asi_rejected_percentage = (rejected_tiles.count.to_f / total_flown.to_f * 100).round(2)
            usda_accepted_percentage = (scoped_tiles.usda_accepted.count.to_f / total_flown * 100).round(2)
            usda_rejected_percentage = (scoped_tiles.usda_rejected.count.to_f / total_flown * 100).round(2)

            result << {
                project: project,
                state_name: state.name,
                total_sites: state.tiles.count,
                total_flown: total_flown,
                acres: scoped_tiles.map {|tile| tile.easement.acres}.inject(:+).to_f.round(2),
                asi_accepted: scoped_tiles.count,
                asi_rejected: rejected_tiles.count,
                usda_accepted: scoped_tiles.usda_accepted.count,
                usda_rejected: scoped_tiles.usda_rejected.count,
                asi_accepted_percentage: asi_accepted_percentage.nan? ? 0.0 : asi_accepted_percentage,
                asi_rejected_percentage: asi_rejected_percentage.nan? ? 0.0 : asi_rejected_percentage,
                usda_accepted_percentage: usda_accepted_percentage.nan? ? 0.0 : usda_accepted_percentage,
                usda_rejected_percentage: usda_rejected_percentage.nan? ? 0.0 : usda_rejected_percentage
            }

        end

        result

    end

    def self.AllSitesByStateNAIP date_flown_from, date_flown_end

        result = []

        State.includes(:doqqs).exclude_geom.active_naip.each do |state|

            # Get the totals
            scoped_doqqs = state.doqqs.where(flight_date: date_flown_from..date_flown_end)
            rejected_doqqs = state.rejected_doqqs.where(flight_date: date_flown_from..date_flown_end)
            total_flown = scoped_doqqs.count + rejected_doqqs.count
  
            asi_accepted_percentage = (scoped_doqqs.count.to_f / total_flown.to_f * 100).round(2)
            asi_rejected_percentage = (rejected_doqqs.count.to_f / total_flown.to_f * 100).round(2)
            usda_accepted_percentage = (scoped_doqqs.usda_accepted.count.to_f / total_flown * 100).round(2)
            usda_rejected_percentage = (scoped_doqqs.usda_rejected.count.to_f / total_flown * 100).round(2)

            result << {
                state_name: state.name,
                total_sites: state.doqqs.count,
                total_flown: total_flown,
                sq_miles: scoped_doqqs.map {|doqq| doqq.sq_miles}.inject(:+).to_f.round(2),
                asi_accepted: scoped_doqqs.count,
                asi_rejected: rejected_doqqs.count,
                usda_accepted: scoped_doqqs.usda_accepted.count,
                usda_rejected: scoped_doqqs.usda_rejected.count,
                asi_accepted_percentage: asi_accepted_percentage.nan? ? 0.0 : asi_accepted_percentage,
                asi_rejected_percentage: asi_rejected_percentage.nan? ? 0.0 : asi_rejected_percentage,
                usda_accepted_percentage: usda_accepted_percentage.nan? ? 0.0 : usda_accepted_percentage,
                usda_rejected_percentage: usda_rejected_percentage.nan? ? 0.0 : usda_rejected_percentage
            }

        end

        result

    end

    def self.AllSitesByContractorAndState project, date_flown_from, date_flown_end

        result = []

        # Tile.where(flight_date: date_flown_from..date_flown_end).select(:flown_by_name).order(:flown_by_name).distinct.to_a.each do |group|
        Tile.where(flight_date: date_flown_from..date_flown_end, project: project).select(:flown_by_name, :state_name, :state_id).distinct.to_a.sort { |a, b| [a[:flown_by_name], a[:state_name]] <=> [b[:flown_by_name], b[:state_name]] }.each do |group|

            state = State.exclude_geom.includes(:tiles).find(group["state_id"])

            # Get the totals
            scoped_tiles = state.tiles.includes(:easement).where(flight_date: date_flown_from..date_flown_end, flown_by_name: group[:flown_by_name], project: project)
            rejected_tiles = state.rejected_tiles.where(flight_date: date_flown_from..date_flown_end, flown_by_name: group[:flown_by_name], project: project)
            total_flown = scoped_tiles.count + rejected_tiles.count

            result << {
                project: project,
                state_name: state.name,
                flown_by: group[:flown_by_name],
                total_flown: total_flown,
                acres: scoped_tiles.map {|tile| tile.easement.acres}.inject(:+).to_f.round(2),
                asi_accepted: scoped_tiles.count,
                asi_rejected: rejected_tiles.count,
                usda_accepted: scoped_tiles.usda_accepted.count,
                usda_rejected: scoped_tiles.usda_rejected.count,
                asi_accepted_percentage: (scoped_tiles.count.to_f / total_flown.to_f * 100).round(2),
                asi_rejected_percentage: (rejected_tiles.count.to_f / total_flown.to_f * 100).round(2),
                usda_accepted_percentage: (scoped_tiles.usda_accepted.count.to_f / total_flown * 100).round(2),
                usda_rejected_percentage: (scoped_tiles.usda_rejected.count.to_f / total_flown * 100).round(2)
            }

        end

        result

    end

    def self.AllSitesByContractorAndStateNAIP date_flown_from, date_flown_end

        obj = {}
        ids = []

        doqq_ids = Doqq.select(:id).where(flight_date: date_flown_from..date_flown_end).pluck(:id)
        DoqqFootprint.includes(:doqq, :footprint).where(doqq_id: doqq_ids).order("footprints.flown_by_name DESC, footprints.state_name DESC").each do |df|

            next if ids.include? df.doqq.id

            obj[df.footprint.flown_by_name] = {} if obj[df.footprint.flown_by_name].nil?
            obj["#{df.footprint.flown_by_id}_#{df.footprint.state_id}"] = {} if obj["#{df.footprint.flown_by_id}_#{df.footprint.state_id}"].nil?

            if obj["#{df.footprint.flown_by_id}_#{df.footprint.state_id}"].empty?
                obj["#{df.footprint.flown_by_id}_#{df.footprint.state_id}"] = {
                    flown_by: df.footprint.flown_by_name,
                    state_name: df.footprint.state_name,
                    total_flown: 1,
                    sq_miles: df.doqq.sq_miles,
                    asi_accepted: 1,
                    asi_rejected: RejectedDoqq.where(qq_apfo_name: df.doqq.qq_apfo_name).count,
                    usda_accepted: df.doqq.usda_accepted ? 1 : 0,
                    usda_rejected: 0,
                    asi_accepted_percentage: 0,
                    asi_rejected_percentage: 0,
                    usda_accepted_percentage: 0,
                    usda_rejected_percentage: 0,
                } 
            else
                obj["#{df.footprint.flown_by_id}_#{df.footprint.state_id}"][:total_flown] += 1
                obj["#{df.footprint.flown_by_id}_#{df.footprint.state_id}"][:sq_miles] += df.doqq.sq_miles
                obj["#{df.footprint.flown_by_id}_#{df.footprint.state_id}"][:asi_accepted] += 1
                obj["#{df.footprint.flown_by_id}_#{df.footprint.state_id}"][:asi_rejected] += RejectedDoqq.where(qq_apfo_name: df.doqq.qq_apfo_name).count
                obj["#{df.footprint.flown_by_id}_#{df.footprint.state_id}"][:usda_accepted] += df.doqq.usda_accepted ? 1 : 0
                obj["#{df.footprint.flown_by_id}_#{df.footprint.state_id}"][:usda_rejected] += 0
            end

            ids << df.doqq.id

        end

        result = obj.flatten.select { |record| record.class == Hash && !record.empty? }

        result.each do |record|

            record[:sq_miles] = record[:sq_miles].to_f.round(2)
            record[:asi_accepted_percentage] = (record[:asi_accepted].to_f / record[:total_flown].to_f * 100).round(2)
            record[:asi_rejected_percentage] = (record[:usda_rejected].to_f / record[:total_flown].to_f * 100).round(2)
            record[:usda_accepted_percentage] =  (record[:usda_accepted].to_f / record[:total_flown] * 100).round(2)
            record[:usda_rejected_percentage] = (record[:usda_rejected].to_f / record[:total_flown] * 100).round(2)

        end

        result

    end

end
