require 'active_support/concern'

module CallLogApiAttributes

  extend ActiveSupport::Concern

  included do

    acts_as_api

    api_accessible :call_log_details do |template|
      template.add :id
      template.add lambda{|call_log| call_log.lead&.name  }, as: :lead_name
      template.add lambda{|call_log| call_log.lead&.uuid  }, as: :lead_uuid
      template.add lambda{|call_log| call_log.lead&.status&.name  }, as: :lead_status
      template.add lambda{|call_log| call_log.lead&.project&.name  }, as: :project_name
      template.add :from_number
      template.add :to_number
      template.add lambda{|call_log| call_log.other_data['direction']  }, as: :call_type
      template.add :start_time
      template.add :end_time
      template.add :duration

    end

    def duration
      raw_duration = self[:duration]
      return 0 unless raw_duration.is_a?(String)

      if raw_duration =~ /\A\d{2}:\d{2}:\d{2}\z/
        hours, minutes, seconds = raw_duration.split(':').map(&:to_i)
        (hours * 3600) + (minutes * 60) + seconds
      else
        raw_duration.to_i
      end
    end

  end
end