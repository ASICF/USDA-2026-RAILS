class CompaniesController < ApplicationController
  include ApplicationHelper
  before_action :manager_check 

  load_and_authorize_resource :company

  def index
    @companies = Company.all.order(:name).page(params[:page]).per(50)
  end

  def show
  end

  def new
    @company = Company.new
    # can_destroy = false
  end

  def edit
    build
  end

  def create
    @company = Company.new(company_params)
    if @company.save

      # Create a new History record
      history = History.new
      history.message = "Company #{@company.name} was successfully created."
      history.action_type = "Company Create"
      history.creator = current_user
      history.save

      # add records to polymorphic association
      history.companies << @company

      render json: {
        message: "Company #{@company.name} was successfully created.", 
        pass: true
      }
    else
      render json: {
        message: @company.errors.full_messages.to_sentence, 
        pass: false
      }
    end
  end

  def update
    if @company.update(company_params)

      # Create a new History record
      history = History.new
      history.message = "Company #{@company.name} was successfully updated."
      history.action_type = "Company Update"
      history.creator = current_user
      history.save

      # add records to polymorphic association
      history.companies << @company

      render json: {
        message: "Company #{@company.name} was successfully updated.", 
        pass: true
      }
    else
      render json: {
        message: @company.errors.full_messages.to_sentence, 
        pass: false
      }
    end
  end

  def destroy
    # Check if the company's planes or camera has any post flight records. 
    # If so then don't destroy
    count = 0

    @company.planes.each { |p| count += p.tiles.count }
    @company.cameras.each { |c| count += c.tiles.count }

    # get the company name
    name = @company.name

    if count == 0
      name = @company.name
      @company.destroy

      # Create a new History record
      history = History.new
      history.message = "Company #{@company.name} was successfully destroyed."
      history.action_type = "Company Destroy"
      history.creator = current_user
      history.save

      # add records to polymorphic association
      history.companies << @company

      render json: {
        message: "Company #{name} was deleted.", 
        pass: true
      }
    else
      render json: {
        message: @company.errors.full_messages.to_sentence, 
        pass: false
      }
    end
  end

  private

  def build
    count = 0
    @company.planes.each { |p| count += p.tiles.count }
    @company.cameras.each { |c| count += c.tiles.count }
    count += @company.tiles.count
    @can_destroy = count == 0
  end

  def company_params
    params.required(:company).permit(:name, :alias, :sl, :naip)
  end

end
