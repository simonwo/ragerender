require_relative 'test_helper'
require_relative '../lib/ragerender/jekyll/archive'

describe RageRender::ComicArchivePaginator.name do
  before do
    @site = FakeSite.new({'strict_front_matter' => false})
    @site.add_collection 'comics'
    @site.add_page File.join(File.dirname(__FILE__), '../'), 'assets', 'archive-comics.html'
    @original = @site.pages.first
    @site.add_page File.join(File.dirname(__FILE__), '../'), 'assets', 'archive.html'

    _(@site.pages.size).must_equal 2
  end

  after do
    @site.teardown!
  end

  it 'keeps the original page in place' do
    @site.add_comic '1.html'

    RageRender::ComicArchivePaginator.new.generate(@site)
    _(@site.pages.size).must_equal 3
    _(@site.pages).must_include @original
  end

  it 'generates a single page for less than 160 comics' do
    RageRender::COMICS_PER_PAGE.times {|i| @site.add_comic "#{i}.html" }

    RageRender::ComicArchivePaginator.new.generate(@site)
    _(@site.pages.size).must_equal 3
    _(@site.pages).must_include @original

    new = @site.pages.detect {|p| p != @original && !p.data['mode'].nil? }
    _(new.data['number']).must_equal 1
    _(@original.data['number']).must_equal 1
  end

  it 'generates multiple pages for more than 160 comics' do
    (2 * RageRender::COMICS_PER_PAGE).times {|i| @site.add_comic "#{i}.html" }

    RageRender::ComicArchivePaginator.new.generate(@site)
    _(@site.pages.size).must_equal 4
    _(@site.pages).must_include @original

    numbers = @site.pages.select {|p| p != @original && !p.data['mode'].nil? }.map {|c| c.data['number']}
    _(numbers.sort).must_equal [1, 2]
  end
end
