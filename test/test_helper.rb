$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "minitest/autorun"
require 'jekyll'

class FakeSite < Struct.new :config, :collections, :static_files
  def add_collection label
    self.collections ||= {}
    self.collections[label] = Jekyll::Collection.new(self, label)
  end

  def add_static_file path
    file = Jekyll::StaticFile.new(self, "", File.dirname(path), File.basename(path))
    file.instance_variable_set(:"@modified_time", Time.now)
    self.static_files ||= []
    self.static_files << file
  end

  def add_comic path, **data
    comic = Jekyll::Document.new(path, site: self, collection: self.collections['comics'])
    comic.merge_data! data.map {|k ,v| [k.to_s, v] }.to_h, source: caller.first
    self.collections['comics'].docs << comic
  end

  def collections_path; ''; end
  def frontmatter_defaults; Jekyll::FrontmatterDefaults.new(self); end
end
