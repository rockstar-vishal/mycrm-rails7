class ServiceApiLog < ActiveRecord::Base
  enum entry_type:{
    "knowlarities": 1,
    "tatateleservice": 2,
    "slashrtcservice": 3,
    "twispire": 4,
    "teleteemtech": 5
  }
end
