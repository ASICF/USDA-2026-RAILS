module WipByStateHelper

    def calc_wip_by_state_months

        @months = []

        # if there is a from and to date then proceed
        if Tile.flown.count > 0

            # get the months of the first flight date and the last ship date
            from_month = Tile.flown.order(:flight_date).first.flight_date.beginning_of_month

            # in case nothing has shipped yet then get the last flight month
            if Tile.flown.shipped.count > 0
                to_month = Tile.flown.shipped.order(:ship_date).last.ship_date.end_of_month
            elsif Tile.flown.dumped.count > 0
                to_month = Tile.flown.dumped.order(:dump_date).last.dump_date.end_of_month
            elsif Tile.flown.at_done.count > 0
                to_month = Tile.flown.at_done.order(:at_done_date).last.at_done_date.end_of_month
            else
                to_month = Tile.flown.order(:flight_date).first.flight_date.end_of_month
            end


            @months = []

            # If both the from_month and to_month
            if from_month && to_month

                # Count the number of months between first ship date and last flight date
                num_months = (to_month.year * 12 + to_month.month) - (from_month.year * 12 + from_month.month) + 1

                months = []
                num_months.times do |index|
                    date_value = from_month + index.months

                    months << {date: date_value, name: date_value.strftime("%B %Y") }
                end

                @months = months

            end

        end

    end
    
end
