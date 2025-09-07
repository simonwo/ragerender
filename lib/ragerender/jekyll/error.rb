require_relative 'pipettes'

Jekyll::Hooks.register :pages, :pre_render do |page, payload|
  if page.data['layout'] == 'error-page'
    RageRender::Pipettes.clean_payload payload
    payload.merge! RageRender::ErrorDrop.new(page).to_liquid
  end
end

module RageRender
  class ErrorDrop < Jekyll::Drops::Drop
    private delegate_method_as :data, :fallback_data
    extend Pipettes
    extend Forwardable

    def_data_delegator :title, :errortitle
    def_delegator :@obj, :content, :errormessage
  end
end
