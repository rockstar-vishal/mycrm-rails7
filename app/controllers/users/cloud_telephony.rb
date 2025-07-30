require 'active_support/concern'

module Users

  module CloudTelephony

    extend ActiveSupport::Concern

    included do

      belongs_to :cloud_telephony, class_name: 'CloudTelephony'

      def is_cloud_telephony_active?(integration_name)
        self.company.respond_to?("#{integration_name}_integration") &&
          self.company.send("#{integration_name}_integration").present? &&
          self.company.send("#{integration_name}_integration").active? && self.cloud_telephony_sid.present?
      end

      def cloud_telephony_no
        self.cloud_telephony_sid&.number
      end

      def cloud_telephony_caller_id
        self.cloud_telephony_sid.caller_id
      end

    end

  end
end