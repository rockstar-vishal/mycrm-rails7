class AddEventTypeToEmails < ActiveRecord::Migration
  def change
    add_column :emails, :event_type, :string
  end
end
