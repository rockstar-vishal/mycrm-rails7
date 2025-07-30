class CommunicationAttribute < ActiveRecord::Base
 
  belongs_to :trigger_event
  belongs_to :variable_mapping
end