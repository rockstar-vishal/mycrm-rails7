module LeadNotifications

  extend ActiveSupport::Concern

  included do

    before_validation :set_changes
    after_commit :notify_lead_assign_user, :send_whatsapp_notification_to_client
    after_commit :create_ravima_leads, :whatsapp_notify_on_status_change, :create_gbk_group_hot_warm_cold, on: :update
    after_create :send_whatsapp_on_create, :create_ravima_nextel_leads

    TRIGGER_MAPPING = [423,424,425,426,427,428,429]

    def notify_lead_assign_user
      if self.company.can_send_lead_assignment_mail && self.company.mailchimp_integration.active? && @changes.present? && @changes["user_id"].present?
        Resque.enqueue(::ProessAssignmentChangeNotification, self.id)
      end
      if self.company.push_notification_setting.present? && self.company.push_notification_setting.is_active? && @changes.present? && (@changes["user_id"].present? || @changes["closing_executive"].present?) && self.company.events.include?('lead_assign')
        Resque.enqueue(::ProcessMobilePushNotification, self.id, changes: @changes)
        Resque.enqueue(::ProcessWebPushNotification, self.id, changes: @changes)
      end
    end


    def set_changes
      @changes = self.changes
    end

    def send_whatsapp_on_create
      # Agami Realty DoubleTick integration - check by company UUID
      if self.company.uuid == 'df33c145-78db-4ddd-be80-04c000c7d5be'
        Resque.enqueue(::ProcessAgamiDoubletickWhatsappTrigger, self.id, 'on_create')
      end
      
      if self.company.whatsapp_integration&.active
        if self.company.whatsapp_integration.user_name == "golden abode"
          body_values = {
            name: self.name,
            Project: self.project.name,
            executivename: (self.user&.name rescue nil)
          }
          Resque.enqueue(::ProcessGabodeWhatsapp, "new_lead_marketing_message", self.id, body_values, recipient_data)
        elsif self.company.whatsapp_integration.integration_key.present? && self.company.whatsapp_integration.user_name == "panom" && [3743].include?(self.project_id)
          Resque.enqueue(::ProcessPanomWhatsappTrigger, self.id, "on_create")
        elsif self.company.whatsapp_integration.integration_key.present? && self.company.whatsapp_integration.user_name == "vm builder"
          Resque.enqueue(::ProcessVmBuilderWhatsappTrigger, self.id, 'on_create')
        elsif self.company.whatsapp_integration.user_name == "ceratec"
          Resque.enqueue(::ProcessCeratecWhatsappTrigger, self.id)
        elsif self.company.whatsapp_integration.integration_key.present? && self.company.whatsapp_integration.user_name == "bharat realty"
          Resque.enqueue(::ProcessBharatWhatsappTrigger, self.id, 'on_create')
        elsif self.company.whatsapp_integration.user_name == "mahadev greens" && [4841].include?(self.project_id)
          Resque.enqueue(::ProcessMahadevWhatsappTrigger, self.id, 'on_create')
        elsif self.company.whatsapp_integration.user_name == "sk fortune"
          Resque.enqueue(::ProcessSkfortuneWhatsappTrigger, self.id)
        elsif self.company.whatsapp_integration.integration_key.present? && self.company.whatsapp_integration.user_name == "vinra group"
          Resque.enqueue(::ProcessVinraWhatsappTrigger, self.id, 'on_create')
        elsif self.company.whatsapp_integration.user_name == "ashapura"
          Resque.enqueue(::ProcessAshapuraWhatsappTrigger, self.id)
        elsif self.company.whatsapp_integration.integration_key.present? && self.company.whatsapp_integration.user_name == "GBK Group"
          Resque.enqueue(::ProcessGbkgroupWhatsappTrigger, self.id, 'on_create')
        end
      end
    end

    def whatsapp_notify_on_status_change
      if self.company.whatsapp_integration&.active && self.company.whatsapp_integration.integration_key.present?
        if self.company.whatsapp_integration.user_name == "mahadev greens" && self.previous_changes.present? && self.previous_changes["status_id"].present? && [1].include?(self.status_id) && [4841].include?(self.project_id)
          Resque.enqueue(::ProcessMahadevWhatsappTrigger, self.id)
        elsif self.company.whatsapp_integration.user_name == "golden abode" && self.previous_changes.present? && self.previous_changes["status_id"].present? && [99].include?(self.status_id)
          body_values = {
            name: self.name,
            project: self.project.name,
            location: (self.city&.name rescue nil)
          }
          Resque.enqueue(::ProcessGabodeWhatsapp, "not_answering_leads_marketing_message", self.id, body_values, recipient_data)
        elsif self.company.whatsapp_integration.user_name == "vinra group" && self.previous_changes.present? && self.previous_changes["status_id"].present? && [646].include?(self.status_id)
          Resque.enqueue(::ProcessVinraWhatsappTrigger, self.id)
        end
      end
    end

    def send_whatsapp_notification_to_client
      # Agami Realty DoubleTick integration - check by company UUID
      if self.company.uuid == 'df33c145-78db-4ddd-be80-04c000c7d5be' && self.previous_changes.present? && self.previous_changes["status_id"].present?
        # Check if the new status maps to a DoubleTick template
        status_name = self.status&.name
        if status_name.present? && ProcessAgamiDoubletickWhatsappTrigger::STATUS_TEMPLATE_MAPPING.key?(status_name)
          Resque.enqueue(::ProcessAgamiDoubletickWhatsappTrigger, self.id)
        end
      end
      
      if self.company.whatsapp_integration&.active && self.company.whatsapp_integration.integration_key.present?
        if self.company.whatsapp_integration.user_name == "panom" && self.previous_changes.present? && self.previous_changes["status_id"].present? && [12,49,50,54,87,310,405,406,407].include?(self.status_id)
          Resque.enqueue(::ProcessPanomWhatsappTrigger, self.id)
        elsif self.company.whatsapp_integration.user_name == "vm builder" && self.previous_changes.present? && self.previous_changes["status_id"].present? && [18,22,33].include?(self.status_id)
          Resque.enqueue(::ProcessVmBuilderWhatsappTrigger, self.id)
        elsif self.previous_changes.present? && self.previous_changes["status_id"].present? && [1,108,280].include?(self.status_id)
          Resque.enqueue(::ProcessUrbanWhatsappTrigger, self.id)
        elsif self.company.whatsapp_integration.user_name == "bharat realty" && self.previous_changes.present? && self.previous_changes["status_id"].present? && [self.company.booking_done_id, 50, 593].include?(self.status_id)
          Resque.enqueue(::ProcessBharatWhatsappTrigger, self.id)
        elsif self.company.whatsapp_integration.user_name == "GBK Group" && self.previous_changes.present? && self.previous_changes["status_id"].present? && [18,22, 50].include?(self.status_id) && self.created_at != self.updated_at
          Resque.enqueue(::ProcessGbkgroupWhatsappTrigger, self.id)
        end
      elsif self.company.whatsapp_integration&.active && self.company.whatsapp_integration.user_name == "ceratec" && self.previous_changes.present? && self.previous_changes["status_id"].present? && [22,33].include?(self.status_id)
        Resque.enqueue(::ProcessCeratecWhatsappTrigger, self.id)
      elsif self.previous_changes.present? && self.previous_changes["status_id"].present? && TRIGGER_MAPPING.include?(self.status_id)
        Resque.enqueue(::ProcessWhatsAppTrigger, self.id)
      end
    end

    def create_ravima_nextel_leads
      if self.company.template_flag_name =="ravima"
        Resque.enqueue(::ProcessNextelLeads, self.id)
      end
      if self.company.setting.present? && self.company.enable_nextel_whatsapp_triggers
        Resque.enqueue(::ProcessRavimaWhatsappTrigger, self.id, 'on_create')
      end
    end

    def create_ravima_leads
      if self.company.template_flag_name =="ravima" && self.previous_changes.present? && self.previous_changes["status_id"].present?
        Resque.enqueue(::ProcessNextelLeads, self.id)
      end
      if self.company.setting.present? && self.company.enable_nextel_whatsapp_triggers && self.previous_changes.present? && self.previous_changes["status_id"].present?
        Resque.enqueue(::ProcessRavimaWhatsappTrigger, self.id)
      end
    end

    def create_gbk_group_hot_warm_cold
      if company.client_visit_qr && self.previous_changes.present? && self.previous_changes["status_id"].present? && [6,5,14].include?(self.status_id)
        Resque.enqueue(::AutoMessageWhenLeadStatusIsMarked, self.id)
      end
    end

    def recipient_data
      {
        name: self.name,
        phone: "91#{self.mobile.last(10)}"
      }
    end
  end
end