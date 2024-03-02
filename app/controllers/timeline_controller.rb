class TimelineController < ApplicationController
    authorize_resource :history

    def index
        # query the timelines based on the table or by default

        obj = {}

        if !params[:action_type].blank? && params[:action_type] != "All"
            obj[:action_type] = params[:action_type]
        end

        if !params[:user].blank? && params[:user] != "All"
            obj[:creator_id] = params[:user]
        end

        if !params[:date_from].blank?
            if params[:date_to].blank?
                obj[:created_at] = params[:date_from]..Time.now + 2.hours
            else
                obj[:created_at] = params[:date_from]..params[:date_to]
            end
        elsif !params[:date_to].blank?
            obj[:created_at] = Time.parse(params[:date_to] - 1.year)..params[:date_to]
        end

        # If the term parameter is blank then ignore the PG Search
        if params[:term].blank? && obj.blank?
            @timeline = History.all.order(created_at: :desc).page(params[:page]).per(50);
        elsif params[:term].blank?
            @timeline = History.where(obj).order(created_at: :desc).page(params[:page]).per(50);
        else
            @timeline = History.search(params[:term]).where(obj).order(created_at: :desc).page(params[:page]).per(50);
        end

        respond_to do |format|
            format.html {
                # Get all unique Users from the history table
                @users = User.where(id: History.all.order(:action_type).pluck(:creator_id).uniq).order(:first_name)

                # Get all unique Action Types from the history table
                @action_types = History.all.order(:action_type).pluck(:action_type).uniq
            }
            format.json {
                render json: @timeline
            }
        end

        # Get all unique Action Types from the history table
        @action_types = History.all.order(:action_type).pluck(:action_type).uniq
        # Get all unique Users from the history table
        @users = User.where(id: History.all.order(:action_type).pluck(:creator_id).uniq).order(:first_name)
    end

    def show
        history = History.includes(
            :cameras, :companies, :easements, :footprints, :frame_centers, :packing_slips, :planes, 
            :rejected_tiles, :rejected_footprints, :rejected_frame_centers, :tiles, :doqqs, 
            :users, :uploads, :web_log_uploads, :photo_indices
        ).find_by(id: params[:timeline_id])

        if history.present?

            @record = {}

            # Associate the Upload
            # @record["upload"] = history.uploads.first if history.uploads.count > 0

            # Build the default meta
            @record["meta"] = {
                id: history.id,
                message: history.message,
                action_type: history.action_type,
                user: User.select(:id, :first_name, :last_name).find_by(id: history.creator_id),
                url: history.url,
                created_at: history.created_at,
                upload_id: history.uploads.count > 0 ? history.uploads.first.id : nil
            }

            # Footprint Meta
            if history.action_type.include?("Upload Footprints")
                first = history.footprints.first

                @record["meta"] = @record["meta"].merge({
                    flight_date: first.flight_date,
                    associated_count: history.footprints.count, 
                    project: first.project,
                    flown_by_name: first.flown_by_name,
                    camera_name: first.camera_name,
                    plane_name: first.plane_name,
                    pilot_name: first.pilot_name,
                    sensor_operator: first.camera_operator_name
                })
            end

            # Frame Center Meta
            if history.action_type.include?("Frame Center Upload")
                first = history.frame_centers.first

                @record["meta"] = @record["meta"].merge({
                    flight_date: first.flight_date,
                    associated_count: history.frame_centers.count, 
                    project: first.project,
                    flown_by_name: first.flown_by_name,
                    camera_name: first.camera_name,
                    plane_name: first.plane_name,
                })
            end

            # Associations
            @record["users"] = history.users.select(:id, :first_name, :last_name) if history.users.count > 0
            @record["web_log_uploads"] = history.web_log_uploads.select(:id, :start_date, :end_date, :count) if history.users.count > 0

            @record["companies"] = history.companies.select(:id, :name, :alias) if history.companies.count > 0

            if history.cameras.count > 0
                camera_array = []
                history.cameras.each do |camera|
                    camera_array << {
                        name: camera.name,
                        manufacturer: camera.manufacturer,
                        model: camera.model,
                        company_name: camera.company.name
                    }
                end
                @record["cameras"] = camera_array
            end


            if history.planes.count > 0
                planes_array = []
                history.planes.each do |planes|
                    planes_array << {
                        name: planes.name,
                        manufacturer: planes.manufacturer,
                        model: planes.model,
                        company_name: planes.company.name
                    }
                end
                @record["planes"] = planes_array
            end

            @record["easements"] = history.easements.select(:id, :project, :project_no, :poly_id, :flight_date, :acres, :county_name, :state_name, :utm_zone, :latitude, :longitude) if history.easements.count > 0
            @record["tiles"] = history.tiles.select(:id, :project, :project_no, :poly_id, :flight_date, :filename, :county_name, :state_name, :utm_zone, :created_at) if history.tiles.count > 0
            @record["doqqs"] = history.doqqs.select(:id, :project_no, :qq_apfo_name, :filename, :flight_date, :acres, :county_name, :state_name, :utm_zone) if history.doqqs.count > 0
            @record["footprints"] = history.footprints.select(:id, :project, :strip_frame, :original_strip_frame, :associated, :centroid_latitude, :centroid_longitude, :county_name, :state_name, :utm_zone) if history.footprints.count > 0
            @record["frame_centers"] = history.frame_centers.select(:id, :project, :strip_frame, :latitude, :longitude, :sun_angle, :sun_angle_error, :county_name, :state_name, :utm_zone, :footprint_id) if history.frame_centers.count > 0
            @record["photo_indices"] = history.photo_indices.select(:id, :project, :strip_frame, :latitude, :longitude, :sun_angle, :sun_angle_error, :county_name, :state_name, :utm_zone, :footprint_id) if history.photo_indices.count > 0
            @record["packing_slips"] = history.packing_slips.select(:id, :project, :approved_date, :shipped_date, :company, :created_at) if history.packing_slips.count > 0
            @record["rejected_tiles"] = history.rejected_tiles.select(:id, :project, :project_no, :rejected_date, :rejection_type, :rejection_report_date, :poly_id, :flight_date, :filename, :county_name, :state_name, :utm_zone) if history.rejected_tiles.count > 0
            @record["rejected_footprints"] = history.rejected_footprints.select(:id, :project, :strip_frame, :original_strip_frame, :associated, :rejected_date, :rejection_type, :centroid_latitude, :centroid_longitude, :county_name, :state_name, :utm_zone) if history.rejected_footprints.count > 0
            @record["rejected_frame_centers"] = history.rejected_frame_centers.select(:id, :project, :rejected_date, :rejection_type, :strip_frame, :latitude, :longitude, :sun_angle, :sun_angle_error, :county_name, :state_name, :utm_zone, :footprint_id) if history.rejected_frame_centers.count > 0
        else
            @record = nil
        end

    end

    # def show
    #     @history = History.find(params[:timeline_id])

    #     # if @timeline.action_type == "Upload ADS"
    #     #     @type = "updated_ads"
    #     # elsif @timeline.action_type == "Frame Center Upload"
    #     #     @type = "frame_center_upload"
    #     # else
    #     #     @type = "default"
    #     # end
    # end

    def download

        if params[:model_type].blank? || params[:id].blank?
            flash[:error] = "Unable to process download request"
            redirect_to timeline_path
        end

        if model_type === "Upload"

            upload = Upload.find_by(id: params[:id])
            if !upload.nil? && !upload.folder_path.nil?

                response = upload.retrieve_files

                if response[:pass]
                    send_file(
                        response[:file],
                        filename: response[:file_name],
                        type: "application/zip"
                    )
                else
                    flash[:error] = response[:errors]
                    redirect_to easements_to_fly_path
                end

            end

        end

    end

    def excel_export

        # queues the export with a job tracker
        if ["Admin", "Manager", "Reviewer"].include? current_user.role
            History.delay.build_export current_user, params[:type]
        end

        redirect_to root_url
    end

    def history_download
        p params

        if ["Admin", "Manager", "Reviewer"].include? current_user.role

            history = History.find(params[:history_id])

            p history.url

            if history.present?
                send_file history.url
            end
        end
    end

end
