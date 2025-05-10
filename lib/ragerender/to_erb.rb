require 'strscan'

module RageRender
  NOT_TAGS = /[^\[\]]+/
  IDENT = /[a-zA-Z0-9_]+(\.[a-zA-Z0-9_]+)*/
  TYPE_IDENT = /([clvf]):(#{IDENT})/
  OPENING_TAG = /\[ *(#{TYPE_IDENT}) *(\| *(#{TYPE_IDENT}|#{IDENT}))* *\]/
  CLOSING_TAG = /\[\/\]/

  public
  def to_erb input, output
    scanner = StringScanner.new(input)
    loop do
      break if scanner.eos?

      # If we just have normal content, output it unchanged.
      content = scanner.scan(NOT_TAGS)
      unless content.nil?
        output.write content
        next
      end

      # If we have a tag, output the ERB equivalent.
      content = scanner.scan(OPENING_TAG)
      unless content.nil?
        tokenizer = StringScanner.new(content)
        tokenizer.scan('[')
        type, ident = tokenizer.scan(TYPE_IDENT).split(':')

        case type
        when 'c'
          output.write "<% if #{ident} %>"
        when 'l'
          output.write "<% for #{ident} %>"
        when 'v'
          output.write "<%= #{ident} %>"
        when 'f'
          output.write "<%= #{ident}("
          params = []
          loop do
            break unless tokenizer.scan(/\|/)
            type_ident = tokenizer.scan(TYPE_IDENT)
            unless type_ident.nil?
              type, ident = type_ident.split(':')
              raise ArgumentError, "can\'t run function on type #{type}" unless type == 'v'
              params << ident
              next
            end

            ident_or_literal = tokenizer.scan(IDENT)
            unless ident_or_literal.nil?
              params << ident_or_literal
              next
            end

            raise ArgumentError, "unknown content in function tag #{content}"
          end
          output.write params.join(', ')
          output.write ") %>"
        else
          raise ArgumentError, "unknown tag #{tag}"
        end
        next
      end

      # If we have a closing tag, just output the generic closer
      content = scanner.scan(CLOSING_TAG)
      unless content.nil?
        output.write "<% end %>"
        next
      end

      raise ArgumentError, "unknown content at position #{scanner.pos}, starting with '#{scanner.peek(10)}'"
    end
  end
end

if __FILE__ == $0
  include RageRender
  to_erb ARGF.read, STDOUT
end
