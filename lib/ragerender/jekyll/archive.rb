require 'jekyll/generator'
require 'jekyll/drops/drop'
require_relative 'comics'
require_relative 'chapter'
require_relative 'pagination'
require_relative 'pipettes'

# Pass the right variables to archive pages. Note that this doesn't apply to
# chapter pages because they are not "pages"
Jekyll::Hooks.register :pages, :pre_render do |page, payload|
  if page.data['layout'] == 'archive'
    RageRender::Pipettes.clean_payload payload
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
      archive.data['mode'] = unless site.collections['comics'].docs.any? {|c| c.data.include? 'chapter' }
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
    priority :normal

    def generate site
      site.collections['chapters'].docs.to_a.dup.each do |page|
        page.data['mode'] = 'chapters'
        ChapterArchivePaginator.new(page).generate(site)
      end
    end
  end

  # Note that this one doesn't descend from Jekyll::Generator, because we don't
  # want it to be invoked automatically, only when we create a chapter page.
  class ChapterArchivePaginator
    include PaginationGenerator

    def initialize chapter
      @page = chapter
    end

    def source_page site
      @page
    end

    def duplicate original
      page = Jekyll::Document.new(original.path, site: original.site, collection: original.collection)
      page.merge_data! original.data, source: 'original document'
      page
    end

    def num_pages site
      site.collections['comics'].docs.select do |c|
        c.data['chapter'] == @page.data['slug']
      end.each_slice(COMICS_PER_PAGE).size
    end

    def permalink
      path = Pathname.new(@page.url)
      path = path.dirname unless @page.url.end_with?('/')
      path.join('page/:number/index.html').to_path
    end

    def handle_page page
      page.collection.docs << page
    end
  end

  # A Drop that provides all of the page variables for the archive pages.
  class ArchiveDrop < Jekyll::Drops::Drop
    private delegate_method_as :data, :fallback_data
    extend Pipettes

    def ischapterarchive
      @obj.type == :chapters
    end

    def show_comic_list
      ischapterarchive || @obj.data['mode'] == 'comics'
    end

    def show_chapter_overview
      !show_comic_list
    end

    def_loop :chapters, *(RageRender::ChapterDrop.invokable_methods - Jekyll::Drops::DocumentDrop.invokable_methods)
    def chapters
      unless show_chapter_overview
        @obj.site.collections['chapters'].docs.reject do |page|
          page.data['hidden']
        end.map do |page|
          ChapterDrop.new(page).to_liquid
        end
      end
    end

    def_loop :comics_paginated, *PaginatedComicDrop.own_methods
    def comics_paginated
      number = @obj.data['number']
      comics = if number
        selected_comics.to_a[number - 1]
      else
        selected_comics.to_a.flatten
      end || []

      comics.map do |comic|
        PaginatedComicDrop.new(comic, comics)
      end
    end

    def lastpagenumber
      selected_comics.size
    end

    def thumbnail_box_styles
      'position:fixed; opacity:0; pointer-events:none; z-index:10000;'
    end

    private
    def selected_comics
      comics = @obj.site.collections['comics'].docs.reject {|c| SPECIAL_COMIC_SLUGS.include? c.data['slug'] }
      if @obj.type == :chapters
        comics = comics.select {|c| c.data['chapter'] == @obj.data['slug'] }
      end
      comics.each_slice(COMICS_PER_PAGE)
    end
  end
end
