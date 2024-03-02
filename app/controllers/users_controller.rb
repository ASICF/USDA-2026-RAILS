class UsersController < ApplicationController
    include ApplicationHelper
    before_action :admin_check 
    
    load_and_authorize_resource :user

    def index
        @users = User.all.order(:last_name).page(params[:page]).per(50)
    end

    def show
        @user = User.find(params[:id])
    end

    def new
    end

    def create
        p new_user_params
        if current_user.admin? 
            result = User.create_new_user new_user_params
            render json: result
        else
            render json: {
                state: false,
                message: "Insufficent Permission"
            }
        end
    end

    def edit
    end

    def update
        p params
        if @user.update(user_params)
  
            # Create a new History record
            history = History.new
            history.message = "User #{@user.full_name} was Updated."
            history.action_type = "User Update"
            history.creator = current_user
            history.save
      
            # add records to polymorphic association
            history.users << @user

            render json: {
                message: "User was successfully updated.", 
                pass: true
              }
        else

            render json: {
                message: @user.errors.full_messages.to_sentence, 
                pass: false
            }
        end
    end

    private

    def user_params
        params.required(:user).permit(:first_name, :last_name, :role, :approved, :marked_as_destroyed)
    end

    def new_user_params
        params.required(:user).permit(:email, :first_name, :last_name, :role, :title)
    end
end
