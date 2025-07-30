class ProcessWebPushNotification

  @queue = :web_push_notification
  @process_wpn_logger = Logger.new('log/web_push_notification.log')


  def self.perform(id, options={})
    errors=[]
    begin
      lead = Lead.find(id)
      company = lead.company
      changes = options["changes"]
      if changes.present? && lead.company.enable_push_notify_closing_manager && changes.key?('closing_executive')
        message_text = "Lead #{lead.name}, assigned to #{lead.postsale_user&.name} has been created at #{lead.created_at.strftime('%d-%b-%y %H:%M %p')}"
        web_notification = PushNotificationServiceWeb.new(company, {message: message_text, notifiables: [lead.postsale_user&.uuid], target_url: "https://#{lead.company.domain}/Lead/#{lead.uuid}"})
        web_notification.deliver
      elsif changes.present? && changes.key?('user_id')
        message_text = "Lead #{lead.name}, assigned to #{lead.user&.name} has been created at #{lead.created_at.strftime('%d-%b-%y %H:%M %p')}"
        web_notification = PushNotificationServiceWeb.new(company, {message: message_text, notifiables: [lead.user.uuid], target_url: "https://#{lead.company.domain}/Lead/#{lead.uuid}"})
        web_notification.deliver
      else
        message_text = "Lead #{lead.name}, assigned to #{lead.user&.name} has been created at #{lead.created_at.strftime('%d-%b-%y %H:%M %p')}"
        web_notification = PushNotificationServiceWeb.new(company, {message: message_text, notifiables: [lead.user.uuid], target_url: "https://#{lead.company.domain}/Lead/#{lead.uuid}"})
        web_notification.deliver
      end
    rescue Exception => e
      error_message = "#{e.backtrace[0]} --> #{e}"
      errors << {message: error_message}
    end
    @process_wpn_logger.info("result for Lead ID- #{id} - #{errors}")
  end

end