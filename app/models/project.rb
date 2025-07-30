class Project < ActiveRecord::Base

  include AppSharable

  acts_as_api

  has_many :call_ins, dependent: :restrict_with_error
  has_many :exotel_sids, dependent: :restrict_with_error
  has_many :mcube_sids, dependent: :restrict_with_error
  has_many :fb_forms, class_name: 'Companies::FbForm', dependent: :restrict_with_error
  has_many :projects_fb_forms, class_name: 'Projects::FbForm', dependent: :restrict_with_error
  has_many :users_projects, class_name: 'UsersProject'
  has_many :accessible_users, through: :users_projects, class_name: 'User', source: :user
  has_many :visits_projects, class_name: 'Leads::VisitsProject'
  has_many :fb_ads_ids, class_name: 'FbAdsId'
  belongs_to :company
  belongs_to :city
  belongs_to :country
  has_many :leads, dependent: :restrict_with_error
  has_many :round_robin_settings, class_name: 'RoundRobinSetting'
  validates :name, :company, presence: true

  has_attached_file :project_brochure,
                    path: ":rails_root/public/system/:attachment/:id/:style/:filename",
                    url: "/system/:attachment/:id/:style/:filename"
  validates_attachment :project_brochure, 
                        content_type: { :content_type => %w(image/jpeg image/jpg image/gif image/png application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document) }
  has_attached_file :banner_image,
                        path: ":rails_root/public/system/:attachment/:id/:style/:filename",
                        url: "/system/:attachment/:id/:style/:filename"
  validates_attachment :banner_image, 
                        content_type: { :content_type => %w(image/jpeg image/jpg image/png) }

  scope :active, -> { where(:active=>true) }

  scope :sorted, -> { order("projects.name asc")}

  accepts_nested_attributes_for :fb_ads_ids, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :projects_fb_forms, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :round_robin_settings, reject_if: :all_blank, allow_destroy: true

  api_accessible :details do |template|
    template.add :uuid
    template.add :name
    template.add :address
    template.add :created_at
    template.add :updated_at
  end

  def housing_token=(default_value)
    write_attribute(:housing_token, default_value&.strip)
  end

  def mb_token=(default_value)
    write_attribute(:mb_token, default_value&.strip)
  end

  def nine_token=(default_value)
    write_attribute(:nine_token, default_value&.strip)
  end

  def property_codes=(default_value)
    if default_value.present?
      pc = default_value.map{|val| val.gsub(' ','').split(',')}.flatten
      write_attribute(:property_codes, pc)
    end
  end

  def fb_form_nos=(default_value)
    if default_value.present?
      ffids = default_value.map{|val| val.gsub(' ','').split(',')}.flatten
      write_attribute(:fb_form_nos, ffids)
    end
  end


  class << self

    def basic_search(query)
      projects = Project.includes(:city)
      projects =projects.where("projects.name ILIKE ? OR cities.name ILIKE ?", "%#{query}%", "%#{query}%").references(:city)
      projects
    end
  end

end
