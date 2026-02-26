require_relative 'test_helper'
require_relative '../lib/ragerender/jekyll/comics'

describe RageRender::ComicDrop.name do
  before do
    @site = FakeSite.new url: 'https://example.cfw.me/'
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

  it 'correctly gives permalinks to next and previous comics' do
    @site.add_comic '1.html', image: @img
    @site.add_comic '2.html', image: @img

    first = RageRender::ComicDrop.new(@site.collections['comics'].docs.first).to_liquid
    last = RageRender::ComicDrop.new(@site.collections['comics'].docs.last).to_liquid
    _(first['nextcomicpermalink']).must_equal 'https://example.cfw.me/comics/2/'
    _(first['prevcomicpermalink']).must_be_nil
    _(last['nextcomicpermalink']).must_be_nil
    _(last['prevcomicpermalink']).must_equal 'https://example.cfw.me/comics/1/'
  end

  it 'correctly gives year and month numbers for the post date' do
    @site.add_comic '1.html', image: @img, date: '2025-12-21'
    @site.add_comic '2.html', image: @img, date: '2024-1-19'

    first = RageRender::ComicDrop.new(@site.collections['comics'].docs.first).to_liquid
    last = RageRender::ComicDrop.new(@site.collections['comics'].docs.last).to_liquid
    _(first['postyear']).must_equal 2025
    _(first['postmonth']).must_equal 12
    _(last['postyear']).must_equal 2024
    _(last['postmonth']).must_equal 1
   end

  it 'includes appropriate chapter variables in the comic variables' do
    @site.add_chapter 'first.yml', slug: 'first', title: 'Chapter the First'
    @site.add_chapter 'second.yml', slug: 'second', title: 'Chapter 2'

    @site.add_comic '1.html', image: @img, chapter: 'first'
    first = RageRender::ComicDrop.new(@site.collections['comics'].docs.first).to_liquid
    _(first['chapterid']).must_equal 0
    _(first['chaptername']).must_equal 'Chapter the First'

    @site.add_comic '2.html', image: @img
    second = RageRender::ComicDrop.new(@site.collections['comics'].docs.last).to_liquid
    _(second['chapterid']).must_be_nil
    _(second['chaptername']).must_be_nil

    @site.add_comic '3.html', image: @img, chapter: 'second'
    third = RageRender::ComicDrop.new(@site.collections['comics'].docs.last).to_liquid
    _(third['chapterid']).must_equal 1
    _(third['chaptername']).must_equal 'Chapter 2'
  end
end
