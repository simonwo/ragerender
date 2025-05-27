require_relative 'test_helper'
require_relative '../lib/ragerender/jekyll/comics'

describe ComicFromImageGenerator.name do
  before do
    @site = FakeSite.new({}, {}, [])
    @site.add_collection 'posts'
    @site.add_collection 'comics'
  end

  it 'only adds comics from images' do
    ComicFromImageGenerator.new.generate(@site)
    _(@site.collections['comics'].docs.size).must_equal 0
  end

  it 'creates a comic from just an image' do
    @site.add_static_file '/images/booga.jpg'

    ComicFromImageGenerator.new.generate(@site)

    _(@site.collections['comics'].docs.size).must_equal 1
    comic = @site.collections['comics'].docs.first
    _(comic.data['title']).must_equal 'booga'
    _(comic.data['image']).must_equal '/images/booga.jpg'
  end

  it 'matches comics to images without making new ones' do
    @site.add_static_file '/images/booga.jpg'
    @site.add_comic '_comics/booga.html', slug: 'booga', title: 'My comic'
    _(@site.collections['comics'].docs.size).must_equal 1

    ComicFromImageGenerator.new.generate(@site)

    _(@site.collections['comics'].docs.size).must_equal 1
    comic = @site.collections['comics'].docs.first
    _(comic.data['title']).must_equal 'My comic'
    _(comic.data['image']).must_be_nil
  end

  it 'matches comics that set image files explicitly' do
    @site.add_static_file '/images/booga.jpg'
    @site.add_comic '_comics/whatever.html', slug: 'whatever', title: 'greatness', image: '/images/booga.jpg'

    ComicFromImageGenerator.new.generate(@site)

    _(@site.collections['comics'].docs.size).must_equal 1
    comic = @site.collections['comics'].docs.first
    _(comic.data['title']).must_equal 'greatness'
    _(comic.data['image']).must_equal '/images/booga.jpg'
  end
end
