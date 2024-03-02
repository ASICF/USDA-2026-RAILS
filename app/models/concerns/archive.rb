module Concerns::Archive
    extend ActiveSupport::Concern

    included do
        after_initialize :readonly!, if: :check_if_project_archived?

        def check_if_project_archived?
            return Rails.application.secrets.project_archived
        end
    end

end