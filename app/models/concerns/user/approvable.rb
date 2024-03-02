module Concerns::User::Approvable
  extend ActiveSupport::Concern

  # included do
  #   # before_save :auto_approve
  #   if !Rails.env.development?
  #     after_commit :send_notification_for_admin, on: :create
  #     after_commit :send_notification_for_user, on: [:create, :update]
  #   end
  # end

  # def send_notification_for_admin
  #   unless approved?
  #     ApproveMailer.notification_for_admin(self).deliver
  #   end
  # end

  # def send_notification_for_user
  #   if previous_changes.include?(:approved) && approved?
  #     ApproveMailer.notification_for_user(self).deliver
  #   end
  # end

end
