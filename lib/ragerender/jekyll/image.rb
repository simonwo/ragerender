require 'forwardable'
require 'jekyll/drops/drop'
require_relative 'pipettes'

module RageRender
  class ImageDrop < Jekyll::Drops::Drop
    extend Forwardable
    extend Pipettes

    def initialize(obj, comicdrop)
      super(obj)
      @comic = comicdrop
      @image_obj = obj
    end

    # an <img> tag containing the image, without surrounding link
    def imageonlyhtml
      filehtml || <<~HTML
        <img id="comicimage" src="#{imageurl}" alt="#{comictitle}"
             width="#{width}" height="#{height}"
             title="#{comicdescription}">
      HTML
    end

    # the html contents of this loop iteration. this includes stuff like a
    # surrounding link to the next page
    def html
      filehtml || [
        nextcomic ? "<a href=\"#{nextcomic}\">" : '',
        imageonlyhtml,
        nextcomic ? '</a>' : '',
      ].join
    end

    private
    def image
      @obj.relative_path
    end

    def filehtml
      image_obj.data['content']
    end

    def_delegators :@comic, :nextcomic, :comictitle, :comicdescription
    private :nextcomic, :comictitle, :comicdescription

    def_image_metadata :image
    private :image_url, :image_width, :image_height

    def imageurl
      image_url unless filehtml
    end

    alias width image_width
    alias height image_height
    public :imageurl, :width, :height

    def fallback_data; {}; end
  end

  class MultiImageDrop < ImageDrop
    def imageonlyhtml
      <<~HTML
        <img src="#{imageurl}" alt="#{comictitle}"
             width="#{width}" height="#{height}"
             title="#{comicdescription}" class="comicsegmentimage">
      HTML
    end

    def html
      <<~HTML
        <div class="segmentcontainer">
          #{super}
        </div>
      HTML
    end
  end
end
