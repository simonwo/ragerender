require 'erb'
require 'liquid'
require_relative 'test_helper'
require_relative '../lib/ragerender/language'
require_relative '../lib/ragerender/functions'
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
  '[f:js|v:code]' => '"Some words\u003Cbr\/\u003E\n\nSome more words\u003Cscript\u003Esome code\u003C\/script\u003E"',
  '[f:js|"\'<>✅]' => '"\u0022\u0027\u003C\u003E\u2705"',
  '[f:js|v:html]' => '"\u0026lt;p\u0026gt;Wicked wango is a fun \u0026#039;game\u0026#039;.\u0026lt;\/p\u0026gt;"',
  '[f:removehtmltags|v:code]' => "Some words\n\nSome more words",
  # escaping: language should not do any automatic escaping
  '[v:text]' => 'Text with \'apostrophes\' and "quotes"',
  '[v:html]' => '&lt;p&gt;Wicked wango is a fun &#039;game&#039;.&lt;/p&gt;',
  '[f:removehtmltags|v:text]' => 'Text with \'apostrophes\' and "quotes"',
  '[f:removehtmltags|v:html]' => '&lt;p&gt;Wicked wango is a fun &#039;game&#039;.&lt;/p&gt;',
  '[f:rawhtml|v:text]' => 'Text with \'apostrophes\' and "quotes"',
  '[f:rawhtml|v:html]' => '<p>Wicked wango is a fun \'game\'.</p>',
  # comicfury won't escape entities in literal text
  '[f:removehtmltags|Literal text with \'apostrophes\']' => 'Literal text with \'apostrophes\'',
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
  '[c:three=v:three]pass[/]' => 'pass',
  '[c:three!=v:three]fail[/]' => '',
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
  # random
  '[f:randomnumber|1|3]' => /^(1|2|3)$/,
  '[f:randomnumber|1|v:three]' => /^(1|2|3)$/,
}

VARIABLES = {
  'three' => 3,
  'title' => 'RageRender',
  'code'  => "Some words<br/>\n\nSome more words<script>some code</script>",
  'text'  => "Text with 'apostrophes' and \"quotes\"",
  'html'  => "&lt;p&gt;Wicked wango is a fun &#039;game&#039;.&lt;/p&gt;",
  'array' => [{'value' => 'a'}, {'value' => 'b'}, {'value' => 'c'}],
}

class TestTemplate < Struct.new(*VARIABLES.keys.map(&:to_sym))
  include RageRender::TemplateFunctions

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
  before do
    Liquid::Template.error_mode = :strict
    Liquid::Template.register_filter(RageRender::TemplateFunctions)
  end

  TESTS.each do |input, expected|
    it "renders #{input.inspect} using Liquid into #{expected.inspect}" do
      liquid = RageRender.to_liquid(Language.parse StringIO.new(input)).join
      template = Liquid::Template.parse liquid
      output = template.render!(VARIABLES, strict_filters: true)

      case expected
      when String
        _(output).must_equal expected
      when Regexp
        _(output).must_match expected
      else
        raise 'Unknown test type'
      end
    end

    it "renders #{input.inspect} using ERB into #{expected.inspect}" do
      output = TestTemplate.new(*VARIABLES.values).render(input)

      case expected
      when String
        _(output).must_equal expected
      when Regexp
        _(output).must_match expected
      else
        raise 'Unknown test type'
      end
    end
  end
end
