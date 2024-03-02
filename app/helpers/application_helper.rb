module ApplicationHelper

    def admin_check
        redirect_to root_path if !current_user.admin?
    end

    def manager_check
        if ["Manager", "Admin"].exclude? current_user.role
            redirect_to root_path 
        end
    end
end
