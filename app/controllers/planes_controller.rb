class PlanesController < ApplicationController
  include ApplicationHelper
  before_action :manager_check 

  load_and_authorize_resource :plane

  def index
    @planes = Plane.all.order(:name).page(params[:page]).per(50)
  end

  def show
    @plane = Plane.find(params[:id])
  end

  def new
    @plane = Plane.new
    build
  end

  def edit
    build
  end

  def create
    @plane = Plane.new(plane_params)
    if @plane.save

      # Create a new History record
      history = History.new
      history.message = "Plane #{@plane.name} was successfully created."
      history.action_type = "Plane Create"
      history.creator = current_user
      history.save

      # add records to polymorphic association
      history.planes << @plane

      render json: {
        message: "Plane #{@plane.name} was successfully created.", 
        pass: true
      }
    else
      render json: {
        message: @plane.errors.full_messages.to_sentence, 
        pass: false
      }
    end
  end

  def update
    if @plane.update(plane_params)
  
      # Create a new History record
      history = History.new
      history.message = "Plane #{@plane.name} was successfully updated."
      history.action_type = "Plane Update"
      history.creator = current_user
      history.save

      # add records to polymorphic association
      history.planes << @plane

      render json: {
        message: "Plane #{@plane.name} was successfully updated.", 
        pass: true
      }
    else
      render json: {
        message: @plane.errors.full_messages.to_sentence, 
        pass: false
      }
    end
  end

  def destroy
    # Check if the planes has any post flight records. 

    # get the company name
    name = @plane.name

    count = @plane.tiles.count

    if count == 0
      name = @plane.name
      @plane.destroy
  
      # Create a new History record
      history = History.new
      history.message = "Plane #{@plane.name} was successfully updated."
      history.action_type = "Plane Destroy"
      history.creator = current_user
      history.save

      # add records to polymorphic association
      history.planes << @plane

      render json: {
        message: "Plane #{@plane.name} was successfully destroyed.", 
        pass: true
      }
    else
      render json: {
        message: @plane.errors.full_messages.to_sentence, 
        pass: false
      }
    end
  end

  private

  def build
    @total_flown = @plane.footprints.count
    @companies = Company.select(:id, :name, :alias).order(:name)
  end

  def plane_params
    params.required(:plane).permit(:name, :model, :company_id, :sl, :naip)
  end

end
