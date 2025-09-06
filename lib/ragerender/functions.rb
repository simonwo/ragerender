require 'cgi'
require 'json'

# Include this module to get ComicFury intrinsic functions available in
# templates.
module RageRender
  module TemplateFunctions
    def js str
      JSON.generate(str, script_safe: true, ascii_only: true).gsub(/[<>'&]|\\"/) do |m|
        '\u' + sprintf('%04x', m.chars.last.ord).upcase
      end
    end

    def randomnumber a, b
      rand a.to_i..b.to_i
    end

    # Unescape all HTML entities in the input
    def rawhtml str
      CGI.unescape_html str
    end

    # https://github.com/Shopify/liquid/blob/9bb7fbf123e6e2bd61e00189b1c83159f375d3f3/lib/liquid/standardfilters.rb#L24-L29
    # Used under the MIT License.
    STRIP_HTML_BLOCKS = Regexp.union(
      %r{<script.*?</script>}m,
      /<!--.*?-->/m,
      %r{<style.*?</style>}m,
    )
    STRIP_HTML_TAGS = /<.*?>/m

    # This is only used for ERB – for Liquid, we use the native `strip_html`
    # This pretty much mirrors the Liquid implementation.
    def removehtmltags str
      str.gsub(STRIP_HTML_BLOCKS, '').gsub(STRIP_HTML_TAGS, '')
    end
  end
end
