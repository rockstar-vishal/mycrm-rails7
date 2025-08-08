class AddEventTypeToEmails < ActiveRecord::Migration[7.1]
  def change
    add_column :emails, :event_type, :string
  end
end
