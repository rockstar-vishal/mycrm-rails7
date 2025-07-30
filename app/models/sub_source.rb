class SubSource < ActiveRecord::Base
  include AppSharable
  belongs_to :company
  belongs_to :source
end
