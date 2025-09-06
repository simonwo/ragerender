require 'digest'
require_relative 'language'

module RageRender
  LIQUID_FUNCTIONS = {
    'add' => proc {|f| [Language::Function.new('plus', f.params)] },
    'subtract' => proc {|f| [Language::Function.new('minus', f.params)] },
    'multiply' => proc {|f| [Language::Function.new('times', f.params)] },
    'divide' => proc {|f| [Language::Function.new('divided_by', f.params)] },
    'removehtmltags' => proc {|f| Language::Function.new('strip_html', f.params) },
  }

  def self.render_value value, literals
    case value
    when String
      case value
      when /^[0-9]+$/
        value
      when /"'/
        literals[value]
      else
        "\"#{value}\""
      end
    when Language::Variable
      if value.path.first == 'l' && value.path.last == 'iteration'
        'forloop.index0'
      elsif value.path.first == 'l' && value.path.last == 'aiteration'
        'forloop.index'
      else
        value.path.join('.')
      end
    when Language::Function
      params = value.params.map {|p| render_value p, literals }
      args = params.drop(1).map {|p| "#{value.name}: #{p}" }.join(' | ')
      [params.first, args.empty? ? value.name : args].join(' | ')
    when nil
      ""
    end
  end

  def self.to_liquid document
    tag_stack = Array.new
    literals = Hash.new {|cache, l| cache[l] = "str" + Digest::MD5.hexdigest(l)}

    chunks = document.map do |chunk|
      case chunk
      when String
        chunk

      when Language::Variable
        "{{ #{render_value chunk, literals} }}"

      when Language::Conditional
        tag_stack << (chunk.reversed ? :endunless : :endif)

        lhs = render_value chunk.lhs, literals
        rhs = render_value chunk.rhs, literals
        operator = chunk.operator

        if chunk.lhs.is_a?(Language::Variable) && chunk.lhs.path.first == "l"
          case chunk.lhs.path.last
          when "is_first", "is_last"
            lhs = "forloop.#{chunk.lhs.path.last[3..]}"
          when "is_even", "is_odd"
            lhs = 'forloop.index0'
            rhs = '2'
            operator = (chunk.lhs.path.last == 'is_even' ? '%' : '!%')
          end
        end

        output = Array.new
        case operator
        when '~', '!~'
          # case insensitive comparison: we need to manually do this
          output << "{% assign lhs = #{lhs} | downcase %}"
          output << "{% assign rhs = #{rhs} | downcase %}"
          lhs = "lhs"
          rhs = "rhs"
          operator = {'~' => '==', '!~' => '!='}[operator]
        when '%', '!%'
          # modulo comparison with zero
          output << "{% assign lhs = #{lhs} | modulo: #{rhs} %}"
          lhs = "lhs"
          rhs = "0"
          operator = {'%' => '==', '!%' => '!='}[operator]
        end

        operator = (operator == '=' ? '==' : operator)
        output << "{% #{chunk.reversed ? 'unless' : 'if'} #{lhs} #{operator} #{rhs} %}"
        output.join

      when Language::Function
        *output, func = LIQUID_FUNCTIONS.fetch(chunk.name, proc{|f| f}).call(chunk)
        output << "{{ #{render_value(func, literals)} }}"
        output.join

      when Language::Loop
        tag_stack << :endfor
        "{% for l in #{chunk.path.join('.')} %}"

      when Language::Layout
        "{{ #{chunk.name} }}"

      when Language::EndTag
        if tag_stack.empty?
          '[/]'
        else
          "{% #{tag_stack.pop.to_s} %}"
        end
      end
    end

    literals.map do |(value, name)|
      "{% capture #{name} %}#{value}{% endcapture %}"
    end + chunks
  end
end

if __FILE__ == $0
  puts RageRender.to_liquid(RageRender::Language::parse(ARGF)).join
end
