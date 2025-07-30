class AddColumnRecordedAudioToLeadsCallLogs < ActiveRecord::Migration
  def change
    add_attachment :leads_call_logs, :recorded_audio
  end
end
