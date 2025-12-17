class ProcessAgamiDoubletickWhatsappTrigger
  @queue = :process_whatsapp
  @process_agami_doubletick_logger = Logger.new('log/process_whatsapp.log')

  # Agami company UUID
  AGAMI_COMPANY_UUID = 'df33c145-78db-4ddd-be80-04c000c7d5be'

  # Status name to template name mapping
  STATUS_TEMPLATE_MAPPING = {
    'New' => 'newlead',
    'Attempted to Contact' => 'attemptedtocontact_v2',
    'Following' => 'following_up',
    'Site Visit Scheduled' => 'site_visit_scheduled',
    'Site Visit Done' => 'site_visit_completed',  # Note: Status name as provided by client
    'Site Visit Followup' => 'site_visit_followup',
    'Hot' => 'hot_lead',
    'Booked' => 'booked',
    'Unqualified' => 'unqualified',
    'Lost' => 'lost_lead',
    'Cold' => 'cold',
    'Warm' => 'warm_lead'
  }.freeze

  # DoubleTick API credentials
  DOUBLETICK_API_KEY = CRMConfig.agami_doubletick_key

  def self.perform(id, *args)
    lead = ::Lead.find_by(id: id)
    return false unless lead.present?

    # Verify this is for Agami company
    unless lead.company.uuid == AGAMI_COMPANY_UUID
      @process_agami_doubletick_logger.info("Lead #{id} is not for Agami company. Skipping.")
      return false
    end

    begin
      # Determine template name based on context
      template_name = determine_template_name(lead, args)
      
      unless template_name.present?
        @process_agami_doubletick_logger.info("No template mapping found for lead #{id} with status: #{lead.status&.name}")
        return false
      end

      # Send WhatsApp template via DoubleTick
      success, response = DoubletickNotificationService.send_template_message(
        lead,
        template_name,
        DOUBLETICK_API_KEY
      )

      if success
        message_id = response.is_a?(Hash) ? response[:message_id] : nil
        log_message = "Successfully sent DoubleTick WhatsApp template '#{template_name}' for Lead ID: #{id}"
        log_message += " - Message ID: #{message_id}" if message_id.present?
        @process_agami_doubletick_logger.info(log_message)
      else
        @process_agami_doubletick_logger.error("Failed to send DoubleTick WhatsApp template for Lead ID: #{id} - Error: #{response}")
      end

      return success
    rescue Exception => e
      @process_agami_doubletick_logger.error("Exception while processing DoubleTick WhatsApp notification for Lead ID: #{id} - Error: #{e.message}")
      @process_agami_doubletick_logger.error(e.backtrace.join("\n"))
      return false
    end
  end

  private

  def self.determine_template_name(lead, args)
    # If called with 'on_create', use newlead template
    if args.first == 'on_create'
      return 'newlead'
    end

    # Otherwise, map current status to template
    status_name = lead.status&.name.to_s.strip
    return nil unless status_name.present?

    STATUS_TEMPLATE_MAPPING[status_name]
  end
end

