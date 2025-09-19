class CreateCampaignsSpends < ActiveRecord::Migration[7.1]
  def change
    create_table :campaigns_spends do |t|
      t.references :company
      t.references :campaign
      t.float :spend_amount
      t.date :spend_date
      t.timestamps
    end
  end
end
