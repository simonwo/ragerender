require_relative 'test_helper'
require_relative '../lib/ragerender/jekyll/archive'

describe RageRender::ChapterArchiveGenerator.name do
  before do
    @site = FakeSite.new({}, {}, [], [])
    @site.add_collection 'comics'
    @site.add_page File.dirname(__FILE__), '../assets', 'archive.html'

    _(@site.pages.size).must_equal 1
    @original = @site.pages.first
  end

  it 'generates one root page plus one numbered page per chapter' do
    @site.add_comic '1.html', chatper: 'first'
    @site.add_comic '2.html', chapter: 'second'

    RageRender::ChapterArchiveGenerator.new.generate @site
    _(@site.pages.size).must_equal 5

    permalinks = @site.pages.map {|p| p.data['permalink'] }
    _(permalinks).must_include '/archive/index.html'
    _(permalinks).must_include '/archive/1/index.html'
    _(permalinks).must_include '/archive/1/page/1/index.html'
    _(permalinks).must_include '/archive/2/index.html'
    _(permalinks).must_include '/archive/2/page/1/index.html'
  end

  it 'generates one root page plus extra numbered pages for more comics' do
    (2*RageRender::COMICS_PER_PAGE).times {|i| @site.add_comic "a#{i}.html", chapter: 'first' }
    (3*RageRender::COMICS_PER_PAGE).times {|i| @site.add_comic "b#{i}.html", chapter: 'second' }

    RageRender::ChapterArchiveGenerator.new.generate @site
    # _(@site.pages.size).must_equal 8

    permalinks = @site.pages.map {|p| p.data['permalink'] }
    _(permalinks).must_include '/archive/index.html'
    _(permalinks).must_include '/archive/1/index.html'
    _(permalinks).must_include '/archive/1/page/1/index.html'
    _(permalinks).must_include '/archive/1/page/2/index.html'
    _(permalinks).must_include '/archive/2/index.html'
    _(permalinks).must_include '/archive/2/page/1/index.html'
    _(permalinks).must_include '/archive/2/page/2/index.html'
    _(permalinks).must_include '/archive/2/page/3/index.html'
  end
end
