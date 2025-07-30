class ProcessLeadExport
  require 'uri'
  require 'net/http'
  require 'json'

  @queue = :process_export
  @process_export_logger = Logger.new('log/process_export.log')

  def self.perform(id, file_export_id)
    export_log = ::ExportLog.find_by(id: id)
    file_export = ::FileExport.find_by(id: file_export_id)
    begin
      csv_data = export_log.company.leads.where(id: export_log.target_ids).to_csv(export_log.user)
      file_export.update_columns(
        is_ready: true,
        data: Base64.encode64(csv_data)
      )
    rescue Exception => e
      @process_export_logger.info("processing sms-#{id} - 4")
    end
    @process_export_logger.info("processing Export-#{id} - 6")
    return true
  end
end