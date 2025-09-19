class AddColumnsLogoAndFaviconToCompanies < ActiveRecord::Migration[7.1]
  def change
    # These columns are no longer needed with Active Storage
    # Active Storage handles file attachments automatically
    # add_attachment :companies, :logo
    # add_attachment :companies, :favicon
    # add_attachment :companies, :icon
  end
end
