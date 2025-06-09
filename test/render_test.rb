require 'erb'
require 'cgi/escape'
require 'liquid'
require_relative 'test_helper'
require_relative '../lib/ragerender/language'
require_relative '../lib/ragerender/to_liquid'
require_relative '../lib/ragerender/to_erb'

TESTS = {
  # literals
  'normal string' => 'normal string',
  # variables
  '[v:missing]' => '',
  '[v:three]' => '3',
  '[v:title]' => 'RageRender',
  # functions
  '[f:add|v:three|2]' => '5',
  '[f:subtract|v:three|2]' => '1',
  '[f:multiply|2|v:three]' => '6',
  '[f:divide|18|v:three]' => '6',
  '[f:js|v:code]' => '&lt;br/&gt;',
  # comparisons
  '[c:three=3]pass[/]' => 'pass',
  '[c:three=4]fail[/]' => '',
  '[c:three!=1]pass[/]' => 'pass',
  '[c:three!=3]fail[/]' => '',
  '[c:three>2]pass[/]' => 'pass',
  '[c:three>3]fail[/]' => '',
  '[c:three>=3]pass[/]' => 'pass',
  '[c:three>=4]fail[/]' => '',
  '[c:three<4]pass[/]' => 'pass',
  '[c:three<3]fail[/]' => '',
  '[c:three<=3]pass[/]' => 'pass',
  '[c:three<=2]fail[/]' => '',
  # case insensitive
  '[c:title~ragerender]pass[/]' => 'pass',
  '[c:title~magemender]fail[/]' => '',
  '[c:title!~ragerender]fail[/]' => '',
  '[c:title!~magemender]pass[/]' => 'pass',
  # modulo
  '[c:three%3]pass[/]' => 'pass',
  '[c:three%2]fail[/]' => '',
  '[c:three!%3]fail[/]' => '',
  '[c:three!%2]pass[/]' => 'pass',
  # loops
  '[l:array][v:l.iteration][/]' => '012',
  '[l:array][v:l.aiteration][/]' => '123',
  '[l:array][c:l.is_first][v:l.value][/][/]' => 'a',
  '[l:array][c:l.is_last][v:l.value][/][/]' => 'c',
}

VARIABLES = {
  'three' => 3,
  'title' => 'RageRender',
  'code'  => '<br/>',
  'array' => [{'value' => 'a'}, {'value' => 'b'}, {'value' => 'c'}],
}

class TestTemplate < Struct.new(*VARIABLES.keys.map(&:to_sym))
  include CGI::Escape
  alias js escapeHTML

  V = Struct.new(:value)

  def array
    super.map {|h| V.new h['value'] }
  end

  def render input
    erb = RageRender.to_erb(Language.parse StringIO.new(input)).join
    template = ERB.new(erb)
    template.result(binding)
  end
end

describe 'Rendering' do
  TESTS.each do |input, output|
    it "renders #{input.inspect} into Liquid #{output.inspect}" do
      liquid = RageRender.to_liquid(Language.parse StringIO.new(input)).join
      template = Liquid::Template.parse liquid
      _(template.render(VARIABLES)).must_equal output
    end

    it "renders #{input.inspect} into ERB #{output.inspect}" do
      _(TestTemplate.new(*VARIABLES.values).render(input)).must_equal output
    end
  end
end
