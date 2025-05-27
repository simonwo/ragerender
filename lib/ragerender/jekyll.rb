require 'etc'
require 'stringio'
require 'jekyll'
require 'dimensions'
require_relative 'language'
require_relative 'to_liquid'
require_relative 'date_formats'
require_relative 'jekyll/archive'
require_relative 'jekyll/blog_archive'
require_relative 'jekyll/comics'
require_relative 'jekyll/chapter'
require_relative 'jekyll/overview'

def setup_collection site, label, permalink, **kwargs
  site.config['collections'][label.to_s] = {
    'output' => true,
    'permalink' => permalink,
  }

  site.config['defaults'].prepend({
    'scope' => {
      'path' => '',
      'type' => label.to_s,
    },
    'values' => {
      'permalink' => permalink,
      **kwargs.map do |k, v|
        [k.to_s, v]
      end.to_h,
    },
  })
end

Jekyll::Hooks.register :site, :after_init do |site|
  # This is obviously quite naughty for many reasons,
  # but it's the only way to get the theme selected
  # without requiring the user to write a config file
  site.config['theme'] ||= 'ragerender'
  site.config['title'] ||= File.basename(site.source)
  site.config = site.config

  setup_collection site, :comics, '/:collection/:slug.html', layout: 'comic-page', chapter: '0'
  setup_collection site, :posts, '/blogarchive/:slug.html', layout: 'blog-display'
  setup_collection site, :chapters, '/archive/:slug/', layout: 'archive'

  site.config['defaults'].prepend({
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
class FrontpageGenerator < Jekyll::Generator
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

Jekyll::Hooks.register :posts, :pre_render do |post, payload|
  payload['blogtitle'] = post.data['title']
  payload['authorname'] = post.data['author']
  payload['blog'] = post.content

  site = post.site
  is_first = site.posts.docs.first == post
  is_last = site.posts.docs.last == post
  payload['prevbloglink'] = is_first ? nil : site.posts.docs.each_cons(2).detect {|prev, this| this == post }.first.url
  payload['nextbloglink'] = is_last ? nil : site.posts.docs.each_cons(2).detect {|this, nexx| this == post }.last.url
end

Jekyll::Hooks.register :documents, :pre_render do |doc, payload|
  site = doc.site
  %w{bannerads copyrights allowratings showpermalinks showcomments allowcomments}.each do |var|
    payload[var] = site.config[var] || nil
  end

  payload['webcomicurl'] = site.baseurl
  if site.config['banner']
    payload['banner'] = (site.baseurl || '') + site.config['banner']
  end
  if site.config['webcomicavatar']
    payload['webcomicavatar'] = (site.baseurl || '') + site.config['webcomicavatar']
  end
  payload['banneradcode'] = ''
  payload['webcomicname'] = site.config['title']
  payload['webcomicslogan'] = site.config['description']
  payload['hasblogs'] = site.posts.docs.any?
  payload['hidefromhost'] = false
  payload['extrapages'] = site.pages.reject {|page| page.data['hidden'] }.map do |page|
    {'link' => page.url, 'title' => page.data['title']}
  end
  payload['cfscriptcode'] = '<script type="text/javascript">function jumpTo(place) { window.location = place; }</script>'
  payload['css'] = site.static_files.select {|f| f.extname == '.css'}.map do |f|
    File.read f.path
  end.join

  %w{rating votecount}.each do |var|
    payload[var] = doc.data[var] || nil
  end
  payload['pagetitle'] = doc.data['title']

  payload['posttime'] = comicfury_date(doc.date)
  payload['iscomicpage'] = doc.collection.label == 'comics'
  payload['isextrapage'] = doc.is_a?(Jekyll::Page)
  payload['lastupdatedmy'] = Time.now.strftime('%d/%m/%Y')
  payload['permalink'] = doc.url
end
