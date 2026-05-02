require_relative 'pipettes'

module RageRender
  module PaginationGenerator
    def handle_page page
      page.site.pages << page
    end

    def duplicate page
      Jekyll::Page.new(
        page.site,
        page.instance_variable_get(:"@base"),
        page.instance_variable_get(:"@dir"),
        page.name,
      )
    end

    def generate site
      archive = source_page site
      archive.data['number'] = 1

      num_pages(site).times.each do |number|
        paged_archive = duplicate archive
        paged_archive.data['permalink'] = permalink.gsub(/:number/, (number + 1).to_s)
        paged_archive.data['number'] = number + 1
        paged_archive.data['hidden'] = true
        Jekyll.logger.debug 'Paginating:', paged_archive.data['permalink']
        handle_page paged_archive
      end
    end
  end

  class PaginatedPageDrop < Jekyll::Drops::Drop
    extend Pipettes

    def initialize obj, current_page, prev_page
      super(obj)
      @current = current_page
      @prev = prev_page
    end

    def page
      @obj.data['number']
    end

    def pagelink
      @obj.permalink
    end

    def is_current
      page == @current.data['number']
    end

    def skipped_ahead
      page - @prev.data['number'] > 1
    end
  end
end
