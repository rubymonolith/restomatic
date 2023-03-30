module Oxidizer
  module Form
    # Generates Form attributes for an ActiveRecord model that can be passed into
    # Phlex tags for fun and for profit.
    # TODO: This should handle:
    # * Nested fields
    class Field
      include ActionView::Helpers::FormTagHelper

      def initialize(method:, form: nil)
        @method = method
        @attribute = method.name
        @model = method.receiver
        @form = form
      end

      def id
        "#{naming.param_key}_#{@attribute}_#{object_id}"
      end

      def name
        field_name naming.param_key, @attribute
      end

      def value
        @method.call
      end

      def label
        @attribute.to_s.titleize
      end

      def naming
        @model.model_name
      end

      def form
        @form.id if @form
      end

      def errors
        @model.errors[@attribute]
      end

      def invalid?
        errors.any?
      end

      def validators
        @model.class.validators_on @attribute
      end

      def validation_attributes(**attrs)
        validations = validators.each_with_object Hash.new do |validator, attributes|
          case validator
          when ActiveRecord::Validations::PresenceValidator
            attributes[:required] = true
          end
        end
        attrs.merge(**validations)
      end

      def input_attributes(**attrs)
        attrs.merge(id: id, name: name, value: value).merge(validation_attributes)
      end

      def textarea_attributes(**attrs)
        attrs.merge(id: id, name: name).merge(validation_attributes)
      end

      def label_attributes(**attrs)
        attrs.merge(for: id)
      end

      def self.for(model, attribute, **kwargs)
        new **kwargs.merge(method: model.method(attribute))
      end
    end
  end
end