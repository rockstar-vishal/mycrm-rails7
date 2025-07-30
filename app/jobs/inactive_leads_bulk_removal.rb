class InactiveLeadsBulkRemoval

  @queue = :process_inactive_leads_removal
  @process_inactive_removal_logger = Logger.new('log/process_inactive_removal_logger.log')

  def self.perform
    begin
      company = Company.find(196)
      inactive_leads=company.leads.where(status_id: company.dead_status_ids)
      @process_inactive_removal_logger.info("processing Deletion starts--- 1")
      inactive_leads.each_slice(1000).to_a.each do |leads_batch|
        leads_batch.map(&:destroy)
      end
    rescue Exception => e
      @process_inactive_removal_logger.info("processing Deletion Failed--- 2")
    end
    @process_inactive_removal_logger.info("Deletion Done - 3")
    return true
  end

end