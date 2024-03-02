class VectorMetadataController < ApplicationController
  def index
    if @current_user.admin? || @current_user.manager?
        @all_states = State.active.exclude_geom.order(:name).map { |state| {id: state.id, name: state.name}}
        @sl_states = State.active_sl.exclude_geom.order(:name).map { |state| {id: state.id, name: state.name}}
        @naip_states = State.active_naip.exclude_geom.order(:name).map { |state| {id: state.id, name: state.name}}
        @projects = Rails.application.secrets.active_projects
    else
        redirect_to root_path
    end
  end

#   def query
#     p params

#     if params["project"].blank?
#         render json: {
#             pass: false,
#             message: "No Project Paramter Found"
#         }
#     elsif params["flight_date"].blank?
#         render json: {
#             pass: false,
#             message: "No Flight Date Paramter Found"
#         }
#     elsif params["state_id"].blank?
#         render json: {
#             pass: false,
#             message: "No State Paramter Found"
#         }
#     else

        

#         render json

#     end

#   end

  def export
  end
end
