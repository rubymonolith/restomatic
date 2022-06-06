module Resourcefully
  # This controller is designed for a "Weak" resource entity, or the `parent_resource`
  # is the same as the `resource`. This is useful if you want to have complex view logic
  # in place to change a few parameters on a model.
  class NestedWeakResourceController < NestedResourcesController
    def self.resource
      parent_resource
    end

    protected
      # Prevents callbacks from superclasses from firing that `resources`, not `resource`
      # routes fire. This is a non-obvios way to keep the inheritance on the simpler side.
      # TODO: Can I infer a plural vs singular controller in a better way from params? I
      # could look at action names, but those aren't great. Hmm.
      def member_request?
        true
      end

      def find_resource
        parent_resource
      end

      # This is for the `account_layout` helper in all sub-classes.
      def find_account
        parent_resource.account
      end

      def set_new_resource
        # Do nothing; resource is already created, you're
        # just doing something to it.
      end
  end
end