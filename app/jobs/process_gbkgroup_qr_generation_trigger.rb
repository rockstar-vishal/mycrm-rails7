class ProcessGbkgroupQrGenerationTrigger
  require 'rqrcode'
  require 'chunky_png'
  @queue = :process_whatsapp
  @process_gbkgroup_whatsapp_logger = Logger.new('log/process_whatsapp.log')

  def self.perform(id, new_lead)
    lead = ::Lead.find_by(id: id)
    broker = lead.broker
    return unless lead && broker

    begin
      url = "https://backend.api-wa.co/campaign/tradai/api/v2"
      formatted_status = new_lead ? "lead_creation" : "send_site_visit_url"
      campaign_data = send(formatted_status, lead, broker)
      qr_file_path = nil
      if formatted_status == "send_site_visit_url"
        qrcode = RQRCode::QRCode.new(lead.lead_no.to_s, mode: :byte_8bit, level: :h)

        folder_path = Rails.root.join("public")
        FileUtils.mkdir_p(folder_path) unless Dir.exist?(folder_path)

        qr_file_path = folder_path.join("#{lead.lead_no}.png")

        unless File.exist?(qr_file_path)
          png = qrcode.as_png(
            bit_depth: 8,
            border_modules: 4,
            color: "black",
            fill: "white",
            module_px_size: 10,
            resize_exactly_to: false,
            resize_gte_to: false,
            size: 1500
          )

          png_image = ChunkyPNG::Image.from_string(png.to_s)

          png_image.save(qr_file_path, color_mode: ChunkyPNG::COLOR_GRAYSCALE)
        end
      end
      media_url = "https://#{lead.company.domain}/#{lead.lead_no}.png"
      if formatted_status == "send_site_visit_url"
        request = {
          "apiKey": "#{lead.company.whatsapp_integration.integration_key}",
          "campaignName": campaign_data[:campaign_name],
          "destination": "+91#{lead.mobile.to_s.last(10)}",
          "userName": lead.name,
          "templateParams": campaign_data[:template_params]
        }
        request['media'] = {
          "url": media_url,
          "filename": "QR"
        } if formatted_status == "send_site_visit_url"
        RestClient.post(url, request)
        @process_gbkgroup_whatsapp_logger.info("WhatsApp sent to Lead: #{lead.id}")
      end

      if formatted_status == "lead_creation"
        broker_request = {
          "apiKey": "#{lead.company.whatsapp_integration.integration_key}",
          "campaignName": campaign_data[:campaign_name],
          "destination": "+91#{broker.mobile.to_s.last(10)}",
          "userName": broker.name,
          "templateParams": campaign_data[:template_params]
        }
        RestClient.post(url, broker_request)
        @process_gbkgroup_whatsapp_logger.info("WhatsApp sent to Broker: #{broker.id}")
      end
      #  if File.exist?(qr_file_path)
      #   File.delete(qr_file_path)
      # end

    rescue => e
      @process_gbkgroup_whatsapp_logger.error("Error sending WhatsApp for Lead #{lead&.id}: #{e.message}")
    end
    true
  end

  class << self
    def lead_creation(lead, broker)
      {
        campaign_name: "3_lead_new",
        template_params: [
          lead.name,
        ]
      }
    end

    def send_site_visit_url(lead, broker)
      pickup_location = lead.magic_attributes.find_by(
        magic_field: lead.company.magic_fields.find_by(name: "pickup_location")
      )&.value || ""
      {
        campaign_name: "Site Visit Confirmation Qr",
        template_params: [
          lead.name,
          lead.project&.name || "Vishwajeet Empire - Pale Ambernath East",
          pickup_location || "https://bit.ly/empirelocation",
          lead.tentative_visit_planned&.strftime("%d-%m-%Y") || "Date",
          lead.tentative_visit_planned&.strftime("%I:%M %p") || "Time"
        ]
      }
    end
  end
end
