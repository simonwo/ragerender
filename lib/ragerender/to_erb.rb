require_relative 'language'

module RageRender
  def self.to_erb document
    document.map do |chunk|
      case chunk
      when String
        chunk

      when Language::Variable
        "<%= #{chunk.path.join('.')} %>"

      when Language::Conditional
        rhs = case chunk.rhs
        when String
          "\"#{chunk.rhs}\""
        when Language::Variable
          chunk.rhs.path.join('.')
        when nil
          ""
        end
        "<% if #{chunk.reversed ? 'not ' : ''} #{chunk.lhs.path.join('.')} #{chunk.operator} #{rhs} %>"

      when Language::Function
        params = chunk.params.map do |param|
          case param
          when Language::Variable
            param.path.join('.')
          else
            "\"#{param}\""
          end
        end
        "<%= #{chunk.name}(#{params.join(', ')}) %>"

      when Language::Loop
        "<% for l in #{chunk.path.join('.')} %>"

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
