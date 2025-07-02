require 'rsec'
require 'strscan'

module RageRender
  module Language
    extend Rsec::Helpers

    Variable = Struct.new 'Variable', :path
    Loop = Struct.new 'Loop', :path
    Conditional = Struct.new 'Conditional', :reversed, :lhs, :operator, :rhs
    Function = Struct.new 'Function', :name, :params
    Layout = Struct.new 'Layout', :name
    EndTag = Struct.new 'EndTag'

    def self.optional p, default=nil
      p | ''.r.map {|_| default}
    end

    TEXT = /[^\[\]\|\<\>]+/.r

    # IDENT parses names: 'names' => 'names'
    # IDENT parses underscores: 'underscore_name' => 'underscore_name'
    # IDENT parses numbers: 'name_with_1_number' => 'name_with_1_number'
    # IDENT parses capitals: 'name_with_Capital' => 'name_with_Capital'
    IDENT = /[a-zA-Z0-9_]+/.r

    # PATH parses names: 'names' => ['names']
    # PATH parses dotted paths: 'dotted.name' => ['dotted', 'name']
    PATH = IDENT.join('.'.r).even

    OPERATOR = %w{= != ~ !~ <= >= < > % !%}.map(&:r).reduce {|a, b| a | b }

    # VARIABLE parses names: 'v:name' => Variable.new(['name'])
    # VARIABLE parses dotted paths: 'v:dotted.name' => Variable.new(['dotted', 'name'])
    VARIABLE = ('v:'.r >> PATH).map {|path| Variable.new path }
    LOOP = ('l:'.r >> PATH).map {|path| Loop.new path }

    # CONDITIONAL tests for truthiness: 'c:variable' => Conditional.new(false, Variable.new(['variable']), nil, nil)
    # CONDITIONAL tests for falsiness: 'c:!variable' => Conditional.new(true, Variable.new(['variable']), nil, nil)
    # CONDITIONAL tests for equality: 'c:variable=My comic about bees' => Conditional.new(false, Variable.new(['variable']), '=', 'My comic about bees')
    # CONDITIONAL tests for inequality: 'c:variable!=My comic about bees' => Conditional.new(false, Variable.new(['variable']), '!=', 'My comic about bees')
    # CONDITIONAL tests for greater than: 'c:variable>=3' => Conditional.new(false, Variable.new(['variable']), '>=', '3')
    # CONDITIONAL tests against two variables: 'c:variable=v:other' => Conditional.new(false, Variable.new(['variable']), '=', Variable.new(['other']))
    CONDITIONAL = ('c:'.r >> seq_(
      /!?/.r.map {|c| c == '!' },
      PATH.map {|p| Variable.new(p) },
      optional(OPERATOR),
      optional(VARIABLE | TEXT))
    ).map {|(reversed, lhs, operator, rhs)| Conditional.new reversed, lhs, operator, rhs }

    # FUNCTION with no arguments: 'f:cowsay' => Function.new("cowsay", [])
    # FUNCTION with a variable argument: 'f:js|v:foo' => Function.new('js', [Variable.new(['foo'])])
    # FUNCTION with literal arguments: 'f:add|2|3' => Function.new('add', ['2', '3'])
    FUNCTION = ('f:'.r >> seq(IDENT, ('|'.r >> (VARIABLE | TEXT)).star)).map {|(name, params)| Function.new name, params }

    # TAG matches variable tags: '[v:value]' => Variable.new(["value"])
    # TAG matches loop tags: '[l:loop]' => Loop.new(["loop"])
    # TAG matches conditional tags: '[c:authorname=Simon W]' => Conditional.new(false, Variable.new(['authorname']), '=', 'Simon W')
    # TAG matches function tags: '[f:js|v:dench]' => Function.new('js', [Variable.new(['dench'])])
    TAG = '['.r >> (VARIABLE | CONDITIONAL | LOOP | FUNCTION) << ']'.r

    # LAYOUT_TAG with content: '<!--layout:[content]-->' => Layout.new('content')
    # LAYOUT_TAG with css: '<!--layout:[css]-->' => Layout.new('css')
    LAYOUT_TAG = ('<!--layout:['.r >> IDENT << ']-->'.r).map {|(name)| Layout.new name }

    # END_TAG matches, er, end tags: '[/]' => EndTag.new
    END_TAG = '[/]'.r.map {|_| EndTag.new }

    DOCUMENT = (TAG | END_TAG | LAYOUT_TAG | TEXT | /[\[\]\|\<\>]/.r).star.eof

    def self.parse io
      DOCUMENT.parse! io.read
    end
  end
end

if __FILE__ == $0
  puts RageRender::Language::parse(ARGF).inspect
end
