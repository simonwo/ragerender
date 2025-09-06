require_relative 'test_helper'
require_relative '../lib/ragerender/jekyll/blog'
require_relative '../lib/ragerender/jekyll/comics'

describe 'Escaping' do
  before do
    @site = FakeSite.new
    @img = '/images/comic.jpg'
    @site.add_static_file @img
  end

  after do
    @site.teardown!
  end

  describe RageRender::ComicDrop.name do
    it 'escapes content when sourced from a text file' do
      @site.add_comic 'test.txt', title: "It's All Good", content: '<p>some "text" - it\'s cool!</p>', image: @img

      payload = RageRender::ComicDrop.new(@site.collections['comics'].first).to_liquid
      _(payload).must_include 'authornotes'
      _(payload['authornotes'].first['comment']).must_equal '&lt;p&gt;some &quot;text&quot; - it&#39;s cool!&lt;/p&gt;'
      _(payload).must_include 'comictitle'
      _(payload['comictitle']).must_equal 'It&#39;s All Good'
    end

    it 'only escapes non-body content when sourced from an HTML file' do
      @site.add_comic 'test.html', title: "It's All Good", content: '<p>some "text" - it\'s cool!</p>', image: @img

      payload = RageRender::ComicDrop.new(@site.collections['comics'].first).to_liquid
      _(payload).must_include 'authornotes'
      _(payload['authornotes'].first['comment']).must_equal '<p>some "text" - it\'s cool!</p>'
      _(payload).must_include 'comictitle'
      _(payload['comictitle']).must_equal 'It&#39;s All Good'
    end
  end

  describe RageRender::BlogDrop.name do
    it 'escapes content when sourced from a text file' do
      @site.add_post 'test.txt', title: "It's All Good", content: '<p>some "text" - it\'s cool!</p>'

      payload = RageRender::BlogDrop.new(@site.collections['posts'].first).to_liquid
      _(payload).must_include 'blog'
      _(payload['blog']).must_equal '&lt;p&gt;some &quot;text&quot; - it&#39;s cool!&lt;/p&gt;'
      _(payload).must_include 'blogtitle'
      _(payload['blogtitle']).must_equal 'It&#39;s All Good'
    end

    it 'only escapes non-body content when sourced from an HTML file' do
      @site.add_comic 'test.html', title: "It's All Good", content: '<p>some "text" - it\'s cool!</p>'

      payload = RageRender::BlogDrop.new(@site.collections['comics'].first).to_liquid
      _(payload).must_include 'blog'
      _(payload['blog']).must_equal '<p>some "text" - it\'s cool!</p>'
      _(payload).must_include 'blogtitle'
      _(payload['blogtitle']).must_equal 'It&#39;s All Good'
    end
  end
end
