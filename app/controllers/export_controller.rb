class ExportController < ApplicationController

    def download_upload_original
        # Find the Upload
        # Check if there is an "original" folder inside the Path
        # If so then zip it up and download it to the user

        upload = Upload.find(params[:upload_id])

        if upload
            response = upload.zip_original
            if response[:pass]
                send_file(
                    response[:file],
                    filename: response[:file_name],
                    type: "application/zip"
                )
            end
        end
    end

end
