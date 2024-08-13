class GraphApiController < ApplicationController
    include GraphApiHelper
    def widgets
        render json: {
          ready_to_ship: {
            overdue: Tile.county_flown.not_shipped.where("county_due_date <= ?", Date.today).count,
            due_within_seven_days: Tile.county_flown.not_shipped.where("county_due_date >= ? AND county_due_date <= ?", Date.today, Date.today + 7.days).count,
            due_within_fifteen_days: Tile.county_flown.not_shipped.where("county_due_date >= ? AND county_due_date <= ?", Date.today + 7.days, Date.today + 15.days).count ,
            due_within_thirty_days: Tile.county_flown.not_shipped.where("county_due_date >= ? AND county_due_date <= ?", Date.today + 7.days, Date.today + 30.days).count ,
          }, 
          eo_tracker: {
            uploads_that_need_eos: Upload.includes(:footprints).where(upload_type: "Footprint", footprints: {flight_date_time: nil, associated: true}).count
          },
          easements_with_multiple_coverages: {
            records_with_coverage: Tile.flown.covered.not_ortho_processed.count,
            rejected_with_coverage: Tile.not_flown.covered.count
          }
        }
    end

    def milestones

        project = params[:project]
        if project.nil?
            project = "SL"
        end

        total_tiles = Tile.where(project: project).count.to_f

        render json: {
            status: true,
            label: ["Total Invoiced", "Total Shipped", "Total Dumped", "Total Counties Flown", "Total Flown"],
            datasets: {
                "Total Invoiced":  {
                    data: (Tile.invoiced.where(project: project).count / total_tiles) * 100,
                    background: "rgba(67, 111, 158, .8)"
                },
                "Total Shipped":  {
                    data: (Tile.shipped.where(project: project).count / total_tiles) * 100,
                    background: "rgba(168, 194, 86, .8)"
                },
                "Total Dumped":  {
                    data: (Tile.dumped.where(project: project).count / total_tiles) * 100,
                    background: "rgba(230, 218, 67, .8)"
                },
                "Total Counties Flown":  {
                    data: (Tile.county_flown.where(project: project).count / total_tiles) * 100,
                    background: "rgba(195, 96, 59, .8)"
                },
                "Total Flown":  {
                    data: (Tile.flown.where(project: project).count / total_tiles) * 100,
                    background: "rgba(147, 67, 62, .8)"
                }
            }
        }
    end

    def production_status_data
        render json: build_status_data()
    end

    def history_activity
        # iterates the history for the last month and get counts 
        # Query all history records since 30 days ago
        sql = "SELECT created_at::date as date, COUNT(*) FROM histories as count GROUP BY created_at::date ORDER BY created_at::date ASC"
        result = ActiveRecord::Base.connection.execute(sql)

        # iterate and format the calendar data
        calendar_values = {}
        result.each do |record|
            calendar_values[record["date"]] = record["count"]
        end

        last = History.select(:created_at).order(:created_at).last
        end_time = nil

        if last.present?
        end_time = last.created_at.strftime("%F")
        end

        render json: {
            until: end_time,
            values: calendar_values
        }
    end

    def build_status_data

        if params[:project] == "SL" || params[:project] == "NRI"

            project = params[:project]

            shipped = {}
            tile_dumped = {}
            ortho_processed = {}
            at_started = {}
            at_done = {}
            flown = {}

            return {status: false} if Tile.flown.where(project: project).count == 0

            dates = []

            obj = {}
            flown_obj = {}
            shipped_obj = {}
            at_started_obj = {}
            at_done_obj = {}
            ortho_proc_obj = {}
            dumped_obj = {}
        
            if params[:state_id] != "all"
                obj[:state_id] = params[:state_id]
                obj[:project] = params[:project]
                flown_obj[:state_id] = params[:state_id]
                flown_obj[:project] = project
                shipped_obj[:state_id] = params[:state_id]
                shipped_obj[:project] = params[:project]
                at_started_obj[:state_id] = params[:state_id]
                at_started_obj[:project] = params[:project]
                at_done_obj[:state_id] = params[:state_id]
                at_done_obj[:project] = params[:project]
                ortho_proc_obj[:state_id] = params[:state_id]
                ortho_proc_obj[:project] = params[:project]
                dumped_obj[:state_id] = params[:state_id]
                dumped_obj[:project] = params[:project]
            end
            if params[:month] != "all" && params[:year].present?
                date = "#{params[:year]}-#{params[:month]}-1"

                flown_obj[:flight_date] = Date.strptime(date, "%Y-%m-%d").all_month
                flown_obj[:project] = project
                shipped_obj[:ship_date] = Date.strptime(date, "%Y-%m-%d").all_month
                shipped_obj[:project] = project
                at_started_obj[:at_start_date] = Date.strptime(date, "%Y-%m-%d").all_month
                at_started_obj[:project] = project
                at_done_obj[:at_done_date] = Date.strptime(date, "%Y-%m-%d").all_month
                at_done_obj[:project] = project
                ortho_proc_obj[:ortho_proc_date] = Date.strptime(date, "%Y-%m-%d").all_month
                ortho_proc_obj[:project] = project
                dumped_obj[:dump_date] = Date.strptime(date, "%Y-%m-%d").all_month
                dumped_obj[:project] = project
            end
            
            dates << Tile.flown.where(flown_obj).order(:flight_date).last.flight_date if Tile.flown.where(flown_obj).count > 0
            dates << Tile.shipped.where(shipped_obj).order(:ship_date).last.ship_date if Tile.shipped.where(shipped_obj).count > 0
            dates << Tile.at_started.where(at_started_obj).order(:at_start_date).last.at_start_date if Tile.at_started.where(at_started_obj).count > 0
            dates << Tile.at_done.where(at_done_obj).order(:at_done_date).last.at_done_date if Tile.at_done.where(at_done_obj).count > 0
            dates << Tile.ortho_processed.where(ortho_proc_obj).order(:ortho_proc_date).last.ortho_proc_date if Tile.ortho_processing.where(ortho_proc_obj).count > 0
            dates << Tile.dumped.where(dumped_obj).order(:dump_date).last.dump_date if Tile.dumped.where(dumped_obj).count > 0

            dates = dates.sort

            return {status: false, message: "No Tile Statuses found based on Request"} if dates.size == 0 

            # Get the beginning and end of the project
            # => End is the oldest record in the dates array
            if flown_obj[:flight_date]
                project_start_date = flown_obj[:flight_date].first
                project_end_date = flown_obj[:flight_date].last
            else
                project_start_date = Tile.flown.where(project: project).order(:flight_date).first.flight_date.beginning_of_month
                project_end_date = dates.last.end_of_month
            end
            
            project_range = project_start_date..project_end_date

            # Build the first month jic
            shipped, tile_dumped, ortho_processed, at_started, at_done, flown = build_year_and_month(project_start_date.year, project_start_date.month, shipped, tile_dumped, ortho_processed, at_started, at_done, flown)

            # Iterate all the Tiles and build the summaries
            Tile.where(obj).order(:created_at).each do |tile|

                if project_range.cover? tile.flight_date
                    year = tile.flight_date.year
                    month = tile.flight_date.month
                    shipped, tile_dumped, ortho_processed, at_started, at_done, flown = build_year_and_month(year, month, shipped, tile_dumped, ortho_processed, at_started, at_done, flown)
                    flown[year][month] += 1
                end

                if project_range.cover? tile.at_start_date
                    year = tile.at_start_date.year
                    month = tile.at_start_date.month
                    shipped, tile_dumped, ortho_processed, at_started, at_done, flown = build_year_and_month(year, month, shipped, tile_dumped, ortho_processed, at_started, at_done, flown)
                    at_started[year][month] += 1
                end

                if project_range.cover? tile.at_done_date
                    year = tile.at_done_date.year
                    month = tile.at_done_date.month
                    shipped, tile_dumped, ortho_processed, at_started, at_done, flown = build_year_and_month(year, month, shipped, tile_dumped, ortho_processed, at_started, at_done, flown)
                    at_done[year][month] += 1
                end

                if project_range.cover? tile.ortho_proc_date
                    year = tile.ortho_proc_date.year
                    month = tile.ortho_proc_date.month
                    shipped, tile_dumped, ortho_processed, at_started, at_done, flown = build_year_and_month(year, month, shipped, tile_dumped, ortho_processed, at_started, at_done, flown)
                    ortho_processed[year][month] += 1
                end

                if project_range.cover? tile.dump_date
                    year = tile.dump_date.year
                    month = tile.dump_date.month
                    shipped, tile_dumped, ortho_processed, at_started, at_done, flown = build_year_and_month(year, month, shipped, tile_dumped, ortho_processed, at_started, at_done, flown)
                    tile_dumped[year][month] += 1
                end

                if project_range.cover? tile.ship_date
                    year = tile.ship_date.year
                    month = tile.ship_date.month
                    shipped, tile_dumped, ortho_processed, at_started, at_done, flown = build_year_and_month(year, month, shipped, tile_dumped, ortho_processed, at_started, at_done, flown)
                    shipped[year][month] += 1
                end

            end

            return {
                status: true,
                label: get_months_between_dates_as_label(project_start_date, project_end_date),
                datasets: {
                    "Flown":  {
                    data: sort_by_month_and_year(flown),
                    background: 'rgba(195, 96, 59, .8)'
                    },
                    "AT Started":  {
                    data: sort_by_month_and_year(at_started),
                    background: 'rgba(147, 67, 62, .8)'
                    },
                    "AT Done":  {
                    data: sort_by_month_and_year(at_done),
                    background: 'rgba(168, 194, 86, .8)'
                    },
                    "Ortho Processing":  {
                    data: sort_by_month_and_year(ortho_processed),
                    background: 'rgba(100, 84, 153, .8)'
                    },
                    "Tile Dumped":  {
                    data: sort_by_month_and_year(tile_dumped),
                    background: 'rgba(67, 111, 158, .8)'
                    },
                    "Shipped":  {
                    data: sort_by_month_and_year(shipped),
                    background: 'rgba(230, 218, 67, .8)'
                    }
                }
            }

        elsif params[:project] == "NAIP"

            shipped = {}
            tile_dumped = {}
            # ortho_processed = {}
            at_started = {}
            at_done = {}
            flown = {}

            if Doqq.flown.count == 0
            return {status: false}
            end

            dates = []

            dates << Doqq.flown.order(:flight_date).last.flight_date if Doqq.flown.count > 0
            dates << Doqq.shipped.order(:ship_date).last.ship_date if Doqq.shipped.count > 0
            dates << Doqq.at_started.order(:at_start_date).last.at_start_date if Doqq.at_started.count > 0
            dates << Doqq.at_done.order(:at_done_date).last.at_done_date if Doqq.at_done.count > 0
            # dates << Doqq.ortho_processed.order(:ortho_proc_date).last.ortho_proc_date if Doqq.ortho_processing.count > 0
            dates << Doqq.dumped.order(:dump_date).last.dump_date if Doqq.dumped.count > 0

            dates = dates.sort

            # Get the beginning and end of the project
            # => End is the oldest record in the dates array
            project_start_date = Doqq.flown.order(:flight_date).first.flight_date.beginning_of_month
            project_end_date = dates.last.end_of_month
            project_range = project_start_date..project_end_date

            # Build the first month jic
            shipped, tile_dumped, ortho_processed, at_started, at_done, flown = build_year_and_month(project_start_date.year, project_start_date.month, shipped, tile_dumped, ortho_processed, at_started, at_done, flown)

            # Iterate all the Tiles and build the summaries
            Doqq.all.order(:created_at).each do |tile|

            if project_range.cover? tile.flight_date
                year = tile.flight_date.year
                month = tile.flight_date.month
                shipped, tile_dumped, ortho_processed, at_started, at_done, flown = build_year_and_month(year, month, shipped, tile_dumped, ortho_processed, at_started, at_done, flown)
                flown[year][month] += 1
            end

            if project_range.cover? tile.at_start_date
                year = tile.at_start_date.year
                month = tile.at_start_date.month
                shipped, tile_dumped, ortho_processed, at_started, at_done, flown = build_year_and_month(year, month, shipped, tile_dumped, ortho_processed, at_started, at_done, flown)
                at_started[year][month] += 1
            end

            if project_range.cover? tile.at_done_date
                year = tile.at_done_date.year
                month = tile.at_done_date.month
                shipped, tile_dumped, ortho_processed, at_started, at_done, flown = build_year_and_month(year, month, shipped, tile_dumped, ortho_processed, at_started, at_done, flown)
                at_done[year][month] += 1
            end

            # if project_range.cover? tile.ortho_proc_date
            #   year = tile.ortho_proc_date.year
            #   month = tile.ortho_proc_date.month
            #   shipped, tile_dumped, ortho_processed, at_started, at_done, flown = build_year_and_month(year, month, shipped, tile_dumped, ortho_processed, at_started, at_done, flown)
            #   ortho_processed[year][month] += 1
            # end

            if project_range.cover? tile.dump_date
                year = tile.dump_date.year
                month = tile.dump_date.month
                shipped, tile_dumped, ortho_processed, at_started, at_done, flown = build_year_and_month(year, month, shipped, tile_dumped, ortho_processed, at_started, at_done, flown)
                tile_dumped[year][month] += 1
            end

            if project_range.cover? tile.ship_date
                year = tile.ship_date.year
                month = tile.ship_date.month
                shipped, tile_dumped, ortho_processed, at_started, at_done, flown = build_year_and_month(year, month, shipped, tile_dumped, ortho_processed, at_started, at_done, flown)
                shipped[year][month] += 1
            end

            end

            return {
                status: true,
                label: get_months_between_dates(project_start_date, project_end_date),
                datasets: {
                    "Flown":  {
                        data: sort_by_month_and_year(flown),
                        background: 'rgba(195, 96, 59, .8)'
                    },
                    "AT Started":  {
                        data: sort_by_month_and_year(at_started),
                        background: 'rgba(147, 67, 62, .8)'
                    },
                    "AT Done":  {
                        data: sort_by_month_and_year(at_done),
                        background: 'rgba(168, 194, 86, .8)'
                    },
                    "Tile Dumped":  {
                        data: sort_by_month_and_year(tile_dumped),
                        background: 'rgba(67, 111, 158, .8)'
                    },
                    "Shipped":  {
                        data: sort_by_month_and_year(shipped),
                        background: 'rgba(230, 218, 67, .8)'
                    }
                }
            }

        end

    end

    # Had to build this makeshift approach to getting the proper values for each month
    # => Some statues might not have a value fo the month so it must show a 0 in those cases
    def build_year_and_month(year, month, shipped, tile_dumped, ortho_processed, at_started, at_done, flown)
        shipped[year].nil? ? shipped[year] = {} : nil
        tile_dumped[year].nil? ? tile_dumped[year] = {} : nil
        ortho_processed && ortho_processed[year].nil? ? ortho_processed[year] = {} : nil
        at_started[year].nil? ? at_started[year] = {} : nil
        at_done[year].nil? ? at_done[year] = {} : nil
        flown[year].nil? ? flown[year] = {} : nil

        shipped[year][month].nil? ? shipped[year][month] = 0 : nil
        tile_dumped[year][month].nil? ? tile_dumped[year][month] = 0 : nil
        ortho_processed && ortho_processed[year][month].nil? ? ortho_processed[year][month] = 0 : nil
        at_started[year][month].nil? ? at_started[year][month] = 0 : nil
        at_done[year][month].nil? ? at_done[year][month] = 0 : nil
        flown[year][month].nil? ? flown[year][month] = 0 : nil

        return shipped, tile_dumped, ortho_processed, at_started, at_done, flown
        end

        # Iterate over keys and build an array in order
        # => If multiple years then append the newer year to the array last by month order
        def sort_by_month_and_year obj
        result = []
        obj.sort.to_h.each do |key, array|
            array.sort.to_h.each do |month, total|
            result << total
            end
        end
        result
    end

end
