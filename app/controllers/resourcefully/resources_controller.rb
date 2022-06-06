module Resourcefully
  class ResourcesController < ApplicationController
    before_action :authenticate_user
    before_action :assign_resource_instance_variable, if: :member_request?
    before_action :authorize_resource, if: :member_request?
    before_action :assign_resources_instance_variable, only: :index

    helper_method \
      :resource_name,
      :resource_class,
      :resource,
      :resources,
      :navigation_key,
      :created_resource,
      :updated_resource

    # These are used to contain the serialized IDs for resources so they can
    # be accessed from views on the other side of the action that's performed.
    add_flash_types :created_resource, :updated_resource

    def self.resource
      raise NotImplementedError, "ResourcesController.resource must be an ActiveModel or ActiveRecord class"
    end

    def index
    end

    def show
    end

    def new
      assign_new_resource
      assign_attributes
      authorize_resource
    end

    def edit
    end

    def create
      self.resource = resource_class.new(resource_params)
      assign_attributes
      authorize_resource

      respond_to do |format|
        if resource.save
          flash_created_resource
          format.html { redirect_to create_redirect_url, notice: create_notice }
          format.json { render :show, status: :created, location: resource }
          create_success_formats format
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: resource.errors, status: :unprocessable_entity }
        end
      end
    end

    def update
      resource.assign_attributes(resource_params)
      assign_attributes
      authorize_resource

      respond_to do |format|
        if resource.save
          flash_updated_resource
          format.html { redirect_to update_redirect_url, notice: update_notice }
          format.json { render :show, status: :ok, location: resource }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: resource.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      resource.destroy

      respond_to do |format|
        format.html { redirect_to destroy_redirect_url, notice: destroy_notice }
        format.json { head :no_content }
      end
    end

    protected
      def member_request?
        params.key? resource_id_param
      end

      def collection_request?
        !member_request?
      end

      # Gets the resource name of the ActiveRecord model for use by
      # instance methods in this controller.
      def resource_name
        resource_class.model_name.singular
      end

      def resources_name
        resource_class.model_name.plural
      end

      def resource_class
        self.class.resource
      end

      # Permitted params the resource controller allows
      def permitted_params
        []
      end

      # A scope used for collections scoped by Pundit auth.
      def resource_scope
        policy_scope.joins(:user)
      end

      # `policy_scope` is defined by Pundit.
      def policy_scope(scope = resource_class)
        super(scope)
      end

      # Sets instance variable for templates to match the model name. For
      # example, `Account` model name would set the `@accounts` instance variable
      # for template access.
      def assign_resources_instance_variable
        instance_variable_set("@#{resources_name}", resources)
      end

      # A hook that allows sub-classes to assign attributes to a model.
      def assign_attributes
        resource.user = current_user if resource.respond_to? :user=
      end

      # Redirect to this url after a resource is created
      def create_redirect_url
        resource
      end

      # Redirect to this url after a resource is updated
      def update_redirect_url
        resource
      end

      # Redirect to this url after a resource is destroyed
      def destroy_redirect_url
        resources_name.to_sym
      end

      # Key rails routing uses to find resource. Rails resources defaults to the `:id` value.
      def resource_id_param
        :id
      end

      # Use callbacks to share common setup or constraints between actions.
      def assign_resource_instance_variable
        instance_variable_set("@#{resource_name}", resource)
      end

      def resource
        @_resource ||= find_resource
      end

      # Sometimes we need to set the resource to hack the controller from another method, such as the
      # case of setting the instance variable to be an instance of a model.
      def resource=(value)
        @_resource = value
        assign_resource_instance_variable
      end

      # Finds resource, which is called by `assign_resource` to assign it to the right variables.
      def find_resource
        resource_class.find_resource params[resource_id_param]
      end

      # Initializes a model for the `new` action.
      def assign_new_resource
        self.resource = resource_class.new
      end

      def resources
        @_resources ||= resource_scope
      end

      # Additional formats can be specified for successful response creations
      def create_success_formats(format)
      end

      # Authorizse resource with Pundit.
      def authorize_resource(*args)
        authorize resource, *args
      end

      # `flash[:notice]` message when a resource is successfully created
      def create_notice
        "#{notice_resource_name} created"
      end

      # `flash[:notice]` message when a resource is successfully updated
      def update_notice
        "#{notice_resource_name} updated"
      end

      # `flash[:notice]` message when a resource is successfully deleted
      def destroy_notice
        "#{notice_resource_name} deleted"
      end

      # What do you call the things that are created?
      def notice_resource_name
        resource_name.humanize.capitalize
      end

      # Get the current account of the resource, if possible.
      def find_account
        resource.account if member_request?
      end

    private
      # Never trust parameters from the scary internet, only allow the white list through.
      def resource_params
        params.require(resource_name).permit(permitted_params)
      end

      # Assign global_id to resource that was just created. This is used in subsequent
      # screens to display a link or information about the resource that was just created.
      def flash_created_resource
        flash[:created_resource] = resource_global_uri
      end

      # Resource that was created from the last action.
      def created_resource
        @created_resource ||= GlobalID::Locator.locate flash[:created_resource]
      end

      # Assign global_id to resource that was just created. This is used in subsequent
      # screens to display a link or information about the resource that was just created.
      def flash_updated_resource
        flash[:updated_resource] = resource_global_uri
      end

      # Generates a GlobalID object that can be serialized into flash for the next action to
      # pickup and find the object as an updated or created resource. The reason this check
      # exists is because some resources are ApplicationModels (NOT Records) and don't have
      # a way to find via ActiveRecord queries.
      def resource_global_uri
        resource.to_global_id.uri if resource.respond_to? :to_global_id
      end

      # Resource that was updated from the last action.
      def updated_resource
        @updated_resource ||= GlobalID::Locator.locate flash[:updated_resource]
      end
  end
end