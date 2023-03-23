module Oxidizer
  module Form
    module StrongParams
      extend ActiveSupport::Concern

      included do
        prepend Extensions
      end

      module Extensions
        def field(name)
          if permitted_keys.include? name
            super(name)
          else
            fail "Unpermitted form field: #{name}"
          end
        end
      end

      def permitted_keys
        self.class.permitted_keys
      end

      module ClassMethods
        def permit(*keys)
          permitted_keys.append *keys
        end

        def permitted_keys
          @permitted_keys ||= []
        end

        def permitted_params(**kwargs)
          case kwargs.to_a
            in [[param_key, params]]
              params.require(param_key).permit(permitted_keys)
          end
        end
      end
    end
  end
end
