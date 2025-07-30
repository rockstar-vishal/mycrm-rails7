module ClientSmsNotification
  extend ActiveSupport::Concern

  included do
    before_validation :set_changes
    after_create :new_lead_generated_sms,  :new_lead_assigned, unless: Proc.new { |lead| lead.cannot_send_notification}
    after_commit :missed_followup, :site_visit_done_sms, :ravima_site_visit_done_sms, :site_visit_schedule_sms, :on_lead_assign, on: [:create, :update], unless: Proc.new { |lead| lead.cannot_send_notification }

    def call_log_exotel_sms_integration_enabled?
      self.call_logs.present? && self.call_logs.first.third_party_id == 1
    end

    def new_lead_generated_sms
      if self.company.template_flag_name =="ravima"
        if self.company.sms360_enabled
          ss = self.company.system_smses.new(
            messageable_id: self.id,
            messageable_type: "Lead",
            mobile: self.mobile,
            text: "Dear #{self.name}, Thanks for inquiring about #{self.project.name}. Let's find your dream home together! Ravima Ventures",
            template_id: '1707170143324367942',
            user_id: self.user_id
          )
          ss.save
        end
      elsif self.company.template_flag_name =="ashapura"
        ss = self.company.system_smses.new(
          messageable_id: self.id,
          messageable_type: "Lead",
          mobile: self.mobile,
          text: "Thank you for showing interest in our Rang Rekha project! Our team will connect with you shortly to assist further You can also call 9930400068\nTeam\nRang Rekha\nASHAPURA",
          template_id: '1707172715487914424',
          user_id: self.user_id
        )
        ss.save
      end
      if self.company.my_sms_shop_enabled
        if self.company.enable_status_wise_notification && self.company.notification_templates.find_by(notification_category: "lead create").present?
          template = self.company.notification_templates.find_by(notification_category: "lead create")
          ss = self.company.system_smses.new(
            messageable_id: self.id,
            messageable_type: "Lead",
            mobile: self.mobile,
            text: template.body,
            template_id: template.template_id,
            user_id: self.user_id
          )
        else
          ss = self.company.system_smses.new(
            messageable_id: self.id,
            messageable_type: "Lead",
            mobile: self.mobile,
            text: "Dear #{self.name}, \nThank you for enquiring for #{self.project&.name}. Our Sales team shall call you soon to discuss further. Call for more details: #{self.user&.mobile} \nRegards, CSRLTY",
            template_id: '1707166703057664355',
            user_id: self.user_id
          )
        end
        ss.save
      end
      if self.company.exotel_sms_integration_enabled && !call_log_exotel_sms_integration_enabled?
        ss = self.company.system_smses.new(
          messageable_id: self.id,
          messageable_type: "Lead",
          mobile: self.mobile,
          text: "Hello #{self.name},\nThank you for your interest in #{self.project&.name}.\nHere is your link for the e-Brochure #{self.project.brochure_link.present? ? self.project.brochure_link : ''}\nRegards,\nTeam DK Holdings.",
          user_id: self.user_id,
        )
        ss.save
      end
    end

    def ravima_site_visit_done_sms
      if self.company.template_flag_name =="ravima" && self.company.sms360_enabled && @changes.present? && @changes["status_id"].present? && (self.company.site_visit_done_id == self.status_id)
        ss = self.company.system_smses.new(
          messageable_id: self.id,
          messageable_type: "Lead",
          mobile: self.mobile,
          text: "Dear #{self.name}, Thanks for inquiring about #{self.project.name}. Let's find your dream home together! Ravima Ventures",
          template_id: '1707170143324367942',
          user_id: self.user_id
        )
        ss.save
      end
    end

    def new_lead_assigned
      if self.company.my_sms_shop_enabled && !self.company.enable_status_wise_notification
        ss = self.company.system_smses.new(
          messageable_id: self.user.id,
          messageable_type: "User",
          mobile: self.user.mobile,
          text: "Dear #{self.user&.name}, New Lead #{self.name} for #{self.project&.name} have been assigned to you. \nRegards, Team CSR CRM",
          user_id: (Lead.current_user.id rescue nil),
          template_id: '1707166634475843175'
        )
        ss.save
      end
      if self.company.exotel_sms_integration_enabled
        ss = self.company.system_smses.new(
          messageable_id: self.user.id,
          messageable_type: "User",
          mobile: self.user.mobile,
          text: "Hello #{self.user.name},\nA new lead has been assigned to you.\nRegards,\nTeam DK Holdings",
          user_id: (Lead.current_user.id rescue nil),
          template_id: '1207166280514165897'
        )
        ss.save
      end
      if self.company.template_flag_name == "amruttara"
        ss = self.company.system_smses.new(
          messageable_id: self.user.id,
          messageable_type: "User",
          mobile: self.user.mobile,
          text: "Dear user, you have received a lead on the Corelto panel for Mehta Group. Kindly login to the panel and give a call within 5 mins.",
          user_id: (Lead.current_user.id rescue nil),
          template_id: '1707171197361122248'
        )
        ss.save
      elsif self.company.template_flag_name =="ashapura"
        ss = self.company.system_smses.new(
          messageable_id: self.id,
          messageable_type: "User",
          mobile: self.user&.mobile,
          text: "Hi Team, we've received new lead#{self.name}from#{self.source&.name}Please follow up\nRegards,\nAshapura Realty",
          template_id: '1707172622874719624',
          user_id: (Lead.current_user.id rescue nil)
        )
        ss.save
      end
    end

    def missed_followup
      if self.company.exotel_sms_integration_enabled && @changes.present? && @changes["status_id"].present? && ([28,29,30].include? (self.status_id))
        ss = self.company.system_smses.new(
          messageable_id: self.id,
          messageable_type: "Lead",
          mobile: self.mobile,
          text: "Hello #{self.name},\nThank you for your interest in #{self.project&.name}.\nWe tried calling you but could not connect.\nFor any kind of assistance you can get in touch with #{self.user.name} on #{self.project.contact}.\nRegards,\nTeam DK Holdings.",
          user_id: self.user.id,
          template_id: 1207166253279725770
        )
        ss.save
      end
    end

    def site_visit_schedule_sms
      site_visit_ids=(self.company.expected_visit_ids.reject(&:blank?) | [self.company.expected_site_visit_id.to_s])
      if self.company.exotel_sms_integration_enabled && @changes.present? && @changes["status_id"].present? && (site_visit_ids.include? self.status_id.to_s)
        ss = self.company.system_smses.new(
          messageable_id: self.id,
          messageable_type: "Lead",
          mobile: self.mobile,
          user_id: self.user.id,
          text: "Hello #{self.name},\nThank you for your interest in #{self.project.name}.\nYour site visit is scheduled on #{self.tentative_visit_planned.strftime('%d/%m/%Y')} at #{self.tentative_visit_planned.strftime('%I:%M %p')}.\nLink for the location is #{self.project.location.present? ? self.project.location : ''}\nFor any kind of assistance you can get in touch with #{self.user.name} on #{self.project.contact}.\nRegards,\nTeam DK Holdings.",
          template_id: '1207166253270235585'
        )
        ss.save
      end
    end

    def site_visit_done_sms
      if self.company.exotel_sms_integration_enabled && @changes.present? && @changes["status_id"].present? && (self.company.site_visit_done_id == self.status_id)
        ss = self.company.system_smses.new(
          messageable_id: self.id,
          messageable_type: "Lead",
          mobile: self.mobile,
          text: "Hello #{self.name},\nThank you for visiting #{self.project.name}.\nHere is your link for the e-Brochure #{self.project.brochure_link.present? ? self.project.brochure_link : ''}.\nFor any kind of assistance you can get in touch with #{self.user.name} on #{self.project.contact}.\nRegards,\nTeam DK Holdings.",
          user_id: self.user.id,
          template_id: 1207166253275122447
        )
        ss.save
      end
    end

    def on_lead_assign
      message_attributes = if self.company.pg_sms_api_enabled
                              {template_id: "1707169277452886715", text: "Dear#{self.user&.name}, A new lead has been assigned to you today at #{self.updated_at.strftime('%I:%M %p')} Client Name -#{self.name} Divine Realtors"}
      elsif self.company.template_flag_name =="amruttara"
        {template_id: "1707171197361122248", text: "Dear user, you have received a lead on the Corelto panel for Mehta Group. Kindly login to the panel and give a call within 5 mins."}
      end

      if message_attributes.present? && message_attributes[:template_id].present? && message_attributes[:text].present? && @changes.present? && self.previous_changes.present? && self.previous_changes.include?(:user_id)
        ss = self.company.system_smses.new(
          messageable_id: self.user.id,
          messageable_type: "User",
          mobile: self.user.mobile,
          text: message_attributes[:text],
          user_id: (Lead.current_user.id rescue nil),
          template_id: message_attributes[:template_id]
        )
        ss.save
      end
    end

    def set_changes
      @changes = self.changes
    end
  end
end