require 'jekyll/generator'
require 'jekyll/drops/document_drop'
require_relative 'pipettes'
require_relative 'setup_collection'

# Add default values for the 'unchapter' which is used to hold all comics that
# don't have a chapter.
Jekyll::Hooks.register :site, :after_init do |site|
  setup_collection site, :chapters, '/archive/:slug/', layout: 'archive'

  site.config['defaults'].prepend({
    'scope' => {
      'path' => '_chapters/0.html',
      'type' => 'chapters',
    },
    'values' => {
      'title' => 'Unchaptered',
      'description' => 'These comic pages are not part of any chapter',
    },
  })
end

Jekyll::Hooks.register :chapters, :pre_render do |chapter, payload|
  payload.merge! RageRender::ChapterDrop.new(chapter).to_liquid
  payload.merge! RageRender::ArchiveDrop.new(chapter).to_liquid
end

module RageRender
  # Create chapter objects for any chapters listed in comics but that don't
  # currently have an explicit page created.
  class ChapterFromComicsGenerator < Jekyll::Generator
    priority :high

    def generate site
      required = Set.new(site.collections['comics'].docs.map {|c| c.data['chapter'] }.reject(&:nil?))
      existing = Set.new(site.collections['chapters'].docs.map {|c| c.data['slug'] })
      missing = required - existing
      missing.each do |slug|
        Jekyll.logger.debug 'Adding chapter:', slug
        filename = Pathname.new(site.collections['chapters'].relative_directory).join("#{slug}.html")
        chapter = Jekyll::Document.new(filename.to_path, site: site, collection: site.collections['chapters'])
        chapter.send(:merge_defaults)
        chapter.data['slug'] ||= slug
        chapter.data['title'] ||= slug
        chapter.content = nil
        site.collections['chapters'].docs << chapter
      end
    end
  end

  # Set the default cover for any chapters that don't have one to be the first
  # page of the first comic in that chapter.
  class DefaultCoverSetter < Jekyll::Generator
    priority :lowest

    def generate site
      site.collections['chapters'].docs.each do |chapter|
        chapter.data['image'] ||= default_cover(chapter)
      end
    end

    def default_cover chapter
      Pathname.new('/').join(first_comic(chapter).data['image']).to_path
    end

    def first_comic chapter
      chapter.site.collections['comics'].docs.select {|c| c.data['chapter'] == chapter.data['slug'] }.first
    end
  end

  # Values to pass to the archive layout when rendering a chapter.
  class ChapterDrop < Jekyll::Drops::DocumentDrop
    COVER_MAX_HEIGHT = 420
    COVER_MAX_WIDTH = 300

    PAGINATION_FIELDS = %w[ chaptername chapterdescription ]

    delegate_method_as :data, :fallback_data
    extend Pipettes
    extend Forwardable

    def_data_delegator :title, :chaptername
    def_data_delegator :description, :chapterdescription
    def_delegator :@obj, :url, :chapterarchiveurl

    def cover
      cover_obj.url
    end

    def cover_width_small
      if (cover_height.to_f / COVER_MAX_HEIGHT) > (cover_width.to_f / COVER_MAX_WIDTH)
        (cover_height_small * cover_width) / cover_height
      else
        [COVER_MAX_WIDTH, cover_width].min
      end
    end

    def cover_height_small
      if (cover_height.to_f / COVER_MAX_HEIGHT) > (cover_width.to_f / COVER_MAX_WIDTH)
        [COVER_MAX_HEIGHT, cover_height].min
      else
        (cover_width_small * cover_height) / cover_width
      end
    end

    def firstcomicinchapter
      first_comic&.url
    end

    def to_liquid
      super.reject do |k, v|
        Jekyll::Drops::DocumentDrop::NESTED_OBJECT_FIELD_BLACKLIST.include? k
      end.to_h
    end

    private
    def cover_width
      cover_obj.data['width'] ||= Dimensions.width cover_obj.path
    end

    def cover_height
      cover_obj.data['height'] ||= Dimensions.height cover_obj.path
    end

    def cover_obj
      @cover_obj ||= @obj.site.static_files.detect {|f| f.relative_path == cover_relative_path }
    end

    def cover_relative_path
      Pathname.new('/').join(@obj.data['image']).to_s
    end

    def first_comic
      @obj.site.collections['comics'].docs.select {|c| c.data['chapter'] == @obj.data['slug'] }.first
    end
  end
end
