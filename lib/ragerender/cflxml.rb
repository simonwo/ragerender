require 'pathname'
require 'rexml'
require 'base64'

module RageRender
  HTML_FILES = {
    overall: 'overall',
    overview: 'overview',
    viewblog: 'blog-display',
    comic: 'comic-page',
    archive: 'archive',
    blogarchive: 'blog-archive',
    error: 'error-page',
    search: 'search',
  }

  CSS_FILES = {
    layoutcss: 'layout'
  }

  def self.unpack src, html_dest, css_dest
    doc = REXML::Document.new(src).elements
    html_dir = Pathname.new(html_dest)
    css_dir = Pathname.new(css_dest)

    HTML_FILES.each do |(tag, filename)|
      File.write html_dir.join(filename + '.html'), Base64.decode64(doc["/layout/ldata/#{tag.to_s}/text()"].value)
    end

    CSS_FILES.each do |(tag, filename)|
      File.write css_dir.join(filename + '.css'), Base64.decode64(doc["/layout/ldata/#{tag.to_s}/text()"].value)
    end
  end

  def self.pack html_srcdir, css_srcdir, dest
    layout = REXML::Element.new('layout')

    name = REXML::Element.new('name')
    name.text = "Downloaded ComicFury layout"
    layout.add name

    version = REXML::Element.new('cfxml')
    version.text = '1.2'
    layout.add version

    spage = REXML::Element.new('spage')
    spage.text = '1'
    layout.add spage

    ldata = REXML::Element.new('ldata')
    html_dir = Pathname.new(html_srcdir)
    css_dir = Pathname.new(css_srcdir)

    HTML_FILES.each do |(tag, filename)|
      elem = REXML::Element.new tag.to_s
      elem.text = Base64.strict_encode64 File.read html_dir.join(filename + '.html')
      ldata.add elem
    end

    CSS_FILES.each do |(tag, filename)|
      elem = REXML::Element.new tag.to_s
      elem.text = Base64.strict_encode64 File.read css_dir.join(filename + '.css')
      ldata.add elem
    end
    layout.add ldata

    # ComicFury will only accept backup files that have:
    # - A valid XML declaration using double quotes
    # – A comment as per below
    # – Tab indentation
    doc = REXML::Document.new(nil, prologue_quote: :quote)
    doc.add REXML::XMLDecl.new REXML::XMLDecl::DEFAULT_VERSION, REXML::XMLDecl::DEFAULT_ENCODING
    doc.add REXML::Comment.new 'This is a ComicFury layout backup, use the import layout function to restore this to a webcomic site. You can access this as follows: Go to your Webcomic Management, click "Edit Layout", then in the Box labelled "Useful", click "Restore Layout Backup"'
    doc.add layout

    # Pretty print, but *always* make text nodes take up a single line, no
    # matter how long they are
    formatter = REXML::Formatters::Pretty.new(1)
    formatter.compact = true
    formatter.width = Float::INFINITY

    # Replace the space indentation with tab indentation
    buf = StringIO.new
    formatter.write(doc, buf)
    buf.string.each_line do |line|
      dest << line.gsub(/^ +/) {|sp| "\t" * sp.size }
    end
  end
end

if __FILE__ == $0
  case ARGV.shift
  when 'pack'
    html_srcdir, css_srcdir, *dest = ARGV
    RageRender.pack(html_srcdir, css_srcdir, dest.any? ? File.open(dest.first, 'w') : $stdout)
  when 'unpack'
    src, html_dest, css_dest = ARGV
    RageRender.unpack(src == '-' ? $stdin : File.open(src, 'r'), html_dest, css_dest)
  else
    raise <<~USAGE
      Usage: pack html_srcdir css_srcdir dest
      Usage: unpack src html_dest css_dest
    USAGE
  end
end
