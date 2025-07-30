class AddIndexesToLeadsFields < ActiveRecord::Migration
  disable_ddl_transaction!
  def change
    add_index :leads, :company_id, algorithm: :concurrently
    add_index :leads, :source_id, algorithm: :concurrently
    add_index :leads, :project_id, algorithm: :concurrently
    add_index :leads, :user_id, algorithm: :concurrently
    add_index :leads, :closing_executive, algorithm: :concurrently
    add_index :leads, :is_deactivated, algorithm: :concurrently
  end
end
