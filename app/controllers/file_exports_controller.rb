class FileExportsController < ApplicationController

  before_action :find_file_exports

  def index
    @file_exports = @file_exports.week_file
  end

  def download
    @file_export = @file_exports.find_by(id: params[:file_export_id])
    csv_data = @file_export.csv_data
    send_data csv_data, filename: "#{@file_export.file_name}.csv"
  end


  private

  def find_file_exports
    @file_exports = current_user.file_exports
  end

end