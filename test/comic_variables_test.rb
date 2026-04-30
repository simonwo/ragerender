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

    @site.add_comic 'comic2.html', image: @img
    payload = RageRender::ComicDrop.new(@site.collections['comics'].docs.last).to_liquid
    _(payload['comicnumber']).must_equal 2
  end

  it 'correctly gives variables for next and previous comics' do
    @site.add_comic '1.html', title: 'First', image: @img
    @site.add_comic '2.html', title: 'Second', image: @img

    first = RageRender::ComicDrop.new(@site.collections['comics'].docs.first).to_liquid
    _(first['nextcomic']).must_equal '/comics/2/'
    _(first['prevcomic']).must_be_nil
    _(first['nextcomicpermalink']).must_equal 'https://example.cfw.me/comics/2/'
    _(first['prevcomicpermalink']).must_be_nil
    _(first['nextcomictitle']).must_equal 'Second'
    _(first['prevcomictitle']).must_be_nil

    last = RageRender::ComicDrop.new(@site.collections['comics'].docs.last).to_liquid
    _(last['nextcomic']).must_be_nil
    _(last['prevcomic']).must_equal '/comics/1/'
    _(last['nextcomicpermalink']).must_be_nil
    _(last['prevcomicpermalink']).must_equal 'https://example.cfw.me/comics/1/'
    _(last['nextcomictitle']).must_be_nil
    _(last['prevcomictitle']).must_equal 'First'
  end

  it 'orders comics correctly by publication date' do
    @site.add_comic '1.html', image: @img, date: '2025-12-21'
    @site.add_comic '2.html', image: @img, date: '2024-1-19'
    @site.collections['comics'].send(:sort_docs!)

    first = RageRender::ComicDrop.new(@site.collections['comics'].docs.first).to_liquid
    last = RageRender::ComicDrop.new(@site.collections['comics'].docs.last).to_liquid
    _(first['nextcomic']).must_equal '/comics/1/'
    _(first['prevcomic']).must_be_nil
    _(first['isfirstcomic']).must_equal true
    _(first['islastcomic']).must_equal false
    _(last['nextcomic']).must_be_nil
    _(last['prevcomic']).must_equal '/comics/2/'
    _(last['isfirstcomic']).must_equal false
    _(last['islastcomic']).must_equal true
  end

  it 'orders comics correctly between chapters' do
    @site.add_chapter 'first.yml', slug: 'first', title: 'Chapter the First'
    @site.add_chapter 'second.yml', slug: 'second', title: 'Chapter 2'
    @site.add_comic '1.html', image: @img, date: '2024-2-19', chapter: 'second'
    @site.add_comic '2.html', image: @img, date: '2024-1-19', chapter: 'first'
    @site.add_comic '3.html', image: @img, date: '2024-4-19', chapter: 'second'
    @site.add_comic '4.html', image: @img, date: '2024-3-19', chapter: 'first'
    @site.collections['comics'].send(:sort_docs!)

    first = RageRender::ComicDrop.new(@site.collections['comics'].docs[0]).to_liquid
    second = RageRender::ComicDrop.new(@site.collections['comics'].docs[1]).to_liquid
    third = RageRender::ComicDrop.new(@site.collections['comics'].docs[2]).to_liquid
    fourth = RageRender::ComicDrop.new(@site.collections['comics'].docs[3]).to_liquid

    # Default order should be date based
    _(first['comicurl']).must_equal '/comics/2/'
    _(first['nextcomic']).must_equal '/comics/1/'
    _(first['prevcomic']).must_be_nil
    _(second['comicurl']).must_equal '/comics/1/'
    _(second['nextcomic']).must_equal '/comics/4/'
    _(second['prevcomic']).must_equal '/comics/2/'
    _(third['comicurl']).must_equal '/comics/4/'
    _(third['nextcomic']).must_equal '/comics/3/'
    _(third['prevcomic']).must_equal '/comics/1/'
    _(fourth['comicurl']).must_equal '/comics/3/'
    _(fourth['nextcomic']).must_be_nil
    _(fourth['prevcomic']).must_equal '/comics/4/'

    # Chapter links should point within chapters first?
    # 2 -> 4 -> 1 -> 3
    _(first['isfirstcomicinchapter']).must_equal true
    _(first['islastcomicinchapter']).must_equal false
    _(first['nextcomicbychapter']).must_equal '/comics/4/'
    _(first['prevcomicbychapter']).must_be_nil
    _(second['isfirstcomicinchapter']).must_equal true
    _(second['islastcomicinchapter']).must_equal false
    _(second['nextcomicbychapter']).must_equal '/comics/3/'
    _(second['prevcomicbychapter']).must_equal '/comics/4/'
    _(third['isfirstcomicinchapter']).must_equal false
    _(third['islastcomicinchapter']).must_equal true
    _(third['nextcomicbychapter']).must_equal '/comics/1/'
    _(third['prevcomicbychapter']).must_equal '/comics/2/'
    _(fourth['isfirstcomicinchapter']).must_equal false
    _(fourth['islastcomicinchapter']).must_equal true
    _(fourth['nextcomicbychapter']).must_be_nil
    _(fourth['prevcomicbychapter']).must_equal '/comics/1/'
  end

  it 'correctly gives year and month numbers for the post date' do
    @site.add_comic '1.html', image: @img, date: '2025-12-21'
    @site.add_comic '2.html', image: @img, date: '2026-1-19'

    first = RageRender::ComicDrop.new(@site.collections['comics'].docs.first).to_liquid
    last = RageRender::ComicDrop.new(@site.collections['comics'].docs.last).to_liquid
    _(first['postyear']).must_equal 2025
    _(first['postmonth']).must_equal 12
    _(last['postyear']).must_equal 2026
    _(last['postmonth']).must_equal 1
   end

  it 'includes appropriate chapter variables in the comic variables' do
    @site.add_chapter 'first.yml', slug: 'first', title: 'Chapter the First', description: 'It begins!'
    @site.add_chapter 'second.yml', slug: 'second', title: 'Chapter 2', description: 'It carries on'

    @site.add_comic '1.html', image: @img, chapter: 'first'
    first = RageRender::ComicDrop.new(@site.collections['comics'].docs.first).to_liquid
    _(first['chapterid']).must_equal 0
    _(first['chaptername']).must_equal 'Chapter the First'
    _(first['chapterdescription']).must_equal 'It begins!'

    @site.add_comic '2.html', image: @img
    second = RageRender::ComicDrop.new(@site.collections['comics'].docs.last).to_liquid
    _(second['chapterid']).must_be_nil
    _(second['chaptername']).must_be_nil
    _(second['chapterdescription']).must_be_nil

    @site.add_comic '3.html', image: @img, chapter: 'second'
    third = RageRender::ComicDrop.new(@site.collections['comics'].docs.last).to_liquid
    _(third['chapterid']).must_equal 1
    _(third['chaptername']).must_equal 'Chapter 2'
    _(third['chapterdescription']).must_equal 'It carries on'

    first_paginated = RageRender::PaginatedComicDrop.new(@site.collections['comics'].docs.first, @site.collections['comics'].docs).to_liquid
    _(first_paginated['chapterid']).must_equal 0
    _(first_paginated['chaptername']).must_equal 'Chapter the First'
    _(first_paginated['chapterdescription']).must_equal 'It begins!'
    _(first_paginated['newchapter']).must_equal true
    _(first_paginated['chapterend']).must_equal true

    third_paginated = RageRender::PaginatedComicDrop.new(@site.collections['comics'].docs.last, @site.collections['comics'].docs).to_liquid
    _(third_paginated['chapterid']).must_equal 1
    _(third_paginated['chaptername']).must_equal 'Chapter 2'
    _(third_paginated['chapterdescription']).must_equal 'It carries on'
    _(third_paginated['newchapter']).must_equal true
    _(third_paginated['chapterend']).must_equal true
  end

  it 'uses appropriate values for chapter variables when comic is not in a chapter' do
    @site.add_chapter 'first.yml', slug: 'first', title: 'Chapter the First', description: 'It begins!'
    @site.add_comic '1.html', image: @img
    @site.add_comic '2.html', image: @img

    RageRender::ChapterFromComicsGenerator.new.generate(@site)
    _(@site.collections['chapters'].docs).wont_be :one?

    payload = RageRender::ComicDrop.new(@site.collections['comics'].docs.first).to_liquid
    _(payload['chapterid']).must_equal 0
    _(payload['chaptername']).must_equal 'Unchaptered'
    _(payload['chapterdescription']).must_equal 'These comic pages are not part of any chapter'
    _(payload['chapterlink']).must_equal '/archive/0/'
    _(payload['isfirstcomicinchapter']).must_equal true
    _(payload['islastcomicinchapter']).must_equal false

    paginated = RageRender::PaginatedComicDrop.new(@site.collections['comics'].docs.first, @site.collections['comics'].docs).to_liquid
    _(paginated['chapterid']).must_equal 0
    _(paginated['chaptername']).must_equal 'Unchaptered'
    _(paginated['chapterdescription']).must_equal 'These comic pages are not part of any chapter'
    _(paginated['newchapter']).must_equal true
    _(paginated['chapterend']).must_equal false

    paginated = RageRender::PaginatedComicDrop.new(@site.collections['comics'].docs.last, @site.collections['comics'].docs).to_liquid
    _(paginated['chapterid']).must_equal 0
    _(paginated['chaptername']).must_equal 'Unchaptered'
    _(paginated['chapterdescription']).must_equal 'These comic pages are not part of any chapter'
    _(paginated['newchapter']).must_equal false
    _(paginated['chapterend']).must_equal true
  end

  it 'outputs HTML from a non-image comic' do
    @site.add_static_file('/images/comic.html').data['content'] = '<b>Cool comic</b>'
    @site.add_comic 'comic.html', image: '/images/comic.html'

    payload = RageRender::ComicDrop.new(@site.collections['comics'].docs.first).to_liquid
    _(payload['comicimage']).must_equal '<b>Cool comic</b>'
    _(payload['comicimagetype']).must_equal 'html'
    _(payload['comicimageurl']).must_be_nil
    _(payload['comicwidth']).must_equal 0
    _(payload['comicheight']).must_equal 0

    parts = payload['comicparts'].first
    _(parts['html']).must_equal '<b>Cool comic</b>'
    _(parts['imageonlyhtml']).must_equal '<b>Cool comic</b>'
    _(parts['imageurl']).must_be_nil
    _(parts['width']).must_be_nil
    _(parts['height']).must_be_nil

    paginated = RageRender::PaginatedComicDrop.new(@site.collections['comics'].docs.first, @site.collections['comics'].docs).to_liquid
    _(paginated['thumbnail_url']).must_be_nil
    _(paginated['thumbnail_width']).must_equal 0
    _(paginated['thumbnail_height']).must_equal 0
    _(paginated['thumbnail_width_small']).must_equal 0
    _(paginated['thumbnail_height_small']).must_equal 0
  end

  it 'outputs multiple comic parts for multi-image comics' do
    @site.add_static_file '/images/multi1.jpg', {'width' => 1080, 'height' => 1920}
    @site.add_static_file '/images/multi2.jpg', {'width' => 600, 'height' => 800}
    @site.add_comic 'comic.html', images: ['/images/multi1.jpg', 'images/multi2.jpg']

    payload = RageRender::ComicDrop.new(@site.collections['comics'].docs.first).to_liquid
    _(payload['comicimage']).wont_be :empty?
    _(payload['comicimage']).must_include '<div class="comicsegments">'
    _(payload['comicimagetype']).must_equal 'multiimage'
    _(payload['comicimageurl']).must_equal '/images/multi1.jpg'
    _(payload['comicwidth']).must_equal 1080
    _(payload['comicheight']).must_equal 1920

    paginated = RageRender::PaginatedComicDrop.new(@site.collections['comics'].docs.first, @site.collections['comics'].docs).to_liquid
    _(paginated['thumbnail_url']).must_equal '/images/multi1.jpg'
    _(paginated['thumbnail_width']).must_equal 236
    _(paginated['thumbnail_height']).must_equal 420
    _(paginated['thumbnail_width_small']).must_equal 118
    _(paginated['thumbnail_height_small']).must_equal 210

    parts = payload['comicparts']
    _(parts.size).must_equal 2

    first = parts.first
    _(first['html']).wont_be :empty?
    _(first['imageonlyhtml']).wont_be :empty?
    _(first['html']).wont_equal first['imageonlyhtml']
    _(first['imageurl']).must_equal '/images/multi1.jpg'
    _(first['width']).must_equal 1080
    _(first['height']).must_equal 1920

    last = parts.last
    _(last['html']).wont_equal first['html']
    _(last['imageonlyhtml']).wont_equal first['imageonlyhtml']
    _(last['imageurl']).must_equal '/images/multi2.jpg'
    _(last['width']).must_equal 600
    _(last['height']).must_equal 800
  end
end
