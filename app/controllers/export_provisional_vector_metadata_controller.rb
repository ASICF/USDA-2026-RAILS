class ExportProvisionalVectorMetadataController < ApplicationController

    def index
        redirect_to root_path if !Rails.application.secrets.active_projects.include? "NAIP"
        if @current_user.admin? || @current_user.manager?
            @all_states = State.active.exclude_geom.order(:name).map { |state| {id: state.id, name: state.name}}
            @sl_states = State.active_sl.exclude_geom.order(:name).map { |state| {id: state.id, name: state.name}}
            @naip_states = State.active_naip.exclude_geom.order(:name).map { |state| {id: state.id, name: state.name}}
            @projects = ["ALL"] + Rails.application.secrets.active_projects
            @services = ["Provisional", "Production"]
            @active = VectorMetadatum.naip.provisional_active.order(:provisional_due_date).map do |vm|
                {
                    id: vm.id,
                    project: vm.project,
                    service_name: vm.service_name,
                    state_name: vm.state_name,
                    flight_date: vm.flight_date,
                    provisional_date: vm.provisional_date,
                    provisional_due_date: vm.provisional_due_date,
                    production_date: vm.production_date,
                    production_due_date: vm.production_due_date,
                    count: vm.count,
                    not_uploaded_count: vm.footprints.where(provisional_upload_date: nil).count,
                    imagery_paths: vm.imagery_paths,
                    shapefile_path: vm.shapefile_path
                }
            end
        else
            redirect_to root_path
        end
    end

    def provisional_query
        p params

        if params["project"].blank?
            render json: {
                pass: false,
                message: "No Project Paramter Found"
            }
        elsif params["status"].blank?
            render json: {
                pass: false,
                message: "No Status Paramter Found"
            }
        elsif params["state_id"].blank?
            render json: {
                pass: false,
                message: "No State Paramter Found"
            }
        else

            query = {}

            # Set the Status
            if params[:project] != "All"
                query[:project] = params[:project]
            end

            # Set the Status
            # if params[:status] != "All"
            #     query[:completed] = params[:status] == "Completed" ? true : false
            # end

            # Set the flight date
            if params[:flight_date].present?
                p "Flight Date #{params[:flight_date]}"
                query[:flight_date] = params[:flight_date]
            end

            # Set the State
            if params[:state_id] != "All"
                query[:state_id] = params[:state_id]
            end

            if params[:status] == "Active"
                records = VectorMetadatum.provisional_active.where(query).order(:provisional_due_date)
                # query[:provisional_date: nil] = nil
            elsif params[:status] == "Completed"
                records = VectorMetadatum.provisional_finished.where(query).order(:provisional_due_date)
                # not_query = "provisional_date is not null"
            else
                records = VectorMetadatum.where(query).order(:provisional_due_date)
            end

            p query

            result = []

            records.each do |vm|
                result << {
                    id: vm.id,
                    project: vm.project,
                    service_name: vm.service_name,
                    state_name: vm.state_name,
                    flight_date: vm.flight_date,
                    provisional_date: vm.provisional_date,
                    provisional_due_date: vm.provisional_due_date,
                    production_date: vm.production_date,
                    production_due_date: vm.production_due_date,
                    count: vm.count,
                    not_uploaded_count: vm.footprints.where(provisional_upload_date: nil).count,
                    imagery_paths: vm.imagery_paths,
                    shapefile_path: vm.shapefile_path
                }
            end

            render json: {
                pass: true,
                result: result
            }

        end

    end

    def provisional_imagery_paths
        p params

        if params[:id].blank?
            render json: {
                pass: false,
                message: "No ID found"
            }
        else

            vm = VectorMetadatum.find(params[:id])

            footprints = []
            vm.footprints.each do |fp|
                obj = {
                    id: fp.id,
                    strip_frame: fp.strip_frame,
                    time: fp.flight_date_time,
                    path: nil,
                    created_at: nil,
                    user: nil,
                }

                imagery_paths = fp.imagery_paths.where(project: vm.project)
                if imagery_paths.count > 0
                    path = imagery_paths.first

                    obj[:path] = path.path
                    obj[:created_at] = path.created_at
                    obj[:user] = path.user.full_name
                end

                footprints << obj
            end

            imagery = []
            vm.imagery_paths.each do |path|
                imagery << {
                    id: path.id,
                    path: path.path,
                    created_at: path.created_at,
                    user: path.user.full_name
                }
            end
            
            render json: {
                pass: true,
                result: {
                    footprints: footprints,
                    imagery_paths: imagery
                }
            }

        end

    end

    def provisional_execute
        if params[:id].blank?
            render json: {
                pass: false,
                message: "No Input Direcotry Forund"
            }
        elsif params[:input_directory].blank?
            render json: {
                pass: false,
                message: "No Input Direcotry Forund"
            }
        elsif params[:upload_date].blank?
            render json: {
                pass: false,
                message: "No Input Direcotry Forund"
            }
        else

            vm = VectorMetadatum.find(params[:id])

            # Check if the path exists
            if VectorMetadatum.check_if_path_exists params[:input_directory]

                response = vm.provisional_export params[:input_directory], params[:upload_date], current_user

                p "---------------"
                p response
                p "---------------"
    
                render json: {
                    state: response[:pass],
                    message: response[:message],
                    export: response[:export],
                    record: VectorMetadatum.find(params[:id])
                }

            else

                render json: {
                    pass: false,
                    message: "No Input Directory Found"
                }
            end

        end
    end

    def provisional_download

        if params[:id].blank?
            render json: {
                pass: false,
                message: "No ID Found"
            }
        end

        vm = VectorMetadatum.find(params[:id])

        if vm && vm.shapefile_path
            if File.exist? vm.shapefile_path
                send_file(
                    vm.shapefile_path,
                    filename: File.basename(vm.shapefile_path),
                    type: "application/zip"
                )
            else
                render json: {
                    pass: false,
                    message: "No file Found"
                }
            end
        end

    end

end