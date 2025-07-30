class AddReraCertToBrokers < ActiveRecord::Migration
  def change
    add_attachment :brokers, :rera_document
  end
end
