class AddSignatureToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :signature, :binary
  end
end
