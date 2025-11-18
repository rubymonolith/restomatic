module ActionDispatch::Routing
  # I have no idea how or why this works this way, I lifted the pattern from Devise, which came with even
  # more weird stuff. Rails could use an API for adding route helpers to decrease the brittleness of this
  # approach. For now, deal with this helper.
  class Mapper
    def nest(name = nil, *args, except: nil, **kwargs, &block)
      unless resource_scope?
        raise ArgumentError, "can't use nest outside resource(s) scope"
      end

      if name.nil?
        scope module: parent_module_name, &block
      elsif is_singular_resource_name? name
        scope module: parent_module_name do
          except ||= %i[edit update destroy]
          resource name, *args, except: except, **kwargs, &block
        end
      else
        scope module: parent_module_name do
          except ||= %i[show edit update destroy]
          resources name, *args, except: except, **kwargs, &block
        end
      end
    end

    def create(name, *args, **kwargs, &block)
      if resource_scope? && !@scope[:module]
        scope module: parent_module_name do
          resource name, *args, only: %i[new create], **kwargs, &block
        end
      else
        resource name, *args, only: %i[new create], **kwargs, &block
      end
    end

    def edit(name, *args, **kwargs, &block)
      if resource_scope? && !@scope[:module]
        scope module: parent_module_name do
          resource name, *args, only: %i[edit update], **kwargs, &block
        end
      else
        resource name, *args, only: %i[edit update], **kwargs, &block
      end
    end

    def show(name, *args, **kwargs, &block)
      if resource_scope? && !@scope[:module]
        scope module: parent_module_name do
          resource name, *args, only: :show, **kwargs, &block
        end
      else
        resource name, *args, only: :show, **kwargs, &block
      end
    end

    def destroy(name, *args, **kwargs, &block)
      if resource_scope? && !@scope[:module]
        scope module: parent_module_name do
          resource name, *args, only: :destroy, **kwargs, &block
        end
      else
        resource name, *args, only: :destroy, **kwargs, &block
      end
    end

    def index(name, *args, **kwargs, &block)
      if resource_scope? && !@scope[:module]
        scope module: parent_module_name do
          resources name, *args, only: :index, **kwargs, &block
        end
      else
        resources name, *args, only: :index, **kwargs, &block
      end
    end

    private

    def parent_module_name
      # For singular resources (resource :account), Rails uses plural controller names (AccountsController)
      # So we need to pluralize the parent resource name for the module scope
      parent_resource.singular ? parent_resource.name.to_s.pluralize : parent_resource.name
    end

    def is_singular_resource_name?(name)
      name_string = name.to_s
      name_string.singularize == name_string
    end

    def resource_plurality(name)
      is_singular_resource_name?(name) ? :resource : :resources
    end

    def inflect_resource_plurality(name, *args, **kwargs, &)
      self.method(resource_plurality(name)).call(name, *args, **kwargs, &)
    end
  end
end
