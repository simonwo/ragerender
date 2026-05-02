require 'jekyll/generator'
require 'jekyll/drops/drop'
require_relative 'pagination'

Jekyll::Hooks.register :pages, :pre_render do |page, payload|
  if page.data['layout'] == 'search'
    RageRender::Pipettes.clean_payload payload
    payload.merge! RageRender::SearchDrop.new(page).to_liquid
  end
end

module RageRender
  RESULTS_PER_PAGE = 60

  class SearchPaginationGenerator < Jekyll::Generator
    priority :low

    def generate site
      site.pages.select {|p| p.data['layout'] == 'search' }.each do |page|
        SearchPaginator.new(page).generate(site)
      end
    end
  end

  class SearchPaginator
    include PaginationGenerator

    def initialize page
      @page = page
    end

    def source_page site
      @page
    end

    def searchterm
      @page.data['searchterm']
    end

    def num_pages site
      RageRender::search(site, searchterm).each_slice(RESULTS_PER_PAGE).size
    end

    def permalink
      "/search/id/#{searchterm.hash}/:number"
    end
  end

  def self.search site, searchterm
    return [] unless searchterm
    site.collections['comics'].docs.reject {|c| SPECIAL_COMIC_SLUGS.include? c.data['slug'] }.select do |comic|
      [
        *comic.data.fetch('tags', []),
        comic.content,
        *comic.data.fetch('authornotes', []).flat_map {|n| n['comment'] },
      ].map(&:downcase).any? {|c| c.include?(searchterm.downcase) }
    end
  end

  class SearchDrop < Jekyll::Drops::Drop
    extend Pipettes

    private delegate_method_as :data, :fallback_data
    data_delegator 'searchterm'
    data_delegator 'number'
    private :number

    def searched
      !searchterm.nil?
    end

    def_loop :searchresults, *PaginatedComicDrop.own_methods
    def searchresults
      return [] unless searched
      comics = all_results[number-1]
      comics.map do |comic|
        PaginatedComicDrop.new(comic, comics)
      end
    end

    def foundresults
      searchresults.any?
    end

    def_pages :all_pages

    private
    def all_results
      @all_results ||= RageRender::search(@obj.site, searchterm).each_slice(RESULTS_PER_PAGE).to_a
    end

    def all_pages
      @obj.site.pages.select {|p| p.data['searchterm'] == searchterm && p.permalink =~ /id/ }
    end
  end
end
