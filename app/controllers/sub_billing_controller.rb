class SubBillingController < ApplicationController
    authorize_resource :companies

    def index
        @result = Company.generate_sub_billing
    end

end
