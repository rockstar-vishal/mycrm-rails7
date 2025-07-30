class SiteVisitWhatsappReminder
    require 'uri'
    require 'net/http'
    require 'json'
  
    @queue = :site_visit_reminder
    @send_visit_notif = Logger.new('log/site_visit_reminder.log')
  
    def self.perform
      company=Company.find(97)
      leads=company.leads.where("status_id=? AND tentative_visit_planned BETWEEN ? AND ?", company.expected_site_visit_id, Date.today.at_end_of_day, Date.tomorrow.end_of_day)
      leads.each do |lead|
        Resque.enqueue(::ProcessUrbanWhatsappTrigger, lead.id)
      end
    end
  end