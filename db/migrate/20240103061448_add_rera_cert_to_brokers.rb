class AddReraCertToBrokers < ActiveRecord::Migration[7.1]
  def change
    # Active Storage handles file attachments automatically
    # add_attachment :brokers, :rera_document
  end
end
