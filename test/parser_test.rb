require_relative '../lib/ragerender/language'
require_relative 'test_helper'
include RageRender::Language

PARSERS = RageRender::Language::constants
PARSER_RB = File.read File.join(File.dirname(__FILE__), '../lib/ragerender/language.rb')
TEST_CASE_REGEX = /# (#{PARSERS.join('|')}) ([^:]+): ('[^']*'|"[^"]*") => (.*)$/
TEST_DOC_REGEX  = /^\s*#     (.*)$/

describe 'Parser' do
  PARSER_RB.scan(TEST_CASE_REGEX).each do |(parser, desc, input, expected)|
    describe parser do
      it desc do
        assert_equal eval(expected), RageRender::Language.const_get(parser).eof.parse!(eval(input))
      end
    end
  end
end
