require_relative 'test_helper'
require_relative '../lib/ragerender/jekyll'

describe RageRender::FrontpageGenerator.name do
  before do
    @site = FakeSite.new
    @site.add_comic 'latest.html', title: 'Latest', chapter: '2', date: Date.new(2025, 01, 01)
    @site.add_comic 'chapter.html', title: 'Start of latest chapter', chapter: '2', date: Date.new(2024, 06, 01)
    @site.add_comic 'first.html', title: 'First', chapter: '1', date: Date.new(2024, 01, 01)
    @site.add_page File.join(File.dirname(__FILE__), '../'), 'assets', 'archive.html'
    @site.add_page File.join(File.dirname(__FILE__), '../'), 'assets', 'blog.html'
    @site.add_page File.join(File.dirname(__FILE__), '../'), 'assets', 'overview.html'
    File.write File.join(@site.source, 'flibble.html'), "---\nslug: flibble\n---\n"
    @site.add_page @site.source, '', 'flibble.html'
    @site.collections['comics'].send(:sort_docs!)
  end

  after do
    @site.teardown!
  end

  it 'can display the latest comic on the frontpage' do
    @site.config['frontpage'] = 'latest'

    RageRender::FrontpageGenerator.new.generate(@site)

    frontpage = @site.collections['comics'].docs.detect {|c| c.data['slug'] == 'frontpage' }
    _(frontpage).wont_be_nil
    _(frontpage.destination('/')).must_equal File.join(@site.config['destination'], 'index.html')
    _(frontpage.path).must_equal 'latest.html'
  end

  it 'can display the first comic on the frontpage' do
    @site.config['frontpage'] = 'first'

    RageRender::FrontpageGenerator.new.generate(@site)

    frontpage = @site.collections['comics'].docs.detect {|c| c.data['slug'] == 'frontpage' }
    _(frontpage).wont_be_nil
    _(frontpage.destination('/')).must_equal File.join(@site.config['destination'], 'index.html')
    _(frontpage.path).must_equal 'first.html'
  end

  it 'can display the start of the latest chapter on the frontpage' do
    @site.config['frontpage'] = 'chapter'

    RageRender::FrontpageGenerator.new.generate(@site)

    frontpage = @site.collections['comics'].docs.detect {|c| c.data['slug'] == 'frontpage' }
    _(frontpage).wont_be_nil
    _(frontpage.destination('/')).must_equal File.join(@site.config['destination'], 'index.html')
    _(frontpage.path).must_equal 'chapter.html'
  end

  it 'can display the comic archive on the frontpage' do
    @site.config['frontpage'] = 'archive'

    RageRender::FrontpageGenerator.new.generate(@site)

    frontpage = @site.pages.detect {|c| c.data['slug'] == 'frontpage' }
    _(frontpage).wont_be_nil
    _(frontpage.destination('/')).must_equal File.join(@site.config['destination'], 'index.html')
    _(frontpage.path).must_equal 'assets/archive.html'
  end

  it 'can display the blog archive on the frontpage' do
    @site.config['frontpage'] = 'blog'

    RageRender::FrontpageGenerator.new.generate(@site)

    frontpage = @site.pages.detect {|c| c.data['slug'] == 'frontpage' }
    _(frontpage).wont_be_nil
    _(frontpage.destination('/')).must_equal File.join(@site.config['destination'], 'index.html')
    _(frontpage.path).must_equal 'assets/blog.html'
  end

  it 'can display the webcomic overview on the frontpage' do
    @site.config['frontpage'] = 'overview'

    RageRender::FrontpageGenerator.new.generate(@site)

    frontpage = @site.pages.detect {|c| c.data['slug'] == 'frontpage' }
    _(frontpage).wont_be_nil
    _(frontpage.destination('/')).must_equal File.join(@site.config['destination'], 'index.html')
    _(frontpage.path).must_equal 'assets/overview.html'
  end

  it 'can display one of the custom website pages on the frontpage' do
    @site.config['frontpage'] = 'flibble'

    RageRender::FrontpageGenerator.new.generate(@site)

    frontpage = @site.pages.detect {|c| c.data['slug'] == 'frontpage' }
    _(frontpage).wont_be_nil
    _(frontpage.destination('/')).must_equal File.join(@site.config['destination'], 'index.html')
    _(frontpage.path).must_equal 'flibble.html'
  end
end
