module Oxidizer
  class NestedResourcesController < ResourcesController
    before_action :assign_parent_resource_instance_variable
    before_action :assign_resources_instance_variable, only: :index
    before_action :authorize_parent_resource

    helper_method :parent_resource

    protected
      def self.parent_resource
        raise NotImplementedError, "NestedResourcesController.parent_resource must be an ActiveModel or ActiveRecord class"
      end

      def resources
        @_resources ||= order_resource_scope nested_resource_scope
      end

      # Use callbacks to share common setup or constraints between actions.
      def assign_parent_resource_instance_variable
        instance_variable_set("@#{parent_resource_name}", parent_resource)
      end

      def parent_resource
        @_parent_resource ||= find_parent_resource
      end

      def find_parent_resource
        self.class.parent_resource.find_resource params[parent_resource_id_param]
      end

      # Finds the account of the resource depending on the request type and
      # the parent resource.
      def find_account
        if member_request?
          resource.account
        elsif parent_resource.is_a? Account
          parent_resource
        else
          parent_resource.account
        end
      end

      # If we're deep, we want to show only members that are scoped
      # from within an index.
      def nested_resource_scope
        query = {}
        query[parent_resource_foreign_key] = parent_resource
        resource_scope.where(**query)
      end

      # Assumes the route key is the foreign key, which is usually the case.
      # This can be overridden if its not the case or the `nested_resource_scope`
      # can be over-ridden.
      def parent_resource_id_param
        parent_resource_foreign_key
      end

      # Key used to find the parent resource via ActiveRecord. Typically this is the primary key of the record,
      # but it would be a different field if you don't want to expose users to primary keys.
      def parent_active_record_id
        :id
      end

      # If the user doesn't have `show?` priviledge on the parent resource,
      # then its highly likely they won't be authorized to do anything with
      # the child resource. This isn't 100% true, but I'm having a hard time
      # thinking of a practical edge case.
      def authorize_parent_resource
        authorize parent_resource, :show?
      end

    private
      def resource_params
        # Optionally allow the resource params because nested resources usually
        # allow a POST request with no params that create a resource.
        if params.key? resource_name
          params.require(resource_name).permit(permitted_params)
        end
      end

      # Gets the resource name of the ActiveRecord model for use by
      # instance methods in this controller.
      def parent_resource_name
        self.class.parent_resource.model_name.singular
      end

      def parent_resource_foreign_key
        "#{parent_resource_name}_id".to_sym
      end
  end
end