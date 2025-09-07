require 'jekyll/hooks'
require 'jekyll/drops/drop'
require_relative 'comics'
require_relative 'blog_archive'

# Pass the right variables to overview pages.
Jekyll::Hooks.register :pages, :pre_render do |page, payload|
  if page.data['layout'] == 'overview'
    RageRender::Pipettes.clean_payload payload
    payload.merge! RageRender::ComicDrop.new(page.site.collections['comics'].docs.last).to_liquid
    payload.merge! RageRender::OverviewDrop.new(page).to_liquid
  end
end

module RageRender
  class OverviewDrop < Jekyll::Drops::Drop
    private delegate_method_as :data, :fallback_data

    def latestblogs
      @obj.site.posts.docs[-5..].map {|post| RageRender::PaginatedBlogDrop.new(post) }
    end
  end
end
