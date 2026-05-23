class LoadoutsController < ApplicationController
  include ApplicationHelper
  before_action :manager_check 

  load_and_authorize_resource :loadout

  def index
    @loadouts = Loadout.includes(:camera, :plane).order(:name)
  end

  def new
    @loadout = Loadout.new
    build
  end

  def create
    @loadout = Loadout.new(loadout_params)
  
    if @loadout.save
      render json: { pass: true, message: "Loadout created successfully!", data: @loadout }
    else
      render json: {
        message: @loadout.errors.full_messages.to_sentence, 
        pass: false
      }
    end
  end

  def edit
    @loadout = Loadout.find(params[:id])
    build
  end

  def update
    @loadout = Loadout.find(params[:id])
  
    if @loadout.update(loadout_params)
      render json: { pass: true, message: "Loadout updated successfully!", data: @loadout }
    else
      render json: {
        message: @loadout.errors.full_messages.to_sentence, 
        pass: false
      }
    end
  end

  def destroy
    @loadout = Loadout.find(params[:id])
  
    if @loadout.destroy
      render json: { 
        pass: true, 
        message: "Loadout deleted successfully!", 
        data: @loadout 
      }
    else
      render json: {
        pass: false,
        message: @loadout.errors.full_messages.to_sentence
      }
    end
  end

  private

  def build
    @companies = Company.select(:id, :name, :alias).order(:name)
    @cameras = Camera.includes(:company).order(:name)
    @planes  = Plane.includes(:company).order(:name)
  end

  def loadout_params
    params.require(:loadout).permit(:name, :plane_id, :camera_id) 
  end
end
