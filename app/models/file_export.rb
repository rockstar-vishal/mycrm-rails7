class FileExport < ActiveRecord::Base
  belongs_to :user
  belongs_to :company

  scope :todays, -> {where(created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day)}
  scope :week_file, -> {where(created_at: Time.zone.now-1.week..Time.zone.now.end_of_day)}


  def csv_data
    Base64.decode64(self.data)
  end
end
