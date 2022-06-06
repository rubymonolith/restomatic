module Resourcefully
  # Controller for nesting a singular resource within a parent resource. This
  # should only be used for creating a new resource within the scope of the parent
  # resource, or to redirect to the un-nested resource location if it exists.
  class NestedResourceController < NestedResourcesController
    def show
      # Disabled for show because show will only redirect to either
      # the new resource or to the existing resource, which both have
      # authorizations of their own. I did this here and not as a `skip_after_filter`
      # to add safety for a future engineer who might try to incorrectly override
      # this action and render the resource. If that happened, authorization would
      # be disabled for them, which wouldn't be great.
      skip_authorization
      redirect_to resource.present? ? existing_resource_url : new_resource_url
    end

    protected
      def existing_resource_url
        url_for resource
      end

      def new_resource_url
        url_for action: :new
      end

      # A single nested resource should only have one resource under
      # the scope of the parent resources.
      def find_resource
        resources.first
      end
  end
end