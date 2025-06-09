require_relative 'test_helper'
require_relative '../lib/ragerender/jekyll/chapter'
require_relative '../lib/ragerender/jekyll/archive'

describe RageRender::ChapterArchiveGenerator.name do
  before do
    @site = FakeSite.new
    @site.add_collection 'comics'
    @site.add_collection 'chapters'
    @site.add_page File.dirname(__FILE__), '../assets', 'archive.html'

    _(@site.pages.size).must_equal 1
    @original = @site.pages.first
  end

  after do
    @site.teardown!
  end

  it 'generates one numbered page per chapter' do
    @site.add_comic '1.html', chapter: 'first'
    @site.add_comic '2.html', chapter: 'second'

    RageRender::ChapterFromComicsGenerator.new.generate @site
    _(@site.collections['chapters'].docs.size).must_equal 2
    RageRender::ChapterArchiveGenerator.new.generate @site

    permalinks = @site.collections['chapters'].docs.map(&:url)
    _(permalinks).must_include '/archive/first/'
    _(permalinks).must_include '/archive/first/page/1/index.html'
    _(permalinks).must_include '/archive/second/'
    _(permalinks).must_include '/archive/second/page/1/index.html'
    _(@site.collections['chapters'].docs.size).must_equal 4
  end

  it 'generates extra numbered pages for more comics' do
    (2*RageRender::COMICS_PER_PAGE).times {|i| @site.add_comic "a#{i}.html", chapter: 'first' }
    (3*RageRender::COMICS_PER_PAGE).times {|i| @site.add_comic "b#{i}.html", chapter: 'second' }

    RageRender::ChapterFromComicsGenerator.new.generate @site
    _(@site.collections['chapters'].docs.size).must_equal 2
    RageRender::ChapterArchiveGenerator.new.generate @site

    permalinks = @site.collections['chapters'].docs.map(&:url)
    _(permalinks).must_include '/archive/first/'
    _(permalinks).must_include '/archive/first/page/1/index.html'
    _(permalinks).must_include '/archive/first/page/2/index.html'
    _(permalinks).must_include '/archive/second/'
    _(permalinks).must_include '/archive/second/page/1/index.html'
    _(permalinks).must_include '/archive/second/page/2/index.html'
    _(permalinks).must_include '/archive/second/page/3/index.html'
    _(@site.collections['chapters'].docs.size).must_equal 7
  end
end
