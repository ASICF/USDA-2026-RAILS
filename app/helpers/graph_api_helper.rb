module GraphApiHelper

    def get_months_between_dates_as_label start_date, end_date
        results = []
        (start_date.year..end_date.year).each do |y|
            mo_start = (start_date.year == y) ? start_date.month : 1
            mo_end = (end_date.year == y) ? end_date.month : 12
            (mo_start..mo_end).each do |m|  
                results << "#{Date::MONTHNAMES[m]} '#{y % 100}"
            end
        end
        results
    end

    def get_months_between_dates start_date, end_date
        results = []
        (start_date.year..end_date.year).each do |y|
            mo_start = (start_date.year == y) ? start_date.month : 1
            mo_end = (end_date.year == y) ? end_date.month : 12
            (mo_start..mo_end).each do |m|  
                results << {month: m, year: y, label: "#{Date::MONTHNAMES[m]} #{y}"}
            end
        end
        results
    end

end
