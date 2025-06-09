require 'etc'
require 'stringio'
require 'jekyll'
require 'dimensions'
require_relative 'language'
require_relative 'to_liquid'
require_relative 'date_formats'
require_relative 'jekyll/archive'
require_relative 'jekyll/blog'
require_relative 'jekyll/blog_archive'
require_relative 'jekyll/comics'
require_relative 'jekyll/chapter'
require_relative 'jekyll/overview'
require_relative 'jekyll/error'
require_relative 'jekyll/search'
require_relative 'jekyll/named_data_delegator'
require_relative 'jekyll/setup_collection'

Jekyll::Hooks.register :site, :after_init do |site|
  # This is obviously quite naughty for many reasons,
  # but it's the only way to get the theme selected
  # without requiring the user to write a config file
  site.config['theme'] ||= 'ragerender'
  site.config['title'] ||= File.basename(site.source)
  site.config['search'] ||= true
  site.config = site.config

  setup_collection site, :comics, '/:collection/:slug/', layout: 'comic-page', chapter: '0'
  setup_collection site, :posts, '/blogarchive/:slug/', layout: 'blog-display'

  site.config['defaults'].push({
    'scope' => {
      'path' => '',
    },
    'values' => {
      'author' => Etc.getlogin,
    }
  })
end

Jekyll::Hooks.register :site, :post_read do |site|
  site.layouts.each do |(name, layout)|
    layout.data['layout'] = 'overall' unless name == 'overall'
    layout.content = RageRender.to_liquid(RageRender::Language.parse(StringIO.new(layout.content))).join
  end
end

# The index for the site can be set by configuration
class RageRender::FrontpageGenerator < Jekyll::Generator
  priority :lowest

  def generate site
    comics = site.collections['comics']
    frontpage = site.config.fetch('frontpage', 'latest')
    index = case frontpage
    when 'latest'
      collection = site.collections['comics'].docs
      comics.docs.last
    when 'first'
      collection = site.collections['comics'].docs
      comics.docs.first
    when 'chapter'
      collection = site.collections['comics'].docs
      chapter = comics.docs.last.data['chapter']
      comics.docs.detect {|c| c.data['chapter'] == chapter }
    when 'overview'
      collection = site.pages
      site.pages.detect {|p| p.data["permalink"] == '/overview/index.html' }
    else
      collection = site.pages
      site.pages.detect {|p| p.data["slug"] == frontpage }
    end.dup
    index.instance_variable_set(:"@destination", {site.dest => File.join(site.dest, 'index.html')})
    index.instance_variable_set(:"@data", index.data.dup)
    index.data['slug'] = 'frontpage'
    collection << index
  end
end

Jekyll::Hooks.register :documents, :pre_render do |doc, payload|
  payload.merge! RageRender::WebcomicDrop.new(doc).to_liquid
end

Jekyll::Hooks.register :pages, :pre_render do |page, payload|
  payload.merge! RageRender::WebcomicDrop.new(page).to_liquid
end

class RageRender::WebcomicDrop < Jekyll::Drops::Drop
  extend Forwardable
  extend RageRender::NamedDataDelegator

  def self.def_config_delegator source, target
    define_method(target) { @obj.site.config[source.to_s] }
  end

  def_config_delegator :title, :webcomicname
  def_config_delegator :description, :webcomicslogan
  def_config_delegator :search, :searchon
  %w{bannerads allowratings showpermalinks showcomments allowcomments}.each do |var|
    def_config_delegator var, var
  end

  def webcomicurl
    @obj.site.baseurl
  end

  def lastupdatedmy
    Time.now.strftime('%d/%m/%Y')
  end

  def copyrights
    @obj.site.config['copyrights'].gsub('[year]', Date.today.year.to_s)
  end

  def banner
    Pathname.new(@obj.site.baseurl || '/').join(@obj.site.config['banner'] || '').to_path
  end

  def webcomicavatar
    Pathname.new(@obj.site.baseurl || '/').join(@obj.site.config['webcomicavatar'] || '').to_path
  end

  def hasblogs
    @obj.site.posts.docs.any?
  end

  def hidefromhost
    false
  end

  def extrapages
    @obj.site.pages.reject {|page| page.data['hidden'] }.map do |page|
      {'link' => page.url, 'title' => page.data['title']}
    end
  end

  def cfscriptcode
    <<~HTML
      <script type="text/javascript">
        function jumpTo(place) { window.location = place; }
      </script>
    HTML
  end

  def css
    css_files = @obj.site.static_files.select {|f| f.extname == '.css'}.map(&:path).to_a
    css_files << Pathname.new(@obj.site.theme.includes_path).join('layout.css') unless css_files.any?
    css_files.map {|f| File.read f }.join
  end

  delegate_method_as :url, :permalink
  def_data_delegator :title, :pagetitle

  def iscomicpage
    @obj.type == :comics
  end

  def isextrapage
    @obj.type == :pages && @obj.data['hidden'] != true
  end

  def fallback_data
    {}
  end
end
