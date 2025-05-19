# frozen_string_literal: true

Gem::Specification.new do |spec|
  git = Proc.new do |*args, **flags, &block|
    args = args.push *flags.each_pair.map {|k, v| "--#{k.to_s.gsub(/_/, '-')}=#{v}" }
    IO.popen(['git'].push(*args.map(&:to_s)), chdir: __dir__, err: STDERR) do |pipe|
      unless block.nil?
        block.call(pipe)
      else
        pipe.readlines(chomp: true)
      end
    end
  end

  spec.name = File.basename(__FILE__).scan(/^[^\.]+/).first
  spec.authors = git.call(:log, format: '%an').uniq
  spec.email = git.call(:log, format: '%ae').uniq

  version_tag = 'v?.*'
  nearest = git.call(:tag, '--list', version_tag, sort: 'version:refname').last || 'v0'
  spec.version = nearest[1..]

  readme = (File.read('README.txt') rescue spec.name).split("\n")
  spec.summary = readme.first
  spec.description = readme[1..].join("\n").strip
  spec.homepage = git.call(:remote, :'get-url', 'origin').join
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.license = File.read('LICENSE', external_encoding: 'UTF-8').scan(/\(([A-Z]+)\)/).first.first rescue ''

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = git.call(:'ls-files', '-z') do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\A#{spec.bindir}/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rsec', '~> 1'

  spec.add_development_dependency 'rake', '~> 13'
  spec.add_development_dependency 'minitest', '~> 5'
end
