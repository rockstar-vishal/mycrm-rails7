module CompanyConstants
  extend ActiveSupport::Concern

  SUBJECTS = {
      'panom' => "DELIGHTED TO HAVE RECEIVED YOUR INTEREST IN - PARLESHWAR AANGAN, VILE PARLE EAST.",
      'ceratec' => "Welcome To Ceratec Group",
      'ravima' => "Welcome To Ravima Venture"
  }.freeze

  VISIT_DONE_SUBJECTS = {
    'panom' => 'THANK YOU FOR VISITING US',
    'ravima' => "Welcome To Ravima Venture"
  }.freeze
end