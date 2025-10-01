class AddFunctionalIndexesForLeadUniqueness < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    # Functional index for mobile number uniqueness check
    unless index_exists?(:leads, nil, name: 'index_leads_mobile_last_10_digits')
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_leads_mobile_last_10_digits 
        ON leads (RIGHT(REPLACE(mobile, ' ', ''), 10), company_id, is_deactivated, status_id)
        WHERE mobile IS NOT NULL AND mobile != ''
      SQL
    end

    # Functional index for email uniqueness check
    unless index_exists?(:leads, nil, name: 'index_leads_email_company_deactivated')
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_leads_email_company_deactivated
        ON leads (email, company_id, is_deactivated, status_id)
        WHERE email IS NOT NULL AND email != ''
      SQL
    end

    # Composite index for the main uniqueness query conditions
    unless index_exists?(:leads, [:company_id, :is_deactivated, :status_id], name: 'index_leads_uniqueness_check')
      add_index :leads, [:company_id, :is_deactivated, :status_id],
                name: 'index_leads_uniqueness_check',
                algorithm: :concurrently
    end

    # Index for other_phones field (used in extended uniqueness checks)
    unless index_exists?(:leads, nil, name: 'index_leads_other_phones_last_10')
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_leads_other_phones_last_10
        ON leads (RIGHT(REPLACE(other_phones, ' ', ''), 10), company_id, is_deactivated, status_id)
        WHERE other_phones IS NOT NULL AND other_phones != ''
      SQL
    end

    # Index for source-wise inactive report optimization
    unless index_exists?(:leads, [:status_id, :source_id, :dead_reason_id], name: 'index_leads_status_source_dead_reason')
      add_index :leads, [:status_id, :source_id, :dead_reason_id],
                name: 'index_leads_status_source_dead_reason',
                algorithm: :concurrently
    end
  end

  def down
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_leads_mobile_last_10_digits"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_leads_email_company_deactivated"
    remove_index :leads, name: 'index_leads_uniqueness_check' if index_exists?(:leads, name: 'index_leads_uniqueness_check')
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_leads_other_phones_last_10"
  end
end
