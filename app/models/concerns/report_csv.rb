require 'csv'

module ReportCsv

  extend ActiveSupport::Concern

  included do
    class << self

      def report_to_csv(options = {},user)
        data = all.group("user_id, status_id").select("COUNT(*), user_id, status_id, json_agg(leads.id) as lead_ids")
        @data = data.as_json
        users = user.manageables.where(:id=>data.map(&:user_id).uniq)
        statuses = user.company.statuses.where(:id=>data.map(&:status_id).uniq)
        CSV.generate do |csv|
          exportable_fields = ['User Name', 'User Role', 'Total Count' ]
          statuses.each do |status|
            exportable_fields << status.name
          end
          csv << exportable_fields
          users.each do |user|
            this_user_data = @data.select{|k| k["user_id"] == user.id}
            if this_user_data.present?
              user_total = (this_user_data.map{|k| k["lead_ids"].count}.sum rescue nil)
              this_exportable_fields = [user.name, user.role.name, user_total]
              statuses.each do |status|
                this_status_data = this_user_data.detect{|k| k["status_id"] == status.id}
                this_exportable_fields << (this_status_data["lead_ids"].count rescue nil)
              end
            end
            csv << this_exportable_fields
          end
        end
      end

      def svp_tracker_to_csv(options={}, user)
        data = all.site_visit_scheduled
        users = user.manageables.where(:id=>data.map(&:user_id).uniq)
        CSV.generate do |csv|
          exportable_fields = ['User','Site Visit Planned','Site visit done','Site Visit Postponed','Site visit cancel','Revisit','Booked Percentage','Token Percentage']
          csv << exportable_fields
          users.each do |user|
            this_user_data = data.where(:user_id=>user.id)
            if this_user_data.present?
              user_total = this_user_data.count
              this_exportable_fields = [user.name, user_total]
              visit_done = this_user_data.joins(:visits).where(visits: {is_visit_executed: true}).uniq.size
              this_exportable_fields << "#{visit_done} - (#{((visit_done / this_user_data.size.to_f) * 100).round(2)}%)"
              this_exportable_fields<<this_user_data.joins(:visits).where("leads_visits.is_postponed = 't'").uniq.size
              this_exportable_fields << this_user_data.joins(:visits).where("leads_visits.is_canceled = 't'").uniq.size
              this_exportable_fields << this_user_data.where(revisit: true).size
              visit_done = this_user_data.joins(:visits).uniq.size
              booked = this_user_data.booked_for(user.company).count
              this_exportable_fields << "#{booked} - (#{((booked.to_f / visit_done.to_f) * 100).round(2)}%)"
              visit_done = this_user_data.joins(:visits).uniq.size
              tokened = this_user_data.where(status_id: user.company.token_status_ids).count
              this_exportable_fields<<"#{tokened} - (#{((tokened.to_f / visit_done.to_f) * 100).round(2)}%)"
            end
            csv << this_exportable_fields
          end
        end
      end

      def campaign_report_to_csv(options={}, user)
        @leads = all.where(:user_id=>user.manageable_ids)
        campaigns = user.company.campaigns

        CSV.generate do |csv|
          exportable_fields = ['Title', 'Start Date', 'End Date', 'Budget', 'Source', 'project', 'Leads', 'Booked Leads', 'Cost per Lead', 'Visits', 'Cost Per Visit', 'Cost Per Booking' ]
          csv << exportable_fields
          campaigns.each do |campaign|
            leads = @leads
            if campaign.project_ids.present?
              leads = leads.where(project_id: campaign.project_ids)
            end
            booking_data = leads.booked_for(user.company)
            visted_data = leads.joins(:visits).uniq
            this_exportable_fields = [campaign.title, campaign.start_date&.strftime("%Y-%m-%d"), campaign.end_date&.strftime("%Y-%m-%d"), Utility.to_words(campaign.budget), campaign.source_name, (campaign.projects.pluck(:name).join(', ') rescue "")]
            leads_count = leads.where(source_id: campaign.source_id, created_at: campaign.start_date.beginning_of_day..campaign.end_date.end_of_day).count
            this_exportable_fields << leads_count
            booked_leads_count = booking_data.where(source_id: campaign.source_id, created_at: campaign.start_date.beginning_of_day..campaign.end_date.end_of_day).count
            this_exportable_fields << booked_leads_count
            if leads_count > 0
              cost_per_lead = Utility.to_words(campaign.budget/leads_count)
            else
              cost_per_lead = 'N/A'
            end
            this_exportable_fields << cost_per_lead
            visit_leads_count = visted_data.where(source_id: campaign.source_id, created_at: campaign.start_date.beginning_of_day..campaign.end_date.end_of_day).count
            this_exportable_fields << visit_leads_count
            if visit_leads_count > 0
              cost_per_visit = Utility.to_words(campaign.budget/visit_leads_count)
            else
              cost_per_visit = "N/a"
            end
            this_exportable_fields << cost_per_visit
            if booked_leads_count > 0
              cost_per_book = Utility.to_words(campaign.budget/booked_leads_count)
            else
              cost_per_book = 'N/A'
            end
            this_exportable_fields << cost_per_book
            csv << this_exportable_fields
          end
        end
      end

      def visits_to_csv(options={}, data, user)
        statuses = user.company.statuses.where(:id=>data.map(&:status_id).uniq)
        @manageable_ids = user.manageables.ids
        @data = data.as_json.group_by{ |t| t["user_id"] }

        CSV.generate do |csv|
          exportable_fields = ['User', 'Total']
          statuses.each do |status|
            exportable_fields << status.name
          end
          csv << exportable_fields
          @data.each do |user_id, data|
            if @manageable_ids.include?(user_id) && data.present?
              user_total = data.map{|k| k["lead_ids"].uniq.count}.sum
              this_exportable_fields = [data.first&.dig("user_name"), user_total]
              statuses.each do |status|
                this_status_data = data.select { |t| t["status_id"] == status.id }
                this_exportable_fields << this_status_data.map{|k| k["lead_ids"].uniq.count}.sum
              end
            end
            csv << this_exportable_fields
          end
        end
      end

      def source_visits_to_csv(options={}, data, user)
        statuses = user.company.statuses.where(:id=>data.map(&:status_id).uniq)
        @manageable_ids = user.manageables.ids
        @sources = user.company.sources.where(:id=>data.map(&:source_id).uniq)
        @source_ids=@sources.ids
        @data = data.as_json.group_by{ |t| t["source_id"] }

        CSV.generate do |csv|
          exportable_fields = ['Source', 'Total']
          statuses.each do |status|
            exportable_fields << status.name
          end
          csv << exportable_fields
          @data.each do |source_id, data|
            if @source_ids.include?(source_id) && data.present?
              source_total = data.map{|k| k["lead_ids"].uniq.count}.sum
              this_exportable_fields = [data.first&.dig("source_name"), source_total]
              statuses.each do |status|
                this_status_data = data.select { |t| t["status_id"] == status.id }
                this_exportable_fields << this_status_data.map{|k| k["lead_ids"].uniq.count}.sum
              end
            end
            csv << this_exportable_fields
          end
        end
      end

      def activity_to_csv(options={}, user, start_date, end_date)
        activities = user.company.associated_audits.where(:created_at=>start_date..end_date)
        unless user.is_super?
          activities = activities.where(:user_id=>user.manageable_ids, :user_type=>"User")
        end
        lead_ids = activities.pluck(:auditable_id)
        leads = user.manageable_leads.where(:id=>lead_ids.uniq)
        activities = activities.where(:auditable_id=>leads.ids.uniq)
        status_edits = activities.where("audits.audited_changes ->> 'status_id' != ''").group("user_id").select("user_id, json_agg(audited_changes) as change_list")
        comment_edits = activities.where("audits.audited_changes ->> 'comment' != ''").group("user_id").select("user_id, json_agg(audited_changes) as change_list")
        unique_activities = activities.select("DISTINCT ON (audits.auditable_id) audits.* ")
        users = user.manageables.where(:id=>(status_edits.map(&:user_id).uniq | comment_edits.map(&:user_id).uniq))
        status_edits = status_edits.as_json
        comment_edits = comment_edits.as_json
        CSV.generate do |csv|
          exportable_fields = ['User', 'Total Edits', 'Status Edits', 'Comment Edits', 'Unique Leads Edits']
          csv << exportable_fields
          users.each do |user|
            comment_edit = comment_edits.detect{|k| k["user_id"] == user.id}
            status_edit = status_edits.detect{|k| k["user_id"] == user.id}
            uniq_leads_edits = (unique_activities.where(user_id: user.id).map(&:auditable_id).count rescue 0)
            comment_edits_total = (comment_edit["change_list"].count rescue 0)
            status_edits_total = (status_edit["change_list"].count rescue 0)
            total_edits = comment_edits_total + status_edits_total
            this_exportable_fields = [user.name, total_edits, status_edits_total, comment_edits_total, uniq_leads_edits]
            csv << this_exportable_fields
          end
        end
      end

      def activity_details_to_csv(activities, user, helpers)
        CSV.generate(headers: true) do |csv|
          headers = ["Date", "Lead No", "Status Edits", "Comment Edits"]
          headers << "Source Edits" if user.company.enable_activity_report_source_logs
          headers << "User Edits" if user.company.enable_activity_report_user_logs
          csv << headers

          activities.each do |activity|
            status_edits =  helpers.status_edit_html(activity.audited_changes["status_id"], true)
            comment_edits = helpers.comment_edit_text(activity.audited_changes["comment"])
            source_edits = helpers.source_edit_html(activity.audited_changes["source_id"], true)
            user_edits = helpers.user_edit_html(activity.audited_changes["user_id"], true)
            row = [
              activity.created_at.strftime("%d-%m-%y %H:%M %p"),
              activity.auditable.try(:lead_no) || '-',
              status_edits,
              comment_edits
            ]
            row << source_edits if user.company.enable_activity_report_source_logs
            row << user_edits if user.company.enable_activity_report_user_logs
            csv << row
          end
        end
      end

      def source_report_to_csv(options={}, user)
        data = all.group("source_id, status_id").select("COUNT(*), source_id, status_id, json_agg(leads.id) as lead_ids")
        @data = data.as_json(except: [:id])
        sources = user.company.sources.where(:id=>data.map(&:source_id).uniq)
        statuses = user.company.statuses.where(:id=>data.map(&:status_id).uniq)
        CSV.generate do |csv|
          exportable_fields = ['Source', 'Total']
          statuses.each do |status|
            exportable_fields << status.name
          end
          csv << exportable_fields
          sources.each do |source|
            this_source_data = @data.select{|k| k["source_id"] == source.id}
            if this_source_data.present?
              source_total = (this_source_data.map{|k| k["lead_ids"].count}.sum rescue nil)
              this_exportable_fields = [source.name, source_total]
              statuses.each do |status|
                this_status_data = this_source_data.detect{|k| k["status_id"] == status.id}
                this_exportable_fields << (this_status_data["lead_ids"].count rescue nil)
              end
            end
            csv << this_exportable_fields
          end
        end
      end

      def backlog_report_to_csv(options={}, user)
        company = user.company
        leads = all.backlogs_for(company)
        data = leads.group("user_id, status_id").select("COUNT(*), user_id, status_id, json_agg(leads.id) as lead_ids")
        statuses = user.company.statuses.where(:id=>data.map(&:status_id).uniq)
        users = user.manageables.where(:id=>data.map(&:user_id).uniq)
        @data = data.as_json
        CSV.generate do |csv|
          exportable_fields = ['User', 'Total']
          statuses.each do |status|
            exportable_fields << status.name
          end
          csv << exportable_fields
          users.each do |user|
            this_user_data = @data.select{|k| k["user_id"] == user.id}
            user_total = (this_user_data.map{|k| k["lead_ids"].count}.sum rescue 0)
            this_exportable_fields = [user.name, user_total]
            statuses.each do |status|
              this_status_data = this_user_data.detect{|k| k["status_id"] == status.id}
              this_exportable_fields << (this_status_data["lead_ids"].count rescue 0)
            end
            puts this_exportable_fields
            csv << this_exportable_fields
          end
        end
      end

      def closing_executive_backlog_report_to_csv(options={}, user)
        company = user.company
        leads = all.backlogs_for(company)
        data = leads.where.not(closing_executive: nil).group("closing_executive, status_id").select("COUNT(*), closing_executive as user_id, status_id, json_agg(leads.id) as lead_ids")
        statuses = user.company.statuses.where(:id=>data.map(&:status_id).uniq)
        users = user.manageables.where(:id=>data.map(&:user_id).uniq)
        @data = data.as_json
        CSV.generate do |csv|
          exportable_fields = ['User', 'Total']
          statuses.each do |status|
            exportable_fields << status.name
          end
          csv << exportable_fields
          users.each do |user|
            this_user_data = @data.select{|k| k["user_id"] == user.id}
            user_total = (this_user_data.map{|k| k["lead_ids"].count}.sum rescue 0)
            this_exportable_fields = [user.name, user_total]
            statuses.each do |status|
              this_status_data = this_user_data.detect{|k| k["status_id"] == status.id}
              this_exportable_fields << (this_status_data["lead_ids"].count rescue 0)
            end
            csv << this_exportable_fields
          end
        end
      end

      def project_report_to_csv(options={}, user)
        data = all.group("project_id, status_id").select("COUNT(*), project_id, status_id, json_agg(leads.id) as lead_ids")
        uniq_projects = all.map{|k| k[:project_id]}.uniq
        uniq_statuses = all.map{|k| k[:status_id]}.uniq
        projects = user.company.projects.where(:id=>uniq_projects)
        statuses = user.company.statuses.where(:id=>uniq_statuses)
        @data = data.as_json(except: [:id])
        CSV.generate do |csv|
          exportable_fields = ['Project', 'Total']
          statuses.each do |status|
            exportable_fields << status.name
          end
          csv << exportable_fields
          projects.each do |project|
            this_project_data = @data.select{|k| k["project_id"] == project.id}
            if this_project_data.present?
              project_total = (this_project_data.map{|k| k["lead_ids"].count}.sum rescue nil)
              this_exportable_fields = [project.name, project_total]
              statuses.each do |status|
                this_status_data = this_project_data.detect{|k| k["status_id"] == status.id}
                this_exportable_fields << (this_status_data["lead_ids"].count rescue nil)
              end
            end
            csv << this_exportable_fields
          end
        end
      end

      def source_inactive_report_to_csv(options={}, user)
        leads = all.where(:status_id=>user.company.dead_status_ids)
        reasons = user.company.reasons.where(:id=>leads.map(&:dead_reason_id).uniq)
        @sources=user.company.sources.where(id: leads.map(&:source_id).uniq)
        CSV.generate do |csv|
          exportable_fields = ['Source', 'Total']
          reasons.each do |reason|
            exportable_fields << reason.reason
          end
          csv << exportable_fields
          @sources.each do |source|
            this_source_data = leads.where(:source_id=>source.id)
            source_total = this_source_data.count
            this_exportable_fields = [source.name, source_total]
            reasons.each do |reason|
              this_reason_data = this_source_data.where(:dead_reason_id=>reason.id)
              this_exportable_fields << this_reason_data.count
            end
            csv << this_exportable_fields
          end
        end
      end

      def source_inactive_report_to_csv_optimized(options={}, user)
        # Optimized: Single query with aggregation
        aggregated_data = all.where(:status_id=>user.company.dead_status_ids)
                             .joins(:source, :dead_reason)
                             .group('sources.name, sources.id, dead_reason_id, reasons.reason')
                             .count
        
        # Group by source for easier processing
        source_groups = aggregated_data.group_by { |(source_name, source_id, reason_id, reason_name), count| [source_name, source_id] }
        
        # Get all unique reasons for consistent CSV structure
        all_reasons = user.company.reasons.where(id: aggregated_data.keys.map { |k| k[2] }.uniq).pluck(:id, :reason).to_h
        
        CSV.generate do |csv|
          # Header row
          exportable_fields = ['Source', 'Total']
          all_reasons.values.each { |reason| exportable_fields << reason }
          csv << exportable_fields
          
          # Data rows
          source_groups.each do |(source_name, source_id), source_data|
            source_total = source_data.values.sum
            this_exportable_fields = [source_name, source_total]
            
            all_reasons.each do |reason_id, reason_name|
              count = source_data.select { |(_, _, rid, _), _| rid == reason_id }.values.sum
              this_exportable_fields << count
            end
            
            csv << this_exportable_fields
          end
        end
      end

      def dead_report_to_csv(options={}, user)
        leads = all.where(:status_id=>user.company.dead_status_ids)
        reasons = user.company.reasons.where(:id=>leads.map(&:dead_reason_id).uniq)
        users = user.manageables.where(:id=>leads.map(&:user_id).uniq)
        CSV.generate do |csv|
          exportable_fields = ['User', 'Total']
          reasons.each do |reason|
            exportable_fields << reason.reason
          end
          csv << exportable_fields
          users.each do |user|
            this_user_data = leads.where(:user_id=>user.id)
            user_total = this_user_data.count
            this_exportable_fields = [user.name, user_total]
            reasons.each do |reason|
              this_reason_data = this_user_data.where(:dead_reason_id=>reason.id)
              this_exportable_fields << this_reason_data.count
            end
            csv << this_exportable_fields
          end
        end
      end

      def cp_report_to_csv(options={},user)
        data=all.where.not(broker_id: nil).where("source_id IN (?)", user.company.cp_sources&.ids).group("broker_id, status_id").select("COUNT(*), broker_id, status_id, json_agg(leads.id) as lead_ids")
        @data = data.as_json(except: [:id])
        brokers = user.company.brokers.where(:id=>data.map(&:broker_id).uniq)
        statuses = user.company.statuses.where(:id=>data.map(&:status_id).uniq)
        CSV.generate(**options) do |csv|
          exportable_fields = ['Source', 'Total']
          statuses.each do |status|
            exportable_fields << status.name
          end
          csv << exportable_fields
          brokers.each do |broker|
            this_broker_data = @data.select{|k| k["broker_id"] == broker.id}
            if this_broker_data.present?
              broker_total = (this_broker_data.map{|k| k["lead_ids"].count}.sum rescue 0)
              this_exportable_fields = [broker.name, broker_total]
              statuses.each do |status|
                this_status_data = this_broker_data.detect{|k| k["status_id"] == status.id}
                this_exportable_fields << (this_status_data["lead_ids"].count rescue 0)
              end
            end
            csv << this_exportable_fields
          end
        end
      end

      def gre_source_report_to_csv(options={}, user)
        data = all.joins(:visits).group("source_id, leads.status_id").select("COUNT(*), source_id, leads.status_id, json_agg(leads.id) as lead_ids")
        @data = data.as_json(except: [:id])
        sources = user.company.sources.where(:id=>data.map(&:source_id).uniq)
        statuses = user.company.statuses.where(:id=>data.map(&:status_id).uniq)
        CSV.generate do |csv|
          exportable_fields = ['Source', 'Total']
          statuses.each do |status|
            exportable_fields << status.name
          end
          csv << exportable_fields
          sources.each do |source|
            this_source_data = @data.select{|k| k["source_id"] == source.id}
            if this_source_data.present?
              source_total = (this_source_data.map{|k| k["lead_ids"].uniq.count}.sum rescue 0)
              this_exportable_fields = [source.name, source_total]
              statuses.each do |status|
                this_status_data = this_source_data.detect{|k| k["status_id"] == status.id}
                this_exportable_fields << (this_status_data["lead_ids"].uniq.count rescue 0)
              end
            end
            csv << this_exportable_fields
          end
        end
      end

      def closing_executive_to_csv(options = {},user)
        data = all.group("closing_executive, status_id").select("COUNT(*), closing_executive, status_id, json_agg(leads.id) as lead_ids")
        @data = data.as_json
        users = user.manageables.where(:id=>data.map(&:closing_executive).uniq)
        statuses = user.company.statuses.where(:id=>data.map(&:status_id).uniq)
        CSV.generate do |csv|
          exportable_fields = ['User Name', 'User Role', 'Total Count' ]
          statuses.each do |status|
            exportable_fields << status.name
          end
          csv << exportable_fields
          users.each do |user|
            this_user_data = @data.select{|k| k["closing_executive"] == user.id}
            if this_user_data.present?
              user_total = (this_user_data.map{|k| k["lead_ids"].count}.sum rescue nil)
              this_exportable_fields = [user.name, user.role.name, user_total]
              statuses.each do |status|
                this_status_data = this_user_data.detect{|k| k["status_id"] == status.id}
                this_exportable_fields << (this_status_data["lead_ids"].count rescue nil)
              end
            end
            csv << this_exportable_fields
          end
        end
      end
      
      def calls_report_to_csv(options = {}, user, start_date, end_date)
        # Use the already filtered data from controller instead of re-filtering
        # Fix ambiguous user_id reference by specifying table name
        data = all.includes(:user).where("leads_call_logs.user_id IN (?) AND leads_call_logs.created_at BETWEEN ? AND ?", user.manageables.ids, start_date, end_date)
        
        # Get unique user IDs efficiently
        user_ids = data.distinct.pluck(:user_id)
        users_map = user.manageables.where(id: user_ids).index_by(&:id)
        
        # Pre-calculate all statistics using SQL aggregation to avoid N+1 queries
        # Group by user_id and calculate counts for each status type
        total_counts = data.group(:user_id).count
        
        # Calculate completed calls per user
        completed_counts = data
          .where("leads_call_logs.other_data->>'status' IN (?)", ['completed', 'ANSWER', 'Call Complete', 'answered'])
          .group(:user_id)
          .count
        
        # Calculate missed calls per user
        missed_counts = data
          .where("leads_call_logs.other_data->>'status' IN (?)", ['no-answer', 'Missed', 'NOANSWER', 'busy', 'noans', 'client-hangup', 'canceled'])
          .group(:user_id)
          .count
        
        # Calculate abandoned calls per user
        abandoned_counts = data
          .where("leads_call_logs.other_data->>'status' IN (?)", ['CANCEL', 'failed', 'Executive Busy', 'Originate', 'Customer Busy', 'CONNECTING', 'BUSY'])
          .group(:user_id)
          .count
        
        # Calculate duration statistics per user using SQL aggregation
        duration_stats = data
          .group(:user_id)
          .pluck(
            Arel.sql('leads_call_logs.user_id'),
            Arel.sql('AVG(CAST(duration AS INTEGER))'),
            Arel.sql('SUM(CAST(duration AS INTEGER))')
          )
          .to_h { |user_id, avg, sum| [user_id, { avg: avg&.round(2) || 0, sum: sum || 0 }] }

        CSV.generate do |csv|
          exportable_fields = ["User", "Total Calls", "Completed", "Missed", "Abondoned", "Avg. Talk Time", "Total Talk Time"]
          csv << exportable_fields
          
          user_ids.each do |user_id|
            user_obj = users_map[user_id]
            next unless user_obj
            
            total_count = total_counts[user_id] || 0
            completed_calls = completed_counts[user_id] || 0
            missed_calls = missed_counts[user_id] || 0
            abandoned_calls = abandoned_counts[user_id] || 0
            
            avg_talk_time = duration_stats.dig(user_id, :avg) || 0
            total_talk_time = duration_stats.dig(user_id, :sum) || 0
            
            this_exportable_fields = [
              user_obj.name, 
              total_count, 
              completed_calls, 
              missed_calls, 
              abandoned_calls,
              avg_talk_time,
              total_talk_time
            ]
            
            csv << this_exportable_fields
          end
        end
      end
    end

  end
end