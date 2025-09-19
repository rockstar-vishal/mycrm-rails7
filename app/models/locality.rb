class Locality < ActiveRecord::Base

  default_scope { order(name: :asc) }

  include AppSharable
  include CustomValidations


  belongs_to :region
  validates :name, :region_id, presence: true
  validate :unique_name
  acts_as_api

  api_accessible :details do |t|
    t.add :id
    t.add lambda{|locality| locality.name}, as: :text
    t.add lambda{|locality| locality.region.city.id rescue nil}, as: :city_id
  end

  def self.basic_search(query)
    localities = Locality.joins(:region)
    localities = localities.where('localities.name ILIKE ? or regions.name ILIKE ?', "%#{query}%", "%#{query}%")
    localities
  end

  class << self
    def to_csv(options = {}, exporting_user, ip_address, localities_count)
      exporting_user.company.export_logs.create(user_id: exporting_user.id, ip_address: ip_address, count: localities_count)
      CSV.generate do |csv|
        exportable_fields = ['S.No','Locality Name', "City"]
        csv << exportable_fields
        all.each.with_index(1) do |locality, index|
          this_exportable_fields = [index, locality.name, (locality.region.city.name rescue "")]
          csv << this_exportable_fields
        end
      end
    end
  end

end
