require 'uri'
require 'liquid/drop'
require 'jekyll/hooks'
require 'jekyll/plugin'
require 'jekyll/generator'
require 'jekyll/document'
require 'jekyll/drops/drop'
require 'jekyll/drops/document_drop'
require_relative '../date_formats'
require_relative 'chapter'
require_relative 'pipettes'

Jekyll::Hooks.register :comics, :pre_render do |page, payload|
  RageRender::Pipettes.clean_payload payload
  payload.merge! RageRender::ComicDrop.new(page).to_liquid
end

module RageRender
  SPECIAL_COMIC_SLUGS = %w{frontpage index}

  BASE_DIR = File.join(File.dirname(__FILE__), '..', '..', '..')

  # Creates comics for each file found in the 'images' directory
  # that does not already have an associated comic object.
  class ComicFromImageGenerator < Jekyll::Generator
    priority :highest

    def generate site
      images = site.static_files.select {|f| f.relative_path.start_with? '/images' }.map {|f| [f.basename, f] }.to_h
      comics = site.collections['comics'].docs.map {|c| [c.basename_without_ext, c] }.to_h
      missing = Set.new(images.keys) - Set.new(comics.keys)
      missing -= Set.new(comics.map {|k, c| c.data['image'] }.reject(&:nil?).map {|img| File.basename(img, '.*') })
      missing.each do |slug|
        comic = Jekyll::Document.new(images[slug].relative_path, site: site, collection: site.collections['comics'])
        comic.send(:merge_defaults)
        comic.data['slug'] = slug
        comic.data['title'] = slug
        comic.data['date'] = images[slug].modified_time
        comic.data['image'] = images[slug].relative_path
        comic.content = nil
        site.collections['comics'].docs << comic
      end
    end
  end

  # The index for the comics collection is always the latest comic.
  class LatestComicGenerator < Jekyll::Generator
    priority :lowest

    def generate site
      comics = site.collections['comics']
      index = comics.docs.last.dup
      collection = comics.docs
      if index.nil?
        index = site.pages.detect {|p| p.data["title"] == "Comic not found" }.dup
        collection = site.pages
      end
      index.instance_variable_set(:"@data", index.data.dup)
      index.data['slug'] = 'index'
      collection << index
    end
  end

  class DefaultImageSetter < Jekyll::Generator
    priority :normal

    def generate site
      site.collections['comics'].docs.each do |comic|
        comic.data['image'] ||= default_image_path(site, comic)
      end
    end

    def images site
      @images ||= site.static_files.select {|f| f.relative_path.start_with? '/images' }.map {|f| [f.basename, f] }.to_h
    end

    def default_image_path site, comic
      images(site)[comic.data['slug']].relative_path
    end
  end

  # If the image for this comic was inside a subdirectory, set that subdirectory
  # name to be the chapter slug for this comic, if one is not already set.
  class ChapterFromDirectorySetter < Jekyll::Generator
    priority :low

    def generate site
      site.collections['comics'].docs.each do |comic|
        components = Pathname.new(comic.data['image']).descend.reduce([]) {|acc, path| acc << path.basename }
        chapter_slug = components.drop_while {|path| path.root? || path.to_s == 'images' }[...-1].first
        comic.data['chapter'] ||= chapter_slug.to_s unless chapter_slug.nil?
      end
    end
  end

  class ComicDrop < Jekyll::Drops::DocumentDrop
    extend Pipettes

    PAGINATION_FIELDS = %w[ comicurl comictitle posttime ]

    delegate_method_as :id, :comicid
    def_delegator :@obj, :url, :comicurl
    def_delegator :@obj, :url, :permalink
    data_delegator 'rating'
    data_delegator 'votecount'

    def comictitle
      escape @obj.data['title']
    end

    def comicdescription
      escape @obj.data['description']
    end

    def transcript
      escape @obj.data['transcript']
    end

    def keywords
      (@obj.data['keywords'] || []).map {|k| escape k }
    end

    def comicnumber
      1 + all_comics.index(@obj)
    end

    def comicsnum
      all_comics.size
    end

    def posttime
      comicfury_date(@obj.date)
    end

    def postyear
      @obj.date.year
    end

    def postmonth
      @obj.date.month
    end

    def usechapters
      all_comics.any? {|comic| comic.data.include? 'chapter' }
    end

    def haschapter
      @obj.data.include? 'chapter'
    end

    def_safe_delegator :chapterdrop, :chapterid, :chapterid
    def_safe_delegator :chapterdrop, :chaptername, :chaptername
    def_safe_delegator :chapterdrop, :chapterdescription, :chapterdescription
    def_safe_delegator :chapter, :url, :chapterlink

    def_safe_delegator :prevchapterdrop, :url, :prevchapter
    def_safe_delegator :nextchapterdrop, :url, :nextchapter

    def isfirstcomicinchapter
      (chapterdrop&.send(:comics) || []).first == @obj
    end

    def islastcomicinchapter
      (chapterdrop&.send(:comics) || []).last == @obj
    end

    def_loop :dropdown, :is_selected, :is_disabled, :title, :grouplabel, :newgroup, :endgroup, :url
    def dropdown
      all_comics.each_with_object([]) do |c, dropdown|
        new_group = dropdown.last.nil? ? true : dropdown.last['grouplabel'] != c.data['chapter']
        if new_group && !dropdown.last.nil? && dropdown.last['title'] == c.data['chapter']
          dropdown.last['endgroup'] = true
        end

        in_this_chapter = @obj.data['chapter'] == c.data['chapter']
        if in_this_chapter
          dropdown << {
            'is_selected' => @obj == c,
            'is_disabled' => false,
            'title' => escape(c.data['title']),
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
      end
    end

    def_loop :authornotes, :is_reply, :comment, :isguest, :avatar, :authorname, :commentanchor, :posttime, :profilelink
    def authornotes
      @obj.data['authornotes'] || [{
        'is_reply' => false,
        'comment' => maybe_escape(@obj.content),
        'isguest' => false,
        'avatar' => nil,
        'authorname' => @obj.data['author'],
        'commentanchor' => "comment-#{@obj.date.strftime('%s')}",
        'posttime' => comicfury_date(@obj.date),
        'profilelink' => nil, # TODO
      }]
    end

    def custom
      chapter_data = chapter.nil? ? {} : chapter.data.fetch('custom', {})
      comic_data = @obj.data.fetch('custom', {})
      chapter_data.merge(comic_data).reject do |k, v|
        v.nil? || (v.respond_to?(:empty?) && v.empty?)
      end.transform_values do |v|
        v.is_a?(String) ? escape(v) : v
      end
    end

    def isfirstcomic
      all_comics.first == @obj
    end

    def islastcomic
      all_comics.last == @obj
    end

    def_safe_delegator :prevcomicdrop, :url, :prevcomic
    def_safe_delegator :prevcomicdrop, :permalink, :prevcomicpermalink
    def_safe_delegator :prevcomicdrop, :title, :prevcomictitle

    def_safe_delegator :nextcomicdrop, :url, :nextcomic
    def_safe_delegator :nextcomicdrop, :permalink, :nextcomicpermalink
    def_safe_delegator :nextcomicdrop, :title, :nextcomictitle

    def prevcomicbychapter
      if isfirstcomicinchapter
        (prevchapterdrop&.send(:comics) || []).last
      else
        (chapterdrop&.send(:comics) || []).each_cons(2).detect {|_, this| this == @obj }&.first
      end&.url
    end

    def nextcomicbychapter
      if islastcomicinchapter
        nextchapterdrop&.send(:first_comic)
      else
        (chapterdrop&.send(:comics) || []).each_cons(2).detect {|this, _| this == @obj }&.last
      end&.url
    end

    # An HTML tag to print for the comic image. If there is a future image, then
    # this is also a link to the next comic page.
    def comicimage
      linkopen = nextcomic ? <<~HTML : ''
        <a href="#{nextcomic}">
      HTML
      image = <<~HTML
        <img id="comicimage" src="#{comicimageurl}" alt="#{comictitle}"
             width="#{comicwidth}" height="#{comicheight}"
             title="#{comicdescription}">
      HTML
      linkclose = nextcomic ? <<~HTML : ''
        </a>
      HTML
      [linkopen, image, linkclose].join
    end

    def keys
      super.reject {|k| private_methods.include? k.to_sym }
    end

    def to_liquid
      super.reject do |k, v|
        Jekyll::Drops::DocumentDrop::NESTED_OBJECT_FIELD_BLACKLIST.include? k
      end.to_h
    end

    private
    def all_comics
      @obj.collection.docs.reject {|c| SPECIAL_COMIC_SLUGS.include? c.data['slug'] }
    end

    def chapter
      @obj.site.collections['chapters'].docs.detect {|c| c.data['slug'] == @obj.data['chapter'] }
    end

    def nextcomicdrop
      @obj.next_doc.nil? ? nil : ComicDrop.new(@obj.next_doc)
    end

    def prevcomicdrop
      @obj.previous_doc.nil? ? nil : ComicDrop.new(@obj.previous_doc)
    end

    def chapterdrop
      chapter.nil? ? nil : ChapterDrop.new(chapter)
    end

    def prevchapterdrop
      chapter&.previous_doc.nil? ? nil : ChapterDrop.new(chapter.previous_doc)
    end

    def nextchapterdrop
      chapter&.next_doc.nil? ? nil : ChapterDrop.new(chapter.next_doc)
    end

    data_delegator 'image'
    def_image_metadata :image
    private :image, :image_url, :image_width, :image_height

    public
    alias comicimageurl image_url
    alias comicwidth image_width
    alias comicheight image_height
  end
end
