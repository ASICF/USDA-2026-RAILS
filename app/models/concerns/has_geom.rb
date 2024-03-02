module Concerns::HasGeom
    extend ActiveSupport::Concern

    included do

        # Converts decimal degrees with N,E,S,W
        def self.convert_to_dd value
            direction = value[0].upcase
            if direction == "N"
                value[0] = ""
            elsif direction == "E"
                value[0] = ""
            elsif direction == "S"
                value[0] = "-"
            elsif direction == "W"
                value[0] = "-"
            end
            value
        end

    end

end