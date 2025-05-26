require 'etc'
require 'stringio'
require 'jekyll'
require 'dimensions'
require_relative 'language'
require_relative 'to_liquid'
require_relative 'jekyll/blog_archive'

# E.g. 20th Nov 2024, 2:35 PM
SUFFIXES = {1 => 'st', 2 => 'nd', 3 => 'rd'}
def comicfury_date time
  fmt = "%-d#{SUFFIXES.fetch(time.day, 'th')} %b %Y, %-I:%M %p"
  time.strftime(fmt)
end

def default_image_path comic
  "images/#{comic.data['slug']}.jpg"
end

Jekyll::Hooks.register :site, :after_init do |site|
  site.config['title'] ||= File.basename(site.source)
  site.config['collections']['comics'] = {
    'output' => true,
    'permalink' => '/:collection/:slug.html'
  }
  site.config['collections']['posts'] = {
    'output' => true,
    'permalink' => '/blogarchive/:slug.html'
  }

  site.config['defaults'].prepend({
    'scope' => {
      'path' => '',
    },
    'values' => {
      'author' => Etc.getlogin,
    }
  })

  site.config['defaults'].prepend({
    'scope' => {
      'path' => '',
      'type' => 'comics',
    },
    'values' => {
      'layout' => 'comic-page',
    },
  })

  site.config['defaults'].prepend({
    'scope' => {
      'path' => '',
      'type' => 'posts',
    },
    'values' => {
      'layout' => 'blog-display',
    }
  })
end

Jekyll::Hooks.register :site, :post_read do |site|
  site.layouts.each do |(name, layout)|
    layout.data['layout'] = 'overall' unless name == 'overall'
    layout.content = RageRender.to_liquid(RageRender::Language.parse(StringIO.new(layout.content))).join
  end
end

SPECIAL_COMIC_SLUGS = %w{frontpage index}

# The index for the site can be set by configuration
Jekyll::Hooks.register :site, :post_read do |site|
  comics = site.collections['comics']
  frontpage = site.config.fetch('frontpage', 'latest')
  index = case frontpage
  when 'latest'
    comics.docs.last
  when 'first'
    comics.docs.first
  when 'chapter'
    chapter = comics.docs.last.data['chapter']
    comics.docs.detect {|c| c.data['chapter'] == chapter }
  else
    site.pages.detect {|p| p.data["slug"] == frontpage }
  end.dup
  index.instance_variable_set(:"@destination", {site.dest => File.join(site.dest, 'index.html')})
  index.instance_variable_set(:"@data", index.data.dup)
  index.data['image'] ||= default_image_path(index)
  index.data['slug'] = 'frontpage'
  comics.docs << index
end

# The index for the comics collection is always the latest comic
Jekyll::Hooks.register :site, :post_read do |site|
  comics = site.collections['comics']
  index = comics.docs.last.dup
  index.remove_instance_variable(:"@destination")
  index.instance_variable_set(:"@data", index.data.dup)
  index.data['image'] ||= default_image_path(index)
  index.data['slug'] = 'index'
  comics.docs << index
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
  payload['banner'] = (site.baseurl || '') + site.config['banner']
  payload['webcomicavatar'] = (site.baseurl || '') + site.config['webcomicavatar']
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

Jekyll::Hooks.register :comics, :pre_render do |comic, payload|
  all_comics = comic.collection.docs.reject {|c| SPECIAL_COMIC_SLUGS.include? c.data['slug'] }
  payload['comicid'] = "#{comic.data['slug']}-#{comic.date.strftime('%s')}",
  payload['comictitle'] = comic.data['title']
  payload['usechapters'] = all_comics.any? do |c|
    c.data.include? 'chapter'
  end
  payload['haschapter'] = comic.data.include?('chapter')
  payload['chaptername'] = comic.data['chapter']

  payload['dropdown'] = all_comics.reduce([]) do |dropdown, c|
    new_group = dropdown.last.nil? ? true : dropdown.last['grouplabel'] != c.data['chapter']
    if new_group && !dropdown.last.nil? && dropdown.last['title'] == c.data['chapter']
      dropdown.last['endgroup'] = true
    end

    in_this_chapter = comic.data['chapter'] == c.data['chapter']
    if in_this_chapter
      dropdown << {
        'is_selected' => comic == c,
        'is_disabled' => false,
        'title' => c.data['title'],
        'grouplabel' => c.data['chapter'],
        'newgroup' => new_group,
        'endgroup' => false,
        'url' => c.url,
      }
    elsif new_group
      dropdown << {
        'is_selected' => false,
        'is_disabled' => false,
        'title' => c.data['chapter'],
        'grouplabel' => c.data['chapter'],
        'newgroup' => false,
        'endgroup' => false,
        'url' => c.url, # navigating to chapter just goes to first page
      }
    end

    dropdown
  end

  payload['authornotes'] = comic.data['authornotes'] || [{
    'is_reply' => false,
    'comment' => comic.content,
    'isguest' => false,
    'avatar' => nil,
    'authorname' => comic.data['author'],
    'commentanchor' => "comment-#{comic.date.strftime('%s')}",
    'posttime' => comicfury_date(comic.date),
    'profilelink' => nil, # TODO
  }]

  payload['custom'] = (comic.data['custom'] || {}).reject {|k, v| v.nil? }.reject {|k, v| v.respond_to?(:empty?) && v.empty? }
  payload['isfirstcomic'] = all_comics.first == comic
  payload['islastcomic'] = all_comics.last == comic
  payload['prevcomic'] = payload["isfirstcomic"] ? nil : all_comics.each_cons(2).detect {|prev, this| this == comic }.first.url
  payload['nextcomic'] = payload['islastcomic'] ? nil : all_comics.each_cons(2).detect {|this, nexx| this == comic }.last.url

  image_path = comic.data['image'] || default_image_path(comic)
  payload['comicimageurl'] = (comic.site.baseurl || '') + image_path
  payload['comicwidth'] = Dimensions.width(image_path)
  payload['comicheight'] = Dimensions.height(image_path)
  payload['comicimage'] = "<img id=\"comicimage\" src=\"#{payload['comicimageurl']}\" width=\"#{payload['comicwdith']}\" height=\"#{payload['comicheight']}\">"
  if payload['nextcomic']
    payload['comicimage'] = "<a href=\"#{payload['nextcomic']}\">#{payload['comicimage']}</a>"
  end

end
