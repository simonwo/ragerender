require_relative 'language'

module RageRender
  LIQUID_FUNCTIONS = {
    'add' => 'plus',
    'subtract' => 'minus',
    'multiply' => 'times',
    'divide' => 'divided_by',
    'js' => 'escape', # TODO: check these do the same thing!
  }

  def self.render_value value
    case value
    when String
      value =~ /^[0-9]+$/ ? value : "\"#{value}\""
    when Language::Variable
      if value.path.first == 'l' && value.path.last == 'iteration'
        'forloop.index0'
      elsif value.path.first == 'l' && value.path.last == 'aiteration'
        'forloop.index'
      else
        value.path.join('.')
      end
    when nil
      ""
    end
  end

  def self.to_liquid document
    tag_stack = Array.new

    document.map do |chunk|
      case chunk
      when String
        chunk

      when Language::Variable
        "{{ #{render_value chunk} }}"

      when Language::Conditional
        tag_stack << (chunk.reversed ? :endunless : :endif)

        lhs = render_value chunk.lhs
        rhs = render_value chunk.rhs
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
        params = chunk.params.map {|p| render_value p }
        name = LIQUID_FUNCTIONS.fetch(chunk.name, chunk.name)
        args = params.drop(1).map {|p| "#{name}: #{p}" }.join(' | ')
        "{{ #{params.first} | #{args.empty? ? name : args} }}"

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
  end
end

if __FILE__ == $0
  puts RageRender.to_liquid(RageRender::Language::parse(ARGF)).join
end
