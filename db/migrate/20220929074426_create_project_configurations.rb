class CreateProjectConfigurations < ActiveRecord::Migration[7.1]
  def change
    create_table :project_configurations do |t|
      t.integer "company_id"
      t.text    "allowed_fields", default: [], array: true
      t.timestamps
    end
  end
end
