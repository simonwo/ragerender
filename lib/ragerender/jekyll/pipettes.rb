# Pipettes help you make drops.

module RageRender
  module Pipettes
    def def_data_delegator key, aliaz
      define_method(aliaz.to_sym) do
        @obj.data[key.to_s]
      end
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
