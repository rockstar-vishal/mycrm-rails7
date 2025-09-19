require 'csv'
class BulkStepupLeadDeletion
  @queue = :process_stepupleads_deletion
  @process_stepup_deletion_logger = Logger.new('log/process_stepup_deletion_logger.log')

  def self.perform file_path
    begin
      @lead_nos=[]
      CSV.foreach(file_path, headers: :first_row, encoding: "iso-8859-1:utf-8").with_index(1) do |row, index|
          @lead_nos<<row["Lead Number"]
      end
      company=Company.find(83)
      leads=company.leads.where(lead_no: @lead_nos)
      if leads.present?
        leads.each_slice(1000).to_a.each do |leads_batch|
          leads_batch.map(&:destroy)
        end
      else
        @process_stepup_deletion_logger.info("Leads not found--- 1")
      end
    rescue
      @process_stepup_deletion_logger.info("processing Deletion Failed--- 2")
    end
    @process_stepup_deletion_logger.info("Deletion Done - 3")
    return true
  end
end