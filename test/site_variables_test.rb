require_relative 'test_helper'
require_relative '../lib/ragerender/jekyll'

describe RageRender::WebcomicDrop.name do
  after do
    @site.teardown!
  end

  it 'exposes webcomic genres' do
    @site = FakeSite.new genres: ['Comedy', 'Other']
    page = @site.add_post 'test.txt'

    payload = RageRender::WebcomicDrop.new(page.first).to_liquid
    _(payload['webcomicgenres']).wont_be_nil
    _(payload['webcomicgenres'].size).must_equal 2
    _(payload['webcomicgenres'][0]['genre_name']).must_equal 'Comedy'
    _(payload['webcomicgenres'][0]['genre_link']).must_equal 'https://comicfury.com/search.php?vr=1&query=&tags=comedy'
    _(payload['webcomicgenres'][1]['genre_name']).must_equal 'Other'
    _(payload['webcomicgenres'][1]['genre_link']).must_equal 'https://comicfury.com/search.php?vr=1&query=&tags=other'
    _(payload['webcomicgenre']).must_equal 'Comedy'
  end

  it 'handles undefined genres' do
    @site = FakeSite.new
    page = @site.add_post 'test.txt'

    payload = RageRender::WebcomicDrop.new(page.first).to_liquid
    _(payload['webcomicgenres']).wont_be_nil
    _(payload['webcomicgenres']).must_be :empty?
    _(payload['webcomicgenre']).must_be_nil
  end

  it 'handles extra pages' do
    @site = FakeSite.new
    File.write File.join(@site.source, 'visible.html'), "---\ntitle: Visible Page\nhidden: no\n---\n"
    @site.add_page @site.source, '', 'visible.html'
    File.write File.join(@site.source, 'hidden.html'), "---\ntitle: Hidden Page\nhidden: yes\n---\n"
    @site.add_page @site.source, '', 'hidden.html'

    page = @site.add_post 'test.txt'
    payload = RageRender::WebcomicDrop.new(page.first).to_liquid
    _(payload['extrapages'].size).must_equal 1
    _(payload['extrapages'].first['title']).must_equal 'Visible Page'
    _(payload['extrapages'].first['link']).must_equal '/visible.html'
    _(payload['extrapages'].first['foldername']).must_equal 'visible'
  end
end
