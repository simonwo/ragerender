require_relative 'named_data_delegator'

Jekyll::Hooks.register :pages, :pre_render do |page, payload|
  if page.data['layout'] == 'error-page'
    payload.merge! RageRender::ErrorDrop.new(page).to_liquid
  end
end

module RageRender
  class ErrorDrop < Jekyll::Drops::Drop
    private delegate_method_as :data, :fallback_data
    extend NamedDataDelegator
    extend Forwardable

    def_data_delegator :title, :errortitle
    def_delegator :@obj, :content, :errormessage
  end
end
