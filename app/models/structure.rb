class Structure < ActiveRecord::Base
  belongs_to :company
  validates :key, presence: true

  scope :for_sv, -> {where(:key=>"sv")}
  has_many :structure_fields

  has_attached_file :sv_logo, :styles => { :small => "180x180#", :thumb => "70x70#" }
  validates_attachment  :sv_logo, :content_type => { :content_type => %w(image/jpeg image/jpg image/png) }, :size => { :in => 0..1.megabytes }

  accepts_nested_attributes_for :structure_fields, reject_if: :all_blank, allow_destroy: true
end
