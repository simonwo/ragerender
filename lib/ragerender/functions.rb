require 'cgi'

# Include this module to get ComicFury intrinsic functions available in
# templates.
module RageRender
  module TemplateFunctions
    def js str
      '"' + CGI.escape_html(str) + '"'
    end

    def random a, b
      rand a..b
    end
  end
end
