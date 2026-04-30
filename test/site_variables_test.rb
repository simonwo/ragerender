require_relative 'test_helper'
require_relative '../lib/ragerender/jekyll'

describe RageRender::WebcomicDrop.name do
  after do
    @site.teardown!
  end

  it 'exposes webcomic genres' do
    @site = FakeSite.new genres: ['Comedy', 'Other']
    page = @site.add_post 'test.txt'

    payload = RageRender::WebcomicDrop.new(page).to_liquid
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

    payload = RageRender::WebcomicDrop.new(page).to_liquid
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
    payload = RageRender::WebcomicDrop.new(page).to_liquid
    _(payload['extrapages'].size).must_equal 1
    _(payload['extrapages'].first['title']).must_equal 'Visible Page'
    _(payload['extrapages'].first['link']).must_equal '/visible.html'
    _(payload['extrapages'].first['foldername']).must_equal 'visible'
  end

  it 'knows what the comic-related pages are' do
    @site = FakeSite.new

    archive_comics = @site.add_page File.join(File.dirname(__FILE__), '../'), 'assets', 'archive-comics.html'
    payload = RageRender::WebcomicDrop.new(archive_comics).to_liquid
    _(payload['iscomicrelatedpage']).must_equal false
    _(payload['iscomicpage']).must_equal false

    archive = @site.add_page File.join(File.dirname(__FILE__), '../'), 'assets', 'archive.html'
    payload = RageRender::WebcomicDrop.new(archive).to_liquid
    _(payload['iscomicrelatedpage']).must_equal false
    _(payload['iscomicpage']).must_equal false

    overview = @site.add_page File.join(File.dirname(__FILE__), '../'), 'assets', 'overview.html'
    payload = RageRender::WebcomicDrop.new(overview).to_liquid
    _(payload['iscomicrelatedpage']).must_equal true
    _(payload['iscomicpage']).must_equal false
    _(payload['comicsnum']).must_equal 0

    @site.add_static_file '/images/booga.jpg'
    comic = @site.add_comic '_comics/booga.html', slug: 'booga', title: 'My comic'
    payload = RageRender::WebcomicDrop.new(comic).to_liquid
    _(payload['iscomicrelatedpage']).must_equal true
    _(payload['iscomicpage']).must_equal true
    _(payload['comicsnum']).must_equal 1

    @site.config['frontpage'] = 'archive'
    RageRender::FrontpageGenerator.new.generate(@site)
    frontpage = @site.pages.detect {|c| c.data['slug'] == 'frontpage' }
    payload = RageRender::WebcomicDrop.new(frontpage).to_liquid
    _(payload['iscomicrelatedpage']).must_equal false
    _(payload['iscomicpage']).must_equal false

    @site.config['frontpage'] = 'latest'
    RageRender::FrontpageGenerator.new.generate(@site)
    frontpage = @site.collections['comics'].docs.detect {|c| c.data['slug'] == 'frontpage' }
    payload = RageRender::WebcomicDrop.new(frontpage).to_liquid
    _(payload['iscomicrelatedpage']).must_equal true
    _(payload['iscomicpage']).must_equal true
  end
end
