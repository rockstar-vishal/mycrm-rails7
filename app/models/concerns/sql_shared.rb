require 'active_support/concern'

module SqlShared 

  extend ActiveSupport::Concern

  def leads_visits_combinations(search_params, company_id, user, is_source_wise: false)
    conditions = []
    having_conditions = []

    if company_id.present?
      conditions << "leads.company_id = #{company_id}"
    end
    if is_source_wise
      conditions << "(leads.user_id IN (#{user.manageables.ids.join(",")}) OR leads.closing_executive IN (#{user.manageables.ids.join(",")}))"
    end
    if user.is_marketing_manager?
      conditions << "leads.source_id IN (#{user.accessible_sources.ids.join(",")})"
    end
    
    if search_params["is_visit_executed"].present?
      conditions << "leads_visits.is_visit_executed = '#{search_params["is_visit_executed"]}'"
    end
    
    if search_params["start_date"].present?
      start_date = search_params["start_date"].to_date.to_s
      conditions << "leads_visits.date::DATE >= '#{start_date}'"
    end
    
    if search_params["end_time"].present?
      end_date = search_params["end_time"].to_date.to_s
      conditions << "leads_visits.date::DATE <= '#{end_date}'"
    end
    
    if search_params["customer_type"].present?
      conditions << "leads.customer_type = '#{search_params["customer_type"]}'"
    end
    
    if search_params["visit_counts"].present?
      if search_params["visit_counts"] == "Revisit"
        having_conditions << "COUNT(leads_visits.id) > 1"
      else
        having_conditions << "COUNT(leads_visits.id) = 1"
      end
    end

    if search_params["visit_counts_num"].present?
      visit_count_num = search_params["visit_counts_num"].to_i
      having_conditions << "COUNT(leads_visits.id) > '#{visit_count_num}'"
    end
    
    if search_params["project_ids"].present?
      conditions << "leads.project_id IN (#{search_params["project_ids"].join(", ")})"
    end
    
    if search_params["source_ids"].present?
      conditions << "leads.source_id IN (#{search_params["source_ids"].join(", ")})"
    end
    
    if search_params["presale_user_id"].present?
      conditions << "leads.presale_user_id = '#{search_params["presale_user_id"]}'"
    end
    
    if search_params["manager_id"].present?
      searchable_users = user.manageables.find_by(id: search_params["manager_id"]).subordinates.ids
      conditions << (searchable_users.blank? ? "1=0" : "leads.user_id IN (#{searchable_users.join(", ")})")
    end
    
    if search_params["manager_ids"].present?
      searchable_users = user.manageables.where(id: search_params["manager_ids"])
      subordinate_ids = searchable_users.map { |x| x.subordinates.ids }.flatten.uniq
      conditions << (subordinate_ids.blank? ? "1=0" : "leads.user_id IN (#{subordinate_ids.join(", ")})")
    end

    conditions = conditions.blank? ? "" : "WHERE #{conditions.join(' AND ')}"
    having_sql = having_conditions.blank? ? "" : "HAVING #{having_conditions.join(' AND ')}"
    if is_source_wise
      query = <<-SQL
        SELECT sources.name as source_name, leads.source_id as source_id, leads.status_id AS status_id, COUNT(leads.id) AS leads_count, json_agg(leads.id) AS lead_ids
        FROM leads AS leads
        INNER JOIN leads_visits ON leads.id = leads_visits.lead_id
        INNER JOIN sources ON leads.source_id = sources.id
        #{conditions}
        GROUP BY
          leads.id,
          leads.source_id,
          leads.status_id,
          sources.name
        #{having_sql};
      SQL
    else
      query = <<-SQL
        SELECT users.name as user_name, leads.user_id as user_id, leads.status_id AS status_id, COUNT(leads.id) AS leads_count, json_agg(leads.id) AS lead_ids
        FROM leads AS leads
        INNER JOIN leads_visits ON leads.id = leads_visits.lead_id
        INNER JOIN users ON leads.user_id = users.id
        #{conditions}
        GROUP BY
          leads.id,
          leads.user_id,
          leads.status_id,
          users.name
        #{having_sql};
      SQL
    end
    Lead.find_by_sql(query)
  end      
end