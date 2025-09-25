class AddPerformanceIndexesForSalesDashboard < ActiveRecord::Migration[7.1]
  def change
    # Index on leads_visits table for lead_id and date - critical for visit date filtering
    # This index speeds up the joins and date filtering in sales_dashboard
    add_index :leads_visits, [:lead_id, :date], 
              name: 'index_leads_visits_on_lead_id_and_date',
              algorithm: :concurrently

    # Index on magic_attributes for lead_id - speeds up magic attribute queries
    # This index helps with the magic attributes loading in sales_dashboard
    add_index :magic_attributes, :lead_id, 
              name: 'index_magic_attributes_on_lead_id',
              algorithm: :concurrently

    # Composite index for company_id, status_id, source_id - for company-scoped queries
    # This index helps with the base query filtering in reports
    add_index :leads, [:company_id, :status_id, :source_id], 
              name: 'index_leads_on_company_status_source',
              algorithm: :concurrently

    # Composite index for user filtering with status and source
    # This index helps with user-specific report filtering
    add_index :leads, [:user_id, :status_id, :source_id], 
              name: 'index_leads_on_user_status_source',
              algorithm: :concurrently

    # Index for closing_executive with status and source for manager reports
    add_index :leads, [:closing_executive, :status_id, :source_id], 
              name: 'index_leads_on_closing_executive_status_source',
              algorithm: :concurrently,
              where: 'closing_executive IS NOT NULL'
  end

  # Disable DDL transactions for concurrent index creation
  disable_ddl_transaction!
end