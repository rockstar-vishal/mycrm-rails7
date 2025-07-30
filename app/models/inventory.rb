class Inventory < ActiveRecord::Base

  enum configuration_id: {
    "1BHK": 1,
    "2HK": 2,
    "3BHK": 3,
    "4BHK": 4,
    "2BHK Jodi": 5,
    "2bhk converted to 3bhk": 6,
    "Bare shell": 7,
    "3 bhk furnished": 8,
    "5 bhk + 1": 9
  }


  class << self

    def basic_search(search_string)
      inventories = all
      inventories.where("inventories.developer ILIKE :term OR inventories.development LIKE :term", :term=>"%#{search_string}%")
    end

  end
end
