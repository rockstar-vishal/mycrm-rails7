module NotificationTriggerEvents

  extend ActiveSupport::Concern

  included do
    before_validation :set_changes
    after_commit :send_lead_creation_sms, :new_lead_assigned_on_creation, on: :create, if: :check_value_first_setting_presence?
    after_commit :send_lead_update_sms, :sms_on_lead_assign, on: :update, if: :check_value_first_setting_presence?
    
    def send_lead_creation_sms
      communication_template = self.company.communication_templates.for_sms.last
      trigger_event = communication_template.trigger_events.to_lead_create_event.last rescue nil
      communication_attributes = trigger_event.communication_attributes if trigger_event.present?

      if trigger_event.present? && communication_attributes.present?
        text = merget_sms_text(communication_attributes, text = "")
        send_sms_to_lead(trigger_event.object_entity, trigger_event.template_id, text)
      end
    end

    def send_lead_update_sms
      if @changes.present? && @changes["status_id"].present?
        communication_template = self.company.communication_templates.for_sms.last
        trigger_event = communication_template.trigger_events.to_lead_update_event.where(to_status: self.status_id).last rescue nil
        communication_attributes = trigger_event.communication_attributes if trigger_event.present?

        if trigger_event.present? && communication_attributes.present?
          text = merget_sms_text(communication_attributes, text = "")   
          send_sms_to_lead(trigger_event.object_entity, trigger_event.template_id, text)
        end
      end
    end

    def new_lead_assigned_on_creation
      communication_template = self.company.communication_templates.for_sms.last
      trigger_event = communication_template.trigger_events.to_user_create_event.last rescue nil
      communication_attributes = trigger_event.communication_attributes if trigger_event.present?

      if trigger_event.present? && communication_attributes.present?
        text = merget_sms_text(communication_attributes, text = "") 
        send_sms_to_user(trigger_event.object_entity, trigger_event.template_id, text)
      end
    end

    def sms_on_lead_assign
      if @changes.present? && @changes["user_id"].present?
        communication_template = self.company.communication_templates.for_sms.last
        trigger_event = communication_template.trigger_events.to_user_update_event.last rescue nil
        communication_attributes = trigger_event.communication_attributes if trigger_event.present?

        if trigger_event.present? && communication_attributes.present?
          text = merget_sms_text(communication_attributes, text = "") 
          send_sms_to_user(trigger_event.object_entity, trigger_event.template_id, text)
        end
      end
    end

    def merget_sms_text(communication_attributes, text = "")
      communication_attributes.each do |attribute|
        variable_mapping = attribute.variable_mapping rescue nil
        text += "#{attribute[:text]} "
        if variable_mapping.present?
          associated_object = self.class == variable_mapping.variable_type.constantize ? self : send(variable_mapping.system_assoication)
          text += "#{associated_object.send(variable_mapping.system_attribute)} "
        end
      end 

      return text
    end

    def send_sms_to_lead(object_entity, template_id, text)
      sms = self.company.system_smses.new(
        messageable_id: self.id,
        messageable_type: object_entity,
        mobile: self.mobile,
        text: text,
        user_id: self.user_id,
        is_vf_sms: true,
        template_id: template_id
      )
      sms.save
    end

    def send_sms_to_user(object_entity, template_id, text)
      sms = self.company.system_smses.new(
        messageable_id: self.user.id,
        messageable_type: object_entity,
        mobile: self.user.mobile,
        text: text,
        user_id: self.user_id,
        is_vf_sms: true,
        template_id: template_id
      )
      sms.save
    end

    def set_changes
      @changes = self.changes
    end

    def check_value_first_setting_presence?
      self.company.value_first_integration&.active.present? && self.company.value_first_integration.user_name.present? && self.company.value_first_integration.token.present? && self.company.value_first_integration.sender.present?
    end
  end
end