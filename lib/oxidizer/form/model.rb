module Oxidizer
  module Form
    class Model
      attr_reader :fields, :model

      def initialize(model)
        @model = model
        @fields ||= Hash.new do | hash, key |
          hash[key] = Field.for(model, key, form: self)
        end
      end

      def field(key)
        @fields[key]
      end

      def id
        "#{naming.param_key}_#{object_id}"
      end

      def _method_field_value
        @model.persisted? ? "patch" : "post"
      end

      def naming
        @model.model_name
      end

      def attributes(**attrs)
        attrs.merge(id: id)
      end

      def resource_action
        @model.persisted? ? :update : :create
      end

      def button_text
        "#{@model.persisted? ? "Save" : "Create"} #{naming.human.downcase}"
      end
      alias :submit_value :button_text
    end
  end
end
