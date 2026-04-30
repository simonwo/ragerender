Jekyll::Hooks.register :pages, :pre_render do |page, payload|
  if page.data['layout'] == 'search'
    RageRender::Pipettes.clean_payload payload
    payload.merge! RageRender::SearchDrop.new(page).to_liquid
  end
end

module RageRender
  class SearchDrop < Jekyll::Drops::Drop
    extend Pipettes

    private delegate_method_as :data, :fallback_data
    data_delegator 'searchterm'

    def searched
      !searchterm.nil?
    end

    def_loop :searchresults, *PaginatedComicDrop.own_methods
    def searchresults
      return [] unless searched
      @results ||= begin
        comics = @obj.site.collections['comics'].docs.select do |comic|
          [
            *comic.data.fetch('tags', []),
            comic.content,
            *comic.data.fetch('authornotes', []).flat_map {|n| n['comment'] },
          ].map(&:downcase).any? {|c| c.include?(searchterm.downcase) }
        end
        comics.map do |comic|
          PaginatedComicDrop.new(comic, comics)
        end
      end
    end

    def foundresults
      searchresults.any?
    end
  end
end
