class Region < ActiveRecord::Base

  default_scope { order(name: :asc) }

  include CustomValidations

  belongs_to :city
  has_many :localities, dependent: :destroy

  validates :name, :city_id, presence: true

  validate :unique_name

  def self.basic_search(query)
    regions = Region.joins(:city)
    regions = regions.where('regions.name ILIKE ? or cities.name ILIKE ?', "%#{query}%", "%#{query}%")
    regions
  end
end
