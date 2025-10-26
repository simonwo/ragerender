require_relative 'test_helper'
require_relative '../lib/ragerender/jekyll/comics'

describe RageRender::ComicDrop.name do
  before do
    @site = FakeSite.new
    @img = '/images/comic.jpg'
    @site.add_static_file @img
  end

  after do
    @site.teardown!
  end

  it 'uses 1-indexed comic numbers' do
    @site.add_comic 'comic.html', image: @img
    payload = RageRender::ComicDrop.new(@site.collections['comics'].docs.first).to_liquid
    _(payload['comicnumber']).must_equal 1
    _(payload['comicsnum']).must_equal 1

    @site.add_comic 'comic2.html', image: @img
    payload = RageRender::ComicDrop.new(@site.collections['comics'].docs.last).to_liquid
    _(payload['comicnumber']).must_equal 2
    _(payload['comicsnum']).must_equal 2
  end
end
