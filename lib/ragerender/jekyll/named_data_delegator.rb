module RageRender
  module NamedDataDelegator
    def def_data_delegator key, aliaz
      define_method(aliaz.to_sym) do
        @obj.data[key.to_s]
      end
    end
  end
end
