class ExportLog < ActiveRecord::Base
  belongs_to :company
  belongs_to :user
  validates :count, presence: true

  after_commit :process_export_log, on: :create

  def process_export_log
    if self.target_type.present?
      file_export = self.user.file_exports.create(
        company_id: self.company_id,
        file_name: "#{Time.zone.now.to_i}_Lead"
      )

      Resque.enqueue("Process#{self.target_type.capitalize}Export".constantize, self.id, file_export.id)
    end
  end
end
