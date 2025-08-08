class AddColumnCzentrixcloudEnabledAgentIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :czentrixcloud_enabled, :boolean, default: false
    add_column :users, :agent_id, :string
  end
end
