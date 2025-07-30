class AddSignatureToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :signature, :binary
  end
end
