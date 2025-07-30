class Renewal < ActiveRecord::Base

  validates :start_date, :end_date, presence: true

  validate :end_date_is_after_start_date


  private

  def end_date_is_after_start_date
    if end_date < start_date
      errors.add(:end_date, "cannot be before the start date")
    end
  end


end
