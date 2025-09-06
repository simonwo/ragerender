require_relative 'language'

module RageRender
  ERB_OPERATORS = {
    'add' => '+',
    'subtract' => '-',
    'multiply' => '*',
    'divide' => '/',
  }

  def self.to_erb document
    document.map do |chunk|
      case chunk
      when String
        chunk

      when Language::Variable
        if chunk.path == ['l', 'aiteration']
          '<%= (index+1) %>'
        elsif chunk.path == ['l', 'iteration']
          '<%= index %>'
        else
          "<%= #{chunk.path.join('.')} rescue nil %>"
        end

      when Language::Conditional
        lhs = chunk.lhs.path.join('.')
        rhs = case chunk.rhs
        when Language::Variable
          chunk.rhs.path.join('.')
        when /^[0-9]+$/
          chunk.rhs
        when String
          "\"#{chunk.rhs}\""
        when nil
          ""
        end

        lhs, rhs, operator = case chunk.operator
        when '='
          [lhs, rhs, '==']
        when '%', '!%'
          ["#{lhs} % #{rhs}", 0, if chunk.operator[0] == '!' then '!=' else '==' end]
        when '~', '!~'
          ["#{lhs}.downcase", "#{rhs}.downcase", if chunk.operator[0] == '!' then '!=' else '==' end]
        else
          [lhs, rhs, chunk.operator]
        end

        if chunk.lhs.is_a?(Language::Variable) && chunk.lhs.path.first == "l"
          case chunk.lhs.path.last
          when "is_first", "is_last"
            lhs = "index"
            rhs = {"is_first" => "0", "is_last" => "(forloop.size - 1)"}[chunk.lhs.path.last]
            operator = "=="
          when "is_even", "is_odd"
            lhs = 'index % 2'
            rhs = '0'
            operator = {'is_even' => '==', 'is_odd' => '!='}[chunk.lhs.path.last]
          end
        end

        "<% if #{chunk.reversed ? 'not ' : ''} #{lhs} #{operator} #{rhs} %>"

      when Language::Function
        params = chunk.params.map do |param|
          case param
          when Language::Variable
            param.path.join('.')
          when /^[0-9]+$/
            param
          else
            "\"#{param.gsub(/['"]/) {|c| "\\" + c}}\""
          end
        end

        if ERB_OPERATORS.include? chunk.name
          "<%= #{params.join(ERB_OPERATORS[chunk.name])} %>"
        else
          "<%= #{chunk.name}(#{params.join(', ')}) %>"
        end

      when Language::Loop
        "<% #{chunk.path.join('.')}.each_with_object(#{chunk.path.join('.')}).each_with_index do |(l, forloop), index| %>"

      when Language::Layout
        "<%= #{chunk.name} %>"

      when Language::EndTag
        '<% end %>'
      end
    end
  end
end

if __FILE__ == $0
  puts RageRender.to_erb(RageRender::Language::parse(ARGF)).join
end
