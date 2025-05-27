require 'jekyll/generator'
require 'jekyll/drops/drop'
require_relative 'comics'
require_relative 'pagination'
require_relative 'named_data_delegator'

# Pass the right variables to archive pages.
Jekyll::Hooks.register :pages, :pre_render do |page, payload|
  if page.data['layout'] == 'archive'
    payload.merge! RageRender::ArchiveDrop.new(page).to_liquid
  end
end

module RageRender
  COMICS_PER_PAGE = 160

  # Sets the main archive page at '/archive' to be either the chapter index if
  # chapters are enabled or the comics list if there are no chapters.
  class MainArchivePageGenerator < Jekyll::Generator
    def generate site
      archive = site.pages.detect {|page| page.data['layout'] == 'archive' && !page.data.include?('mode') }
      archive.data['mode'] = if site.collections['comics'].docs.any? {|c| c.data.include? 'chapter' }
        'chapters'
      else
        'comics'
      end
    end
  end

  # A simple list of all the comics exists under '/archive/comics',
  # with one page per 160 comics.
  class ComicArchivePaginator < Jekyll::Generator
    include PaginationGenerator

    def source_page site
      site.pages.detect {|page| page.data['layout'] == 'archive' && page.data['mode'] == 'comics' }
    end

    def num_pages site
      site.collections['comics'].docs.each_slice(COMICS_PER_PAGE).size
    end

    def permalink
      '/archive/comics/page/:number/index.html'
    end
  end

  # Now there is also one page per chapter... but also the chapter pages are
  # paginated if there are more than 160 comics per chapter. So we have to
  # handle that pagination manually by calling another paginator for each page
  # we generate here.
  class ChapterArchiveGenerator < Jekyll::Generator
    include PaginationGenerator

    priority :high

    def source_page site
      site.pages.detect {|page| page.data['layout'] == 'archive' }
    end

    def num_pages site
      chapters(site).size
    end

    def permalink
      '/archive/:number/index.html'
    end

    def handle_page page
      page.data['mode'] = 'chapters'
      page.data['chapter'] = chapters(page.site)[page.data['number'] - 1]
      ChapterArchivePaginator.new(page).generate(page.site)
    end

    private
    def chapters site
      site.collections['comics'].docs.map {|c| c.data['chapter'] }.uniq.to_a
    end
  end

  # Note that this one doesn't descend from Jekyll::Generator, because we don't
  # want it to be invoked automatically, only when we create a chapter page.
  class ChapterArchivePaginator
    include PaginationGenerator

    def initialize page
      @page = page
    end

    def source_page site
      @page
    end

    def num_pages site
      site.collections['comics'].docs.select do |c|
        c.data['chapter'] == @page.data['chapter']
      end.each_slice(COMICS_PER_PAGE).size
    end

    def permalink
      File.expand_path File.join @page.permalink, '../', 'page/:number/index.html'
    end
  end

  # A Drop that provides all of the page variables for the archive pages.
  class ArchiveDrop < Jekyll::Drops::Drop
    private delegate_method_as :data, :fallback_data
    extend NamedDataDelegator

    def_data_delegator :chapter, :chaptername

    def ischapterarchive
      @obj.data.include? 'chapter'
    end

    def show_comic_list
      ischapterarchive
    end

    def show_chapter_overview
      !ischapterarchive
    end

    def chapters
      @obj.site.pages.select do |page|
        page.data['layout'] == 'archive' &&
        page.data.include?('chapter') &&
        page.permalink =~ /archive\/[0-9]+\/index.html$/
      end.map do |page|
        ChapterDrop.new(page).to_liquid
      end
    end

    def comics_paginated
      number = @obj.data['number']
      comics = if number
        selected_comics.to_a[number - 1]
      else
        selected_comics.to_a.flatten
      end.group_by {|c| c.data['chapter'] }

      comics.map do |chapter, comics|
        chapter_data = chapters.detect {|c| c['chaptername'] == chapter } || default_chapter
        comics.each_with_index.map do |comic, index|
          drop = ComicDrop.new(comic)
          {
            **ComicDrop::PAGINATION_FIELDS.map {|field| [field, drop[field]] }.to_h,
            **chapter_data,
            'number' => index + 1,
            'newchapter' => index == 0,
            'chapterend' => index == comics.size - 1,
          }
        end
      end.flatten
    end

    def lastpagenumber
      selected_comics.size
    end

    private
    def selected_comics
      comics = @obj.site.collections['comics'].docs
      if @obj.data['chapter']
        comics = comics.select {|c| c.data['chapter'] == @obj.data['chapter'] }
      end
      comics.each_slice(COMICS_PER_PAGE)
    end

    def default_chapter # TODO this should be a config default, chapters should be a custom object + generator
      {
        'chaptername' => 'Unchaptered',
        'chapterdescription' => 'These comic pages are not part of any chapter',
      }
    end
  end

  class ChapterDrop < Jekyll::Drops::Drop
    COVER_MAX_HEIGHT = 420
    COVER_MAX_WIDTH = 300

    delegate_method_as :data, :fallback_data
    extend NamedDataDelegator
    extend Forwardable

    def_data_delegator :chapter, :chaptername
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
      Pathname.new('/').join(@obj.data['image'] || first_comic.data['image']).to_s
    end

    def first_comic
      @obj.site.collections['comics'].docs.select {|c| c.data['chapter'] == chaptername }.first
    end
  end
end
