class State < ApplicationRecord
    include Concerns::Archive

    # Associations
    has_many :counties
    has_many :easements
    has_many :footprints
    has_many :frame_centers
    has_many :tiles
    has_many :doqqs
    has_many :rejected_tiles
    has_many :rejected_doqqs
    has_many :rejected_footprints
    has_many :rejected_frame_centers
    has_many :contract_rates
    has_many :contract_awards

    # Scopes
    scope :active, -> { where(id: Easement.pluck(:state_id).uniq + Doqq.pluck(:state_id).uniq).order(:name) }
    scope :active_sl, -> { where(id: Easement.sl.pluck(:state_id).uniq).order(:name) }
    scope :active_nri, -> { where(id: Easement.nri.pluck(:state_id).uniq).order(:name) }
    scope :active_nri_sl, -> { where(id: Easement.pluck(:state_id).uniq).order(:name) }
    scope :active_naip, -> { where(id: Doqq.pluck(:state_id).uniq).order(:name) }
    scope :exclude_geom, -> { select( State.attribute_names - ['geom'] ) }
    # Dynamically build the project states
    # Rails.application.secrets.active_naip_states.each {|abv| scope "#{abv.downcase}_naip", -> { where(abv: abv) }}
    Rails.application.secrets.active_sl_states.each {|abv| scope "#{abv.downcase}_sl", -> { find_by(abv: abv) }}
    # Rails.application.secrets.active_nri_states.each {|abv| scope "#{abv.downcase}_nri", -> { where(abv: abv) }}

    def active_counties project
        County.includes(:tiles).where(state: self, tiles: { project: project }).where.not( tiles: { county_id: nil } ).order("name ASC")
    end

    def completed_counties
        County.includes(:tiles).where(state: self).where.not( tiles: { at_start_date: nil, at_done_date: nil, ortho_proc_date: nil } ).order("name ASC")
    end

    def wip_by_state project, date_from, date_to

        selected_tiles = tiles.where(project: project)

        state_acres = selected_tiles.sum(&:easements_acres)

        # Get totals
        total = selected_tiles.count
        acres = selected_tiles.sum(&:easements_acres).to_f
        flown = selected_tiles.flown.where(flight_date: date_from..date_to)
        at_done = selected_tiles.flown.at_done.where(at_done_date: date_from..date_to)
        ortho_proc = selected_tiles.flown.at_done.ortho_processed.where(ortho_proc_date: date_from..date_to)
        dumped = selected_tiles.flown.at_done.ortho_processed.dumped.where(dump_date: date_from..date_to)
        shipped = selected_tiles.flown.at_done.ortho_processed.dumped.shipped.where(ship_date: date_from..date_to)
        invoiced = selected_tiles.flown.at_done.ortho_processed.dumped.shipped.invoiced.where(ship_date: date_from..date_to)

        # Return a hash with the values
        {
            name: self.name,
            acres: acres,
            total: total,
            # cost
            flown_cost: flown.sum(&:total_amount),
            at_done_cost: at_done.sum(&:total_amount),
            ortho_processing_cost: ortho_proc.sum(&:total_amount),
            dumped_cost: dumped.sum(&:total_amount),
            shipped_cost: shipped.sum(&:total_amount),
            invoiced_cost: invoiced.sum(&:total_amount),
            # acres
            flown_acres: flown.sum(&:easements_acres).to_f,
            flown_percentage: (flown.sum(&:easements_acres)/state_acres * 100).to_f,
            at_done_acres: at_done.sum(&:easements_acres).to_f,
            ortho_processing_acres: ortho_proc.sum(&:easements_acres).to_f,
            orthos_percentage: (ortho_proc.sum(&:easements_acres)/state_acres * 100).to_f,
            dumped_acres: dumped.sum(&:easements_acres).to_f,
            shipped_acres: shipped.sum(&:easements_acres).to_f,
            invoiced_acres: invoiced.sum(&:easements_acres).to_f,
            # Counts
            flown_count: flown.count,
            at_done_count: at_done.count,
            ortho_processing_count: ortho_proc.count,
            dumped_count: dumped.count,
            shipped_count: shipped.count,
            invoiced_count: invoiced.count

        }
    end

    def wip_by_state_counties project, date_from, date_to

        result = []
        active_counties(project).exclude_geom.each do |county|

            selected_tiles = county.tiles.where(project: project)

            state_acres = selected_tiles.sum(&:easements_acres)

            # Get totals
            total = selected_tiles.count
            acres = selected_tiles.sum(&:easements_acres).to_f
            flown = selected_tiles.flown.where(flight_date: date_from..date_to)
            at_done = selected_tiles.flown.at_done.where(at_done_date: date_from..date_to)
            ortho_proc = selected_tiles.flown.at_done.ortho_processed.where(ortho_proc_date: date_from..date_to)
            dumped = selected_tiles.flown.at_done.ortho_processed.dumped.where(dump_date: date_from..date_to)
            shipped = selected_tiles.flown.at_done.ortho_processed.dumped.shipped.where(ship_date: date_from..date_to)
            invoiced = selected_tiles.flown.at_done.ortho_processed.dumped.shipped.invoiced.where(ship_date: date_from..date_to)

            # flown_percentage = (((flown.to_d / total.to_d).round(4).to_d).to_d * 100).to_f.round(3)

            # Return a hash with the values
            result << {
                name: self.name,
                county_name: county.name,
                acres: acres,
                total: total,
                # cost
                flown_cost: flown.sum(&:total_amount).to_f,
                at_done_cost: at_done.sum(&:total_amount).to_f,
                ortho_processing_cost: ortho_proc.sum(&:total_amount).to_f,
                dumped_cost: dumped.sum(&:total_amount).to_f,
                shipped_cost: shipped.sum(&:total_amount).to_f,
                invoiced_cost: invoiced.sum(&:total_amount).to_f,
                # acres
                flown_acres: flown.sum(&:easements_acres).to_f,
                flown_percentage: (flown.sum(&:easements_acres)/state_acres * 100).to_f,
                at_done_acres: at_done.sum(&:easements_acres).to_f,
                ortho_processing_acres: ortho_proc.sum(&:easements_acres).to_f,
                orthos_percentage: (ortho_proc.sum(&:easements_acres)/state_acres * 100).to_f,
                dumped_acres: dumped.sum(&:easements_acres).to_f,
                shipped_acres: shipped.sum(&:easements_acres).to_f,
                invoiced_acres: invoiced.sum(&:easements_acres).to_f,
                # Counts
                flown_count: flown.count,
                at_done_count: at_done.count,
                ortho_processing_count: ortho_proc.count,
                dumped_count: dumped.count,
                shipped_count: shipped.count,
                invoiced_count: invoiced.count

                # flown: flown,
                # rejected: rejected,
                # percentage_flown: flown_percentage,
                # at_started: at_started,
                # at_done: at_done,
                # ortho_processed: ortho_proc,
                # dumped: dumped,
                # shipped: shipped,
                # flight_cost: tiles.flown.pluck(:flight_amount).sum.to_f,
                # production_cost: tiles.flown.pluck(:production_amount).sum.to_f,
                # total_cost: tiles.flown.pluck(:total_amount).sum.to_f,
            }
        end

        result
    end

    def naip_wip_by_state date_from, date_to

        # Status Weights
        at_start_weight = 0.13
        at_done_weight = 0.12
        ortho_proc_weight = 0.60
        tile_dump_weight = 0.10
        ship_weight = 0.05

        # Get totals
        total = doqqs.count
        flown = doqqs.flown.where(flight_date: date_from..date_to).count
        at_started = doqqs.flown.at_started.where(at_start_date: date_from..date_to).count
        at_done = doqqs.flown.at_done.where(at_done_date: date_from..date_to).count
        ortho_proc = doqqs.flown.at_done.shipped.where(ship_date: date_from..date_to).count
        dumped = doqqs.flown.at_done.shipped.where(ship_date: date_from..date_to).count
        shipped = doqqs.flown.at_done.shipped.where(ship_date: date_from..date_to).count
        rejected = rejected_doqqs.where(rejected_date: date_from..date_to).count
        
        flown_percentage = (((flown.to_d / total.to_d).round(4).to_d).to_d * 100).to_f.round(3)
        done_percentage = (((
            (at_started.to_d * at_start_weight).to_d +
            (at_done.to_d * at_done_weight).to_d +
            (ortho_proc.to_d * ortho_proc_weight).to_d +
            (dumped.to_d * tile_dump_weight).to_d +
            (shipped.to_d * ship_weight).to_d
        ) / total.to_d).to_d * 100).to_f.round(3)

        # Return a hash with the values
        {
            name: self.name,
            total: total,
            flown: flown,
            rejected: rejected,
            percentage_flown: flown_percentage.nan? ? 0 : flown_percentage,
            at_started: at_started,
            at_done: at_done,
            ortho_processed: ortho_proc,
            dumped: dumped,
            shipped: shipped,
            percentage_done: done_percentage.nan? ? 0 : done_percentage
        }
    end

    def sl_total_delivery date_from, date_to

        # Set the default values
        less = 0
        between = 0
        great = 0
        total = 0
        usda = 0

        # iterate the counties
        self.counties.active.each do |county|

            # get the flown tiles from the county
            scoped_tiles = county.tiles.flown.where(ship_date: date_from..date_to).where.not(packing_slip_id: nil)

            # Skip to the next record if there are no shipped tiles
            next if scoped_tiles.empty?

            # Get the max fly date
            max_fly_date = scoped_tiles.order(flight_date: :desc).pluck(:flight_date).first

            # Get the total and the usda_accepted tile count
            total += scoped_tiles.shipped.count
            usda += scoped_tiles.usda_accepted.count

            # => iterate the Packing slips
            scoped_tiles.pluck(:packing_slip_id).uniq.compact.map {|p| PackingSlip.find(p)}.each do |ps|
                # Get the issued date
                if (max_fly_date.to_date..(max_fly_date.to_date + 15.days)).include?(ps.shipped_date)
                    less += ps.tiles.flown.where(county: county).count
                elsif (max_fly_date.to_date..(max_fly_date.to_date + 30.days)).include?(ps.shipped_date)
                    between += ps.tiles.flown.where(county: county).count
                elsif ps.shipped_date.to_date > max_fly_date.to_date + 30.days
                    great += ps.tiles.flown.where(county: county).count
                end
            end

        end

        # Return the results
        {
            name: self.name,
            lesser_count: less,
            between_count: between,
            greater_count: great,
            total_count: total,
            usda_count: usda
        }

    end

    def naip_total_delivery date_from, date_to

        # Set the default values
        less = 0
        between = 0
        great = 0
        total = 0
        usda = 0

        # iterate the counties
        self.counties.active.each do |county|

            # get the flown doqqs from the county
            scoped_doqqs = county.doqqs.flown.where(ship_date: date_from..date_to).where.not(packing_slip_id: nil)

            # Skip to the next record if there are no shipped doqqs
            next if scoped_doqqs.empty?

            # Get the max fly date
            max_fly_date = scoped_doqqs.order(flight_date: :desc).pluck(:flight_date).first

            # Get the total and the usda_accepted tile count
            total += scoped_doqqs.shipped.count
            usda += scoped_doqqs.usda_accepted.count

            # => iterate the Packing slips
            scoped_doqqs.pluck(:packing_slip_id).uniq.compact.map {|p| PackingSlip.find(p)}.each do |ps|
                # Get the issued date
                if (max_fly_date.to_date..(max_fly_date.to_date + 15.days)).include?(ps.shipped_date)
                    less += ps.doqqs.flown.where(county: county).count
                elsif (max_fly_date.to_date..(max_fly_date.to_date + 30.days)).include?(ps.shipped_date)
                    between += ps.doqqs.flown.where(county: county).count
                elsif ps.shipped_date.to_date > max_fly_date.to_date + 30.days
                    great += ps.doqqs.flown.where(county: county).count
                end
            end

        end

        # Return the results
        {
            name: self.name,
            lesser_count: less,
            between_count: between,
            greater_count: great,
            total_count: total,
            usda_count: usda
        }

    end

end