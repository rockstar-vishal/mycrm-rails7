class City < ActiveRecord::Base

  default_scope { order(name: :asc) }

  include AppSharable
  include CustomValidations
  has_many :regions, dependent: :destroy
  has_many :localities, through: :regions
  validates :name, presence: true

  validate :unique_name

  def self.basic_search(query)
    cities = City.all
    cities = cities.where('cities.name ILIKE ?',"%#{query}%")
    cities
  end

  class << self
    def to_csv(options = {}, exporting_user, ip_address, cities_count)
      exporting_user.company.export_logs.create(user_id: exporting_user.id, ip_address: ip_address, count: cities_count)
      CSV.generate do |csv|
        exportable_fields = ['S.No','Name']
        csv << exportable_fields
        all.each.with_index(1) do |city, index|
          this_exportable_fields = [index, city.name]
          csv << this_exportable_fields
        end
      end
    end
  end
end
