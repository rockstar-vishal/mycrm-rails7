class ExportLeadRecords
  @queue = :export_lead_records
  @export_lead_records_logger = Logger.new('log/export_lead_records.log')

  def self.perform
    company = ::Company.find_by(id: 164)
    file = "#{Rails.root}/public/#{company.name}-master-data.csv"
    puts "Initiated..."
    @export_lead_records_logger.info("Exporting Initiated ! - 1")
    CSV.open(file, "w") do |csv|
      exportable_fields = ['Customer Name', 'Lead Number', 'Project', 'Assigned To', 'Lead Status', 'Next Call Date', 'Comment', 'Source', 'Broker', 'Visited', 'Visited Date', 'Dead Reason', 'City', 'Created At']
      exportable_fields += company.magic_fields.pluck(:pretty_name)
      exportable_fields += ['Mobile', 'Email', 'Tentative Visit Date', 'Tentative Visit Day', 'Tentative Visit Time']
      csv << exportable_fields

      company.leads.includes(project: :city).find_each do |client|
        dead_reason = company.dead_status_ids.include?(client.status_id.to_s) ? (client.dead_reason.reason rescue '') : ''
        final_phone = client.mobile
        final_email = client.email
        final_source = client.source.name rescue '-'
        final_broker = company.cp_sources.ids.include?(client.source_id) ? (client.broker.name rescue '-') : '-'

        this_exportable_fields = [
          client.name,
          client.lead_no,
          (client.project.name rescue '-'),
          (client.user.name rescue '-'),
          client.status.name,
          (client.ncd.strftime("%d %B %Y") rescue nil),
          client.comment,
          final_source,
          final_broker,
          client.visits.present? ? "Yes" : "No",
          (client.visits.collect(&:date).join(',') rescue "-"),
          dead_reason,
          (client.project.city.name rescue "-"),
          (client.created_at.strftime("%d %B %Y") rescue nil)
        ]

        company.magic_fields.each do |field|
          this_exportable_fields << client.send(field.name)
        end

        this_exportable_fields += [
          final_phone,
          final_email,
          client.tentative_visit_planned&.strftime("%d-%m-%Y"),
          client.tentative_visit_planned&.strftime("%A"),
          client.tentative_visit_planned&.strftime("%I:%M %p")
        ]

        csv << this_exportable_fields
      end
    end
    @export_lead_records_logger.info("Data Exported ! - 2")
    puts "Data Exported !"
  end
end
