require 'jekyll/drops/drop'
require 'jekyll/drops/document_drop'
require_relative 'named_data_delegator'

# Pass the right variables to blog archive pages.
Jekyll::Hooks.register :pages, :pre_render do |page, payload|
  if page.data['layout'] == 'blog-archive'
    payload.merge! RageRender::BlogArchiveDrop.new(page).to_liquid
  end
end

module RageRender
  BLOGS_PER_PAGE = 15

  # E.g. 20th Nov 2024, 2:35 PM
  SUFFIXES = {1 => 'st', 2 => 'nd', 3 => 'rd'}
  def comicfury_date time
    fmt = "%-d#{SUFFIXES.fetch(time.day, 'th')} %b %Y, %-I:%M %p"
    time.strftime(fmt)
  end

  def self.duplicate_page page, path
    site = page.site
    dupe = Jekyll::Page.new(site, page.instance_variable_get(:"@base"), page.instance_variable_get(:"@dir"), page.name)
    dupe.instance_variable_set(:"@destination", {site.dest => path})
    dupe
  end

  # Creates each page of the blog archive by copying the root blog page and
  # updating the page number. Blog archive pages are available under both
  # '/blog' and '/blogarchive'.
  class PaginatedBlogsGenerator < Jekyll::Generator
    def generate site
      archive = site.pages.detect {|page| page['layout'] == 'blog-archive' }
      archive.data['number'] = 1

      pages = site.posts.docs.each_slice(BLOGS_PER_PAGE).size
      pages.times.each do |number|
        path = File.absolute_path File.join archive.destination(site.dest), '../page', (number+1).to_s, 'index.html'
        paged_archive = RageRender.duplicate_page archive, path
        paged_archive.data['number'] = number + 1
        site.pages << paged_archive

        path = File.absolute_path File.join archive.destination(site.dest), '../../blogarchive/page', (number+1).to_s, 'index.html'
        paged_blogarchive = RageRender.duplicate_page archive, path
        paged_blogarchive.data['number'] = number + 1
        site.pages << paged_blogarchive
      end
    end
  end

  # Data to pass to a blog archive page.
  class BlogArchiveDrop < Jekyll::Drops::Drop
    private delegate_method_as :data, :fallback_data
    data_delegator 'number'

    def blogs_paginated
      all_blogs[number-1]&.map {|blog| PaginatedBlogDrop.new(blog).to_liquid } || []
    end

    def lastpagenumber
      all_blogs.size
    end

    # Objects used for laying out page numbers.
    #
    # The page numbers always include:
    # - the first page
    # - the last page
    # - two pages around the current page
    def pages
      [1].chain([1, all_blogs.size, *(number-2..number+2).to_a].uniq).select {|i| i >= 1 && i <= all_blogs.size }.sort.each_cons(2).map do |prev, page|
        {
          'page' => page,
          'pagelink' => File.join(@obj.url, 'page', page.to_s),
          'is_current' => page == number,
          'skipped_ahead' => page - prev > 1,
        }
      end
    end

    private
    def all_blogs
      @all_blogs = @obj.site.posts.docs.each_slice(BLOGS_PER_PAGE).to_a
    end
  end

  # Data representing a single paginated blog entry, as available from
  # [l:blogs_paginated].
  class PaginatedBlogDrop < Jekyll::Drops::DocumentDrop
    extend NamedDataDelegator

    def_data_delegator :title, :blogtitle
    def_delegator :@obj, :url, :bloglink
    def_data_delegator :author, :authorname
    def_delegator :@obj, :content, :blog
    # TODO profilelink

    private delegate_method_as :data, :fallback_data

    def posttime
      comicfury_date(@obj.date)
    end

    def allowcomments
      @obj.site.config['allowcomments']
    end

    def comments
      (@obj.data['comments'] || []).size
    end
  end
end
