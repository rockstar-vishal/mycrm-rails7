# Fix for Paperclip compatibility with Ruby 3.4
# URI.escape was deprecated and removed in Ruby 3.4
# This monkey patch provides the missing method

require 'uri'

module URI
  class << self
    def escape(s)
      CGI.escape(s.to_s)
    end
  end
end
