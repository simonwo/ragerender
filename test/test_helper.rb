$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "minitest/autorun"
require 'jekyll'

class FakeSite < Struct.new :config, :collections, :static_files, :pages
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

  def add_page base, dir, name, **data
    page = Jekyll::Page.new(self, base, dir, name)
    page.data.merge! data
    self.pages << page
  end

  def collections_path; ''; end
  def frontmatter_defaults; Jekyll::FrontmatterDefaults.new(self); end
  def in_source_dir *path; path.join('/'); end
  def in_theme_dir *path; path.join('/'); end
  def file_read_opts; {encoding: 'utf-8'}; end
end
