module EmailNotifications

  extend ActiveSupport::Concern

  included do

    before_validation :set_changes
    after_commit :lead_creation_email, on: :create, if: -> { email.present? }
    after_commit :send_email_site_visit_conducted, :send_email_unanswered_leads, :send_email_callback_leads, :send_email_interested_leads, :send_email_inactive_leads, :send_email_on_visit_scheduled, :send_email_on_visit_done, if: -> { email.present? }

    def send_email_site_visit_conducted
      if self.company.enable_smtp_settings && @changes.present? && @changes["status_id"].present? && self.status_id == self.company.site_visit_done&.id
        user = Lead.current_user
        email = user.sent_emails.build(
          receiver_id: self.id,
          receiver_type: 'Lead',
          subject:"Thank you for enquiring!",
          event_type: 'ProcessSiteVisitConductedNotification'
        )
        email.save
      end
    end

    def send_email_unanswered_leads
      if self.company.enable_smtp_settings && @changes.present? && @changes["status_id"].present? && self.company.template_flag_name == "panom" && ["Not Answered","Non Contactable"].include?(self.status&.name)
        user = Lead.current_user
        email = user.sent_emails.build(
          receiver_id: self.id,
          receiver_type: 'Lead',
          subject:"DELIGHTED TO HAVE RECEIVED YOUR INTEREST IN - #{self.project&.name.upcase}, VILE PARLE EAST.",
          event_type: 'ProcessUnansweredLeadMail'
        )
        email.save
      end
    end

    def send_email_callback_leads
      if self.company.enable_smtp_settings && @changes.present? && @changes["status_id"].present? && self.company.template_flag_name == "panom" && self.status.name == "Call Back"
        user = Lead.current_user
        email = user.sent_emails.build(
          receiver_id: self.id,
          receiver_type: 'Lead',
          subject:"ALAS WE COULD NOT TOUCH BASE WITH YOU",
          event_type: 'ProcessCallbackLeadMail'
        )
        email.save
      end
    end

    def send_email_interested_leads
      if self.company.enable_smtp_settings && @changes.present? && @changes["status_id"].present? && self.status.name == "Details Shared" && self.company.template_flag_name == "panom"
        user = Lead.current_user
        email = user.sent_emails.build(
          receiver_id: self.id,
          receiver_type: 'Lead',
          subject:"SUBSEQUENT TO THE WONDERFUL DISCUSSION WE HAD IN REGARDS TO OUR PROJECT -  #{self.project.name.upcase}, VILE PARLE EAST",
          event_type: 'ProcessInterestedLeadMail'
        )
        email.save
      end
    end

    def send_email_on_visit_scheduled
      if self.company.enable_smtp_settings && @changes.present? && @changes["status_id"].present? && self.company.expected_site_visit_id == self.status_id && self.company.template_flag_name == "panom"
        user = Lead.current_user
        email = user.sent_emails.build(
          receiver_id: self.id,
          receiver_type: 'Lead',
          subject:"EAGERLY LOOKING FORWARD TO MEET YOU AT OUR CUSTOMER EXPERIENCE CENTER",
          event_type: 'ProcessVisitScheduledMail'
        )
        email.save
      end
    end

    def send_email_inactive_leads
      if self.company.enable_smtp_settings && @changes.present? && @changes["status_id"].present? && ["Not Interested","LSV Dead","Dead"].include?(self.status.name) && self.company.template_flag_name == "panom"
        user = Lead.current_user
        email = user.sent_emails.build(
          receiver_id: self.id,
          receiver_type: 'Lead',
          subject:"HOPE WE ARE ABLE TO MEET YOUR EXPECTATIONS IN THE FUTURE",
          event_type: 'ProcessInactiveLeadMail'
        )
        email.save
      end
    end

    def lead_creation_email
      user = Lead.current_user
      subject = CompanyConstants::SUBJECTS[self.company.template_flag_name]

      if self.company.enable_smtp_settings && check_project_condition && subject
        email = user.sent_emails.build(
          receiver_id: self.id,
          receiver_type: 'Lead',
          subject: subject,
          event_type: 'ProcessLeadOnCreationEmail'
        )
        email.save
      end
    end

    def send_email_on_visit_done
      if self.company.enable_smtp_settings && @changes.present? && @changes["status_id"].present? && self.company.site_visit_done&.id == self.status_id
        user = Lead.current_user
        subject = CompanyConstants::VISIT_DONE_SUBJECTS[self.company.template_flag_name]
        if subject.present?
          email = user.sent_emails.build(
            receiver_id: self.id,
            receiver_type: 'Lead',
            subject: subject,
            event_type: 'ProcessVisitDoneMail'
          )
          email.save
        end
      end
    end

    def set_changes
      @changes = self.changes
    end

    def check_project_condition
      return true unless self.company.template_flag_name == 'panom'

      [3743].include?(self.project_id)
    end
  end
end