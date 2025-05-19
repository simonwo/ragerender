require 'stringio'
require 'jekyll'
require 'dimensions'
require_relative 'language'
require_relative 'to_liquid'

# E.g. 20th Nov 2024, 2:35 PM
SUFFIXES = {1 => 'st', 2 => 'nd', 3 => 'rd'}
def comicfury_date time
  fmt = "%-d#{SUFFIXES.fetch(time.day, 'th')} %b %Y, %-I:%M %p"
  time.strftime(fmt)
end

Jekyll::Hooks.register :site, :after_init do |site|
  site.config['collections']['comics'] = {
    'output' => true,
    'permalink' => '/:collection/:slug.html'
  }

  site.config['defaults'] << {
    'scope' => {
      'path' => '',
      'type' => 'comics',
    },
    'values' => {
      'layout' => 'comic-page',
    },
  }
end

Jekyll::Hooks.register :site, :post_read do |site|
  site.layouts.each do |(name, layout)|
    layout.data['layout'] = 'overall' unless name == 'overall'
    layout.content = RageRender.to_liquid(RageRender::Language.parse(StringIO.new(layout.content))).join
  end
end

Jekyll::Hooks.register :comics, :pre_render do |comic, payload|
  %w{bannerads copyrights allowratings showpermalinks showcomments allowcomments}.each do |var|
    payload[var] = comic.site.config[var] || nil
  end
  payload['banner'] = (comic.site.baseurl || '') + comic.site.config['banner']
  payload['webcomicavatar'] = (comic.site.baseurl || '') + comic.site.config['webcomicavatar']
  payload['banneradcode'] = ''
  payload['webcomicname'] = comic.site.config['title']
  payload['webcomicslogan'] = comic.site.config['description']
  payload['hasblogs'] = comic.site.collections['posts'].docs.any?
  payload['hidefromhost'] = false
  payload['extrapages'] = comic.site.pages.map do |page|
    {'link' => page.url, 'title' => page.data['title']}
  end
  payload['cfscriptcode'] = '<script type="text/javascript">function jumpTo(place) { window.location = place; }</script>'

  %w{rating votecount}.each do |var|
    payload[var] = comic.data[var] || nil
  end
  payload['pagetitle'] = comic.data['title']

  payload['iscomicpage'] = comic.collection.label == 'comics'
  payload['isextrapage'] = comic.collection.label != 'comics'
  payload['comicid'] = "#{comic.data['slug']}-#{comic.date.strftime('%s')}",
  payload['webcomicurl'] = comic.site.baseurl
  payload['comictitle'] = comic.data['title']
  payload['usechapters'] = comic.collection.docs.any? do |c|
    c.data.include? 'chapter'
  end
  payload['haschapter'] = comic.data.include?('chapter')
  payload['chaptername'] = comic.data['chapter']
  payload['posttime'] = comicfury_date(comic.date)
  payload['lastupdatedmy'] = Time.now.strftime('%d/%m/%Y')
  payload['permalink'] = comic.url

  payload['dropdown'] = comic.collection.docs.reduce([]) do |dropdown, c|
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

  payload['css'] = comic.site.static_files.select {|f| f.extname == '.css'}.map do |f|
    File.read f.path
  end.join
  payload['custom'] = comic.data['custom'].reject {|(k, v)| v.nil? || v.empty? }
  payload['isfirstcomic'] = comic.collection.docs.first == comic
  payload['islastcomic'] = comic.collection.docs.last == comic
  payload['prevcomic'] = payload["isfirstcomic"] ? nil : comic.collection.docs.map(&:url).each_cons(2).detect {|prev, this| this == comic.url }.first
  payload['nextcomic'] = payload['islastcomic'] ? nil : comic.collection.docs.map(&:url).each_cons(2).detect {|this, nexx| this == comic.url }.last

  image_path = comic.data['image'] || "images/#{comic.data['slug']}.jpg"
  payload['comicimageurl'] = (comic.site.baseurl || '') + image_path
  payload['comicwidth'] = Dimensions.width(image_path)
  payload['comicheight'] = Dimensions.height(image_path)
  payload['comicimage'] = "<img id=\"comicimage\" src=\"#{payload['comicimageurl']}\" width=\"#{payload['comicwdith']}\" height=\"#{payload['comicheight']}\">"
  if payload['nextcomic']
    payload['comicimage'] = "<a href=\"#{payload['nextcomic']}\">#{payload['comicimage']}</a>"
  end

end
