class MailgroupsController < ApplicationController
  def index
    @mail_groups = MailGroup.all 
    @active_mail_groups = current_user.mail_groups.pluck(:id)
  end

  def update
    # Check if the mail group ids param exists and that it's an array
    if !params.has_key?(:mail_groups_ids) || !params[:mail_groups_ids].kind_of?(Array)
      render json: {
        state: false,
        message: "No Mail Group IDs were included with request"
      }
    else

      # remove the current user from all mail groups
      current_user.mail_groups = []

      # Create new MailGroupUsers
      params[:mail_groups_ids].each do |id|

        # create the Mail Group user
        MailGroupUser.create(
          user: current_user,
          mail_group_id: id
        )
      end

      render json: {
        state: true,
        message: "Updated User's Mail Groups"
      }

    end

  end
end
