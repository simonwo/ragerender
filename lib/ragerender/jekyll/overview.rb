require 'jekyll/hooks'
require 'jekyll/drops/drop'
require_relative 'comics'
require_relative 'blog_archive'

# Pass the right variables to overview pages.
Jekyll::Hooks.register :pages, :pre_render do |page, payload|
  if page.data['layout'] == 'overview'
    RageRender::Pipettes.clean_payload payload
    latest_comic = page.site.collections['comics'].docs.last
    if latest_comic
      payload.merge! RageRender::ComicDrop.new(latest_comic).to_liquid
    end
    payload.merge! RageRender::OverviewDrop.new(page).to_liquid
  end
end

module RageRender
  class OverviewDrop < Jekyll::Drops::Drop
    extend Pipettes
    private delegate_method_as :data, :fallback_data

    def_loop :latestblogs, *(RageRender::PaginatedBlogDrop.invokable_methods - Jekyll::Drops::DocumentDrop.invokable_methods)
    def latestblogs
      @obj.site.posts.docs[-5..]&.map {|post| RageRender::PaginatedBlogDrop.new(post) } || []
    end
  end
end
