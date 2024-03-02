class CamerasController < ApplicationController
  include ApplicationHelper
  before_action :manager_check 

  load_and_authorize_resource :camera

  def index
    @cameras = Camera.all.order(:name).page(params[:page]).per(50)
  end

  def show
    @camera = Camera.find(params[:id])
  end

  def new
    @camera = Camera.new
    build
  end

  def edit
    build
  end

  def create
    @camera = Camera.new(camera_params)
    if @camera.save

      # Create a new History record
      history = History.new
      history.message = "Camera #{@camera.name} was successfully created."
      history.action_type = "Create Camera"
      history.creator = current_user
      history.save

      # add records to polymorphic association
      history.cameras << @camera

      render json: {
        message: "Camera #{@camera.name} was successfully created.", 
        pass: true
      }
    else
      render json: {
        message: @camera.errors.full_messages.to_sentence, 
        pass: false
      }
    end
  end

  def update
    if @camera.update(camera_params)
      

      # Create a new History record
      history = History.new
      history.message = "Camera #{@camera.name} was successfully updated."
      history.action_type = "Camera Update"
      history.creator = current_user
      history.save

      # add records to polymorphic association
      history.cameras << @camera
      
      render json: {
        message: "Camera #{@camera.name} was successfully updated.", 
        pass: true
      }
    else
      render json: {
        message: @camera.errors.full_messages.to_sentence, 
        pass: false
      }
    end
  end

  def destroy
    # Check if the cameras has any post flight records. 

    # get the company name
    name = @camera.name

    count = @camera.tiles.count

    if count == 0
      name = @camera.name
      @camera.destroy

      # Create a new History record
      history = History.new
      history.message = "Camera #{@camera.name} was successfully destroyed."
      history.action_type = "Camera Destroy"
      history.creator = current_user
      history.save

      # add records to polymorphic association
      history.cameras << @camera

      render json: {
        message: "Camera #{name} was deleted.", 
        pass: true
      }
    else
      render json: {
        message: @camera.errors.full_messages.to_sentence, 
        pass: false
      }
    end
  end

  private

  def build
    @total_flown = @camera.footprints.count
    @companies = Company.select(:id, :name, :alias).order(:name)
  end

  def camera_params
    params.required(:camera).permit(:name, :manufacturer, :model, :serial_number, :company_id, :sl, :naip)
  end

end
