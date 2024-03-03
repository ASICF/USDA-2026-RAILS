class ContractRate < ApplicationRecord

    # Associations
    belongs_to :state
    belongs_to :company
    has_many :tiles
    has_many :rejected_tiles

    # Scopes
    scope :sl,  -> { where(project: "SL") }
    scope :nri, -> { where(project: "NRI") }
    scope :naip, -> { where(project: "NAIP") }
    scope :flight,      -> { where(phase: "100") }
    scope :production,  -> { where(phase: "300") }

    # validations
    validates :project, :project_no, :company_alias, :phase, :cost, :start_date, :end_date, :state_id, presence: true
    validates_numericality_of :cost, greater_than: 0, if: -> {company_id == 1}
    validates_numericality_of :cost, greater_than_or_equal_to: 0, if: -> {company_id != 1}
    validate :date_range

    # Validate the start date is before the end date
    def date_range
        return if [start_date.blank?, end_date.blank?].any?
        if end_date <= start_date
          errors.add(:start_date, 'Start Date must be before End Date')
        end
    end

    # Methods
    def self.find_rates flight_date, company, state, project
        return {
            production: self.find_production_rates(flight_date, company, state, project),
            flight: self.find_flight_rates(flight_date, company, state, project)
        }
    end

    def self.find_flight_rates flight_date, company, state, project

        return self.where(
            'start_date <= ? AND end_date >= ?', flight_date, flight_date
        ).find_by(
            phase: "100",
            project: project,
            company: company,
            state: state
        )

    end

    def self.find_production_rates flight_date, company, state, project

        return self.where(
            'start_date <= ? AND end_date >= ?', flight_date, flight_date
        ).find_by(
            phase: "300",
            project: project,
            company: company,
            state: state
        )

    end
end
