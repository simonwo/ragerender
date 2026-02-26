require_relative 'test_helper'
require_relative '../lib/ragerender/jekyll/chapter'

describe RageRender::ChapterDrop.name do
  before do
    @site = FakeSite.new url: 'https://example.cfw.me/'
  end

  after do
    @site.teardown!
  end

  it 'includes appropriate chapter variables' do
    @site.add_chapter 'first.yml', slug: 'first', title: 'Chapter the First'
    @site.add_chapter 'second.yml', slug: 'second', title: 'Chapter 2'

    first = RageRender::ChapterDrop.new(@site.collections['chapters'].docs.first).to_liquid
    last = RageRender::ChapterDrop.new(@site.collections['chapters'].docs.last).to_liquid
    _(first['chapterid']).must_equal 0
    _(first['chaptername']).must_equal 'Chapter the First'
    _(last['chapterid']).must_equal 1
    _(last['chaptername']).must_equal 'Chapter 2'
  end
end
