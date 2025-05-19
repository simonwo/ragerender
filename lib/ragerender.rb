require_relative 'ragerender/language'
require_relative 'ragerender/to_liquid'
require_relative 'ragerender/to_erb'

if defined?(Jekyll)
  require_relative 'ragerender/jekyll'
end
