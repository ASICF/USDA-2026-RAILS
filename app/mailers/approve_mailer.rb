class ApproveMailer < ApplicationMailer

    def notification_for_admin(user)
      @user = user
      addresses = User.admins.approved.pluck(:email)
      if addresses.length > 0
        mail(to: addresses, subject: 'New account waiting for approval.')
      end
    end
  
    def notification_for_user(user)
      @user = user
      mail(to: user.email, subject: 'Your account is approved.')
    end

end
