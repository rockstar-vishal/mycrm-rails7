class AddCriticalLeadsIndexes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    # Critical composite index for the main leads listing query
    unless index_exists?(:leads, [:company_id, :is_deactivated, :status_id], name: 'index_leads_on_company_deactivated_status')
      add_index :leads, [:company_id, :is_deactivated, :status_id],
                name: 'index_leads_on_company_deactivated_status',
                algorithm: :concurrently
    end

    # Index for user_id and closing_executive filtering
    unless index_exists?(:leads, [:user_id, :company_id, :is_deactivated], name: 'index_leads_on_user_company_deactivated')
      add_index :leads, [:user_id, :company_id, :is_deactivated],
                name: 'index_leads_on_user_company_deactivated',
                algorithm: :concurrently
    end

    # Index for closing_executive filtering
    unless index_exists?(:leads, [:closing_executive, :company_id, :is_deactivated], name: 'index_leads_on_closing_exec_company_deactivated')
      add_index :leads, [:closing_executive, :company_id, :is_deactivated],
                name: 'index_leads_on_closing_exec_company_deactivated',
                algorithm: :concurrently,
                where: 'closing_executive IS NOT NULL'
    end

    # Index for NCD date range queries with company filtering
    unless index_exists?(:leads, [:company_id, :ncd, :is_deactivated], name: 'index_leads_on_company_ncd_deactivated')
      add_index :leads, [:company_id, :ncd, :is_deactivated],
                name: 'index_leads_on_company_ncd_deactivated',
                algorithm: :concurrently
    end

    # Index for ordering (ncd, created_at) with company filtering
    unless index_exists?(:leads, [:company_id, :is_deactivated, :ncd, :created_at], name: 'index_leads_on_company_deactivated_ncd_created')
      add_index :leads, [:company_id, :is_deactivated, :ncd, :created_at],
                name: 'index_leads_on_company_deactivated_ncd_created',
                algorithm: :concurrently
    end
  end

  def down
    remove_index :leads, name: 'index_leads_on_company_deactivated_status' if index_exists?(:leads, name: 'index_leads_on_company_deactivated_status')
    remove_index :leads, name: 'index_leads_on_user_company_deactivated' if index_exists?(:leads, name: 'index_leads_on_user_company_deactivated')
    remove_index :leads, name: 'index_leads_on_closing_exec_company_deactivated' if index_exists?(:leads, name: 'index_leads_on_closing_exec_company_deactivated')
    remove_index :leads, name: 'index_leads_on_company_ncd_deactivated' if index_exists?(:leads, name: 'index_leads_on_company_ncd_deactivated')
    remove_index :leads, name: 'index_leads_on_company_deactivated_ncd_created' if index_exists?(:leads, name: 'index_leads_on_company_deactivated_ncd_created')
  end
end
