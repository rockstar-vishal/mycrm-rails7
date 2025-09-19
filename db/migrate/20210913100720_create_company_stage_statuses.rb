class CreateCompanyStageStatuses < ActiveRecord::Migration[7.1]
  def change
    create_table :company_stage_statuses do |t|
      t.integer :status_id, index: true
      t.integer :company_stage_id, index: true

      t.timestamps
    end
  end
end
