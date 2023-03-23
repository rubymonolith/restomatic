module Oxidizer
  module Form
    extend ActiveSupport::Concern

    def initialize(model:)
      @model = model
    end

    def template
      form_tag do
        form_template
      end
    end

    def fields
      form_model.fields.values
    end

    def field(name)
      form_model.field(name)
    end

    def form_tag(**attrs, &)
      form **form_model.attributes(method: "post", action: action, **attrs) do
        authenticity_token_field
        _method_field
        yield
      end
    end

    def action
      helpers.url_for(action: form_model.resource_action)
    end

    def authenticity_token_field
      input(type: :hidden, name: :authenticity_token, value: helpers.form_authenticity_token)
    end

    def _method_field
      input(name: "_method", type: :hidden, value: form_model._method_field_value)
    end

    def default_button_text
      form_model.button_text
    end

    private

    def form_model
      @form_model ||= Form::Model.new(@model)
    end
  end
end
