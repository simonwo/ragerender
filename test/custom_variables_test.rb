require_relative 'test_helper'
require_relative '../lib/ragerender/jekyll/chapter'
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

  it 'renders variables on a comic' do
    @site.add_comic 'comic.html', custom: {'snackeroo' => 'salsa', 'delicious' => true}, image: @img

    payload = RageRender::ComicDrop.new(@site.collections['comics'].first).to_liquid
    _(payload).must_include 'custom'
    _(payload['custom'].keys.size).must_equal 2
    _(payload['custom']).must_include 'snackeroo'
    _(payload['custom']['snackeroo']).must_equal 'salsa'
    _(payload['custom']).must_include 'delicious'
    _(payload['custom']['delicious']).must_equal true
  end

  it 'skips empty variables' do
    @site.add_comic 'comic.html', custom: {'empty_string' => '', 'nil_value' => nil}, image: @img

    payload = RageRender::ComicDrop.new(@site.collections['comics'].first).to_liquid
    _(payload).must_include 'custom'
    _(payload['custom'].keys.size).must_equal 0
  end

  it 'renders variables from a chapter' do
    @site.add_chapter 'chapter.html', slug: 'first', custom: {'snackeroo' => 'salsa'}
    @site.add_comic 'comic.html', chapter: 'first', image: @img

    payload = RageRender::ComicDrop.new(@site.collections['comics'].first).to_liquid
    _(payload).must_include 'custom'
    _(payload['custom'].keys.size).must_equal 1
    _(payload['custom']).must_include 'snackeroo'
    _(payload['custom']['snackeroo']).must_equal 'salsa'
  end

  it 'mixes variables from both a chapter and a comic' do
    @site.add_chapter 'chapter.html', slug: 'first', custom: {'snackeroo' => 'salsa'}
    @site.add_comic 'comic.html', chapter: 'first', custom: {'delicious' => true}, image: @img

    payload = RageRender::ComicDrop.new(@site.collections['comics'].first).to_liquid
    _(payload).must_include 'custom'
    _(payload['custom'].keys.size).must_equal 2
    _(payload['custom']).must_include 'snackeroo'
    _(payload['custom']['snackeroo']).must_equal 'salsa'
    _(payload['custom']).must_include 'delicious'
    _(payload['custom']['delicious']).must_equal true
  end
end
