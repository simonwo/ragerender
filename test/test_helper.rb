$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "minitest/autorun"
require 'jekyll'

class FakeSite < Jekyll::Site
  def initialize config={}
    Jekyll.logger.log_level = :debug
    @source = Dir.mktmpdir()
    config = Jekyll::Configuration.from(config.merge({'source' => @source}))
    super(config)
  end

  def teardown!
    FileUtils.rmtree @source
  end

  def add_collection label
    @collections ||= {}
    @collections[label] = Jekyll::Collection.new(self, label)
  end

  def add_static_file path
    file = Jekyll::StaticFile.new(self, "", File.dirname(path), File.basename(path))
    file.instance_variable_set(:"@modified_time", Time.now)
    @static_files ||= []
    @static_files << file
  end

  def add_chapter path, **data
    chapter = Jekyll::Document.new(path, site: self, collection: self.collections['chapters'])
    chapter.merge_data! data.map {|k ,v| [k.to_s, v] }.to_h, source: caller.first
    @collections['chapters'].docs << chapter
  end

  def add_comic path, **data
    comic = Jekyll::Document.new(path, site: self, collection: self.collections['comics'])
    comic.merge_data! data.map {|k ,v| [k.to_s, v] }.to_h, source: caller.first
    @collections['comics'].docs << comic
  end

  def add_page base, dir, name, **data
    source_dir = Pathname.new(@source).join(dir).cleanpath
    unless File.join(base, dir, name) == source_dir.join(name).to_path
      FileUtils.mkdir_p(source_dir.to_path)
      FileUtils.cp(File.join(base, dir, name), source_dir.join(name).to_path)
    end
    page = Jekyll::Page.new(self, @source, dir, name)
    page.data.merge! data
    @pages << page
  end
end
