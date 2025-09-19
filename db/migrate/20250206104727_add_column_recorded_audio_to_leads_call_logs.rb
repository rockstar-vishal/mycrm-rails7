class AddColumnRecordedAudioToLeadsCallLogs < ActiveRecord::Migration[7.1]
  def change
    # Active Storage handles file attachments automatically
    # add_attachment :leads_call_logs, :recorded_audio
  end
end
