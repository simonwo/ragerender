# Pipettes help you make drops.
require 'cgi'
require 'dimensions'

module RageRender
  module Pipettes
    def self.clean_payload payload
      Jekyll.logger.debug("Cleaning payload")
      sets = Jekyll::Drops::DocumentDrop.subclasses.map(&:invokable_methods)
      methods = sets.reduce(Set.new) {|s,acc| acc.merge(s)} - Set.new(Jekyll::Drops::DocumentDrop.invokable_methods)
      payload.send(:fallback_data).delete_if {|k| methods.include? k}
    end

    def def_data_delegator key, aliaz
      define_method(aliaz.to_sym) do
        @obj.data[key.to_s]
      end
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
    end

    def def_image_metadata prefix
      define_method(:"#{prefix}_relative_path") do
        Pathname.new('/').join(send(prefix.to_sym)).to_path
      end

      define_method(:"#{prefix}_url") do
        File.join (@obj.site.baseurl || ''), send(:"#{prefix}_relative_path")
      end

      define_method(:"#{prefix}_obj") do
        unless instance_variable_defined? :"@#{prefix}_obj"
          instance_variable_set(:"@#{prefix}_obj", @obj.site.static_files.detect {|f| f.relative_path == send(:"#{prefix}_relative_path") })
        end
        instance_variable_get(:"@#{prefix}_obj")
      end

      define_method(:"#{prefix}_path") do
        send(:"#{prefix}_obj").path
      end

      define_method(:"#{prefix}_width") do
        send(:"#{prefix}_obj").data['width'] ||= Dimensions.width(send(:"#{prefix}_path")) rescue nil
      end

      define_method(:"#{prefix}_height") do
        send(:"#{prefix}_obj").data['height'] ||= Dimensions.height(send(:"#{prefix}_path")) rescue nil
      end
    end
  end
end
