require 'active_support/concern'

module ThirdPartyHookApi

  extend ActiveSupport::Concern

  included do
    
    after_commit :update_lead_to_nine_nine_acres, on: :update

    def update_lead_to_nine_nine_acres
      if self.company.nine_nine_update_enabled && self.company.nine_nine_profile_id.present? && self.project.nine_token.present? && self.previous_changes.present? && self.previous_changes["comment"].present?
        Resque.enqueue(ProcessNineNineLead, self.id)           
      end
    end


  end


end