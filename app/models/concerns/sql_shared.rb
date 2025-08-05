require 'active_support/concern'

module SqlShared
  extend ActiveSupport::Concern

  def leads_visits_combinations(search_params, company_id, user, is_source_wise: false)
    # Start with a base relation and apply common joins
    relation = Lead.joins(:visits)

    # Conditionally apply the user or source join
    if is_source_wise
      relation = relation.joins(:source)
    else
      relation = relation.joins(:user)
    end
    
    # Apply standard WHERE conditions using parameterized queries
    if company_id.present?
      relation = relation.where(company_id: company_id)
    end
    
    if is_source_wise
      relation = relation.where(
        "leads.user_id IN (?) OR leads.closing_executive IN (?)",
        user.manageables.ids,
        user.manageables.ids
      )
    end

    if user.is_marketing_manager?
      relation = relation.where(source_id: user.accessible_sources.ids)
    end
    
    if search_params["is_visit_executed"].present?
      relation = relation.where(visits: { is_visit_executed: search_params["is_visit_executed"] })
    end
    
    # **Corrected date comparison:** Pass Time objects directly
    if search_params["start_date"].present?
      # Use `beginning_of_day` to get a time-zone-aware object
      start_date_time = search_params["start_date"].beginning_of_day
      relation = relation.where("leads_visits.date >= ?", start_date_time)
    end
    
    if search_params["end_time"].present?
      # Use `end_of_day` to get a time-zone-aware object
      end_date_time = search_params["end_time"].end_of_day
      relation = relation.where("leads_visits.date <= ?", end_date_time)
    end
    
    if search_params["customer_type"].present?
      relation = relation.where(customer_type: search_params["customer_type"])
    end
    
    if search_params["project_ids"].present?
      relation = relation.where(project_id: search_params["project_ids"])
    end
    
    if search_params["source_ids"].present?
      relation = relation.where(source_id: search_params["source_ids"])
    end
    
    if search_params["presale_user_id"].present?
      relation = relation.where(presale_user_id: search_params["presale_user_id"])
    end
    
    if search_params["manager_id"].present?
      searchable_users = user.manageables.find_by(id: search_params["manager_id"]).try(:subordinates).try(:ids)
      relation = relation.where(user_id: searchable_users) if searchable_users.present?
    end
    
    if search_params["manager_ids"].present?
      searchable_users = user.manageables.where(id: search_params["manager_ids"])
      subordinate_ids = searchable_users.map { |x| x.subordinates.ids }.flatten.uniq
      relation = relation.where(user_id: subordinate_ids) if subordinate_ids.present?
    end

    # Apply HAVING conditions
    if search_params["visit_counts"].present?
      if search_params["visit_counts"] == "Revisit"
        relation = relation.having("COUNT(leads_visits.id) > 1")
      else
        relation = relation.having("COUNT(leads_visits.id) = 1")
      end
    end

    if search_params["visit_counts_num"].present?
      visit_count_num = search_params["visit_counts_num"].to_i
      relation = relation.having("COUNT(leads_visits.id) > ?", visit_count_num)
    end

    # Conditionally apply SELECT and GROUP BY for old Rails versions
    if is_source_wise
      select_clause = "sources.name as source_name, leads.source_id as source_id, leads.status_id AS status_id, COUNT(leads.id) AS leads_count, json_agg(leads.id) AS lead_ids"
      group_clause = "leads.id, leads.source_id, leads.status_id, sources.name"
    else
      select_clause = "users.name as user_name, leads.user_id as user_id, leads.status_id AS status_id, COUNT(leads.id) AS leads_count, json_agg(leads.id) AS lead_ids"
      group_clause = "leads.id, leads.user_id, leads.status_id, users.name"
    end

    # Apply the final select and group
    relation = relation.select(select_clause).group(group_clause)

    # Execute the query
    relation.to_a
  end
end