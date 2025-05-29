require 'jekyll/hooks'
require 'jekyll/drops/document_drop'
require_relative '../date_formats'
require_relative 'named_data_delegator'

Jekyll::Hooks.register :posts, :pre_render do |post, payload|
  payload.merge! RageRender::BlogDrop.new(post).to_liquid
end

module RageRender
  class BlogDrop < Jekyll::Drops::DocumentDrop
    private delegate_method_as :data, :fallback_data
    extend NamedDataDelegator

    def_data_delegator :title, :blogtitle
    def_data_delegator :author, :authorname
    delegate_method_as :content, :blog

    def posttime
      comicfury_date @obj.date
    end

    def prevbloglink
      @obj.previous_doc&.url
    end

    def nextbloglink
      @obj.next_doc&.url
    end

    def to_liquid
      super.reject do |k, v|
        Jekyll::Drops::DocumentDrop::NESTED_OBJECT_FIELD_BLACKLIST.include? k
      end.to_h
    end
  end
end
