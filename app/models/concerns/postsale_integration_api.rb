module PostsaleIntegrationApi

  extend ActiveSupport::Concern

  included do

    def client_integration_to_postsale
      biz_integration_logger = Logger.new('log/biz_integration_logger.log')
      if self.previous_changes.keys.present? && self.previous_changes.keys.include?("status_id") && self.company.booking_done_id == self.previous_changes["status_id"].last
        request = {"clients" => client_params}
        begin
          es = ExternalService.new(self.company, request)
          es.create_client
          biz_integration_logger.info("Client Detail Sent for #{self.company} at #{Time.zone.now}")
        rescue => e
          biz_integration_logger.info("Error Raised For Client Integration for #{self.company.id} at #{Time.zone.now} - #{e.message}")
        end
      end
    end

    def broker_integration_to_partner_crm
      biz_integration_logger = Logger.new('log/partner_integration_logger.log')
      request = {"brokers" => partner_params}
      begin
        es = ExternalService.new(self.company, request)
        response=es.create_partner
        if response && response["success"]
          self.update_column(:partner_broker_uuid, response["broker_uuid"])
        end
        biz_integration_logger.info("Broker Detail Sent for #{self.company.id} at #{Time.zone.now}")
      rescue => e
        biz_integration_logger.info("Error Raised For Broker Integration for #{self.company.id} at #{Time.zone.now} - #{e.message}")
      end
    end

    def broker_integration_to_postsale
      biz_integration_logger = Logger.new('log/biz_integration_logger.log')
      self.reload
      request = {"brokers" => broker_params}
      begin
        es = ExternalService.new(self.company, request)
        es.create_broker
        biz_integration_logger.info("Broker Detail Sent for #{self.company.id} at #{Time.zone.now}")
      rescue => e
        biz_integration_logger.info("Error Raised For Broker Integration for #{self.company.id} at #{Time.zone.now} - #{e.message}")
      end
    end

    def client_params
      {
        name: self.name,
        contact: self.mobile,
        email: self.email,
        address: self.address,
        lead_no: self.lead_no,
        password: 'password',
        enquiry: self.project&.name,
        source: self.source&.name
      }
    end

    def broker_params
      {
        name: self.name,
        email: self.email,
        mobile: self.mobile,
        rera_no: self.rera_number,
        presale_broker_uuid: self.uuid,
        partner_broker_uuid: self.partner_broker_uuid,
        company_name: self.firm_name,
        password: 'password'
      }
    end

    def partner_params
      {
        name: self.name,
        phone: self.mobile,
        email: self.email,
        firm_name: self.firm_name,
        presale_broker_uuid: self.uuid,
        rera_no: self.rera_number
      }
    end
  end
end