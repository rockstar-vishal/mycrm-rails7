class Email < ActiveRecord::Base

  validates :subject, presence: true

  belongs_to :sender, polymorphic: true
  belongs_to :receiver, polymorphic: true

  after_commit :send_email, on: :create


  def send_email
    if event_type.present?
      Resque.enqueue(event_type.constantize, self.id)
    else
      Resque.enqueue(ProcessEmail, self.id)
    end
  end

end
