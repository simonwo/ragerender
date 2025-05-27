module RageRender
  def self.duplicate_page page
    Jekyll::Page.new(
      page.site,
      page.instance_variable_get(:"@base"),
      page.instance_variable_get(:"@dir"),
      page.name,
    )
  end

  module PaginationGenerator
    def handle_page page
    end

    def generate site
      archive = source_page site
      archive.data['number'] = 1

      num_pages(site).times.each do |number|
        paged_archive = RageRender.duplicate_page archive
        paged_archive.data['permalink'] = permalink.gsub(/:number/, (number + 1).to_s)
        paged_archive.data['number'] = number + 1
        Jekyll.logger.debug 'Paginating:', paged_archive.data['permalink']
        site.pages << paged_archive
        handle_page paged_archive
      end
    end
  end
end
