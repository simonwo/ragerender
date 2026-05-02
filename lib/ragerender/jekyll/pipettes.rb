# Pipettes help you make drops.
require 'cgi'
require 'dimensions'
require 'jekyll/drops/document_drop'

module RageRender
  module Pipettes
    def self.clean_payload payload
      Jekyll.logger.debug("Cleaning payload")
      sets = Jekyll::Drops::DocumentDrop.subclasses.map(&:invokable_methods)
      methods = sets.reduce(Set.new) {|s,acc| acc.merge(s)} - Set.new(Jekyll::Drops::DocumentDrop.invokable_methods)
      payload.send(:fallback_data).delete_if {|k| methods.include? k}
    end

    def own_methods
      invokable_methods - Jekyll::Drops::DocumentDrop.invokable_methods
    end

    def def_safe_delegator obj, key, aliaz, default=nil
      define_method(aliaz.to_sym) do
        send(obj.to_sym)&.send(key.to_sym) || default
      end
    end

    def def_data_delegator key, aliaz
      define_method(aliaz.to_sym) do
        @obj.data[key.to_s]
      end
    end

    def def_loop method, *fields
      (@loops ||= {})[method.to_sym] = fields
    end

    def loops
      @loops || {}
    end

    def self.extended mod
      mod.define_method(:escape) do |str|
        str.nil? ? nil : CGI.escapeHTML(str)
      end
      mod.send(:private, :escape)

      mod.define_method(:maybe_escape) do |str|
        Pathname.new(@obj.path).extname != '.html' ?  escape(str) : str
      end
      mod.send(:private, :maybe_escape)

      mod.define_method(:scaled_width) do |width, height, max_width, max_height|
        return nil if width.nil? || height.zero?

        if (height.to_f / max_height) > (width.to_f / max_width)
          (scaled_height(width, height, max_width, max_height) * width) / height
        else
          [max_width, width].min
        end
      end
      mod.send(:private, :scaled_width)

      mod.define_method(:scaled_height) do |width, height, max_width, max_height|
        return nil if height.nil? || width.zero?

        if (height.to_f / max_height) > (width.to_f / max_width)
          [max_height, height].min
        else
          (scaled_width(width, height, max_width, max_height) * height) / width
        end
      end
      mod.send(:private, :scaled_height)
    end

    def def_image_metadata prefix
      define_method(:"#{prefix}_relative_path") do
        Pathname.new('/').join(send(prefix.to_sym)).to_path
      end
      private :"#{prefix}_relative_path"

      define_method(:"#{prefix}_url") do
        site = @obj.instance_variable_get(:"@site") || @obj.send(:site)
        File.join (site.baseurl || ''), send(:"#{prefix}_relative_path")
      end

      define_method(:"#{prefix}_obj") do
        unless instance_variable_defined? :"@#{prefix}_obj"
          instance_variable_set(:"@#{prefix}_obj", @obj.site.static_files.detect {|f| f.relative_path == send(:"#{prefix}_relative_path") })
        end
        instance_variable_get(:"@#{prefix}_obj")
      end
      private :"#{prefix}_obj"

      define_method(:"#{prefix}_path") do
        send(:"#{prefix}_obj").path
      end
      private :"#{prefix}_path"

      define_method(:"#{prefix}_width") do
        send(:"#{prefix}_obj") && (send(:"#{prefix}_obj").data['width'] ||= Dimensions.width(send(:"#{prefix}_path")) rescue nil)
      end

      define_method(:"#{prefix}_height") do
        send(:"#{prefix}_obj") && (send(:"#{prefix}_obj").data['height'] ||= Dimensions.height(send(:"#{prefix}_path")) rescue nil)
      end
    end

    def def_pages all_pages
      define_method(:lastpagenumber) do
        send(all_pages).size
      end

      # Objects used for laying out page numbers.
      #
      # The page numbers always include:
      # - the first page
      # - the last page
      # - two pages around the current page
      define_method(:pages) do
        pages = send(all_pages)
        [1].chain([1, pages.size, *(number-2..number+2).to_a].uniq).select {|i| i >= 1 && i <= pages.size }.sort.map do |i|
          pages[i-1]
        end.each_cons(2).map do |prev, page|
          PaginatedPageDrop.new(page, @obj, prev)
        end
      end

      def_loop :pages, *PaginatedBlogDrop.own_methods
    end
  end
end
