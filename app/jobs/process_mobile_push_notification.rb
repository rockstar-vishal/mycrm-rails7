class ProcessMobilePushNotification

  @queue = :mobile_push_notification
  @process_mpn_logger = Logger.new('log/mobile_push_notification.log')


  def self.perform(id, options={})
    errors=[]
    begin
      lead = Lead.find(id)
      company = lead.company
      changes = options["changes"]
      if changes.present? && lead.company.enable_push_notify_closing_manager && changes.key?('closing_executive')
        message_text = "Lead #{lead.name}, assigned to #{lead.postsale_user&.name} has been created at #{lead.created_at.strftime('%d-%b-%y %H:%M %p')}"
        mobile_notification = PushNotificationServiceMobile.new(company, {message: message_text, notifiables: [lead.postsale_user&.uuid], target_url: "https://#{lead.company.mobile_domain}/Lead/#{lead.uuid}"})
        mobile_notification.deliver
      elsif changes.present? && changes.key?('user_id')
        message_text = "Lead #{lead.name}, assigned to #{lead.user&.name} has been created at #{lead.created_at.strftime('%d-%b-%y %H:%M %p')}"
        mobile_notification = PushNotificationServiceMobile.new(company, {message: message_text, notifiables: [lead.user.uuid], target_url: "https://#{lead.company.mobile_domain}/Lead/#{lead.uuid}"})
        mobile_notification.deliver
      else
        message_text = "Lead #{lead.name}, assigned to #{lead.user&.name} has been created at #{lead.created_at.strftime('%d-%b-%y %H:%M %p')}"
        mobile_notification = PushNotificationServiceMobile.new(company, {message: message_text, notifiables: [lead.user.uuid], target_url: "https://#{lead.company.mobile_domain}/Lead/#{lead.uuid}"})
        mobile_notification.deliver
      end
    rescue Exception => e
      error_message = "#{e.backtrace[0]} --> #{e}"
      errors << {message: error_message}
    end
    @process_mpn_logger.info("result for Lead ID- #{id} - #{errors}")
  end

end