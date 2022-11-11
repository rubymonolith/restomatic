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
        scope module: parent_resource.name, &block
      elsif is_singular_resource_name? name
        scope module: parent_resource.name do
          except ||= %i[index edit update destroy]
          resource name, *args, except: except, **kwargs, &block
        end
      else
        scope module: parent_resource.name do
          except ||= %i[show edit update destroy]
          resources name, *args, except: except, **kwargs, &block
        end
      end
    end

    def create(name, *args, **kwargs, &block)
      inflect_resource_plurality name, *args, only: %i[new create], **kwargs, &block
    end

    def edit(name, *args, **kwargs, &block)
      inflect_resource_plurality name, *args, only: %i[edit update], **kwargs, &block
    end

    def show(name, *args, **kwargs, &block)
      inflect_resource_plurality name, *args, only: :show, **kwargs, &block
    end

    def destroy(name, *args, **kwargs, &block)
      inflect_resource_plurality name, *args, only: :destroy, **kwargs, &block
    end

    def list(name, *args, **kwargs, &block)
      inflect_resource_plurality name, *args, only: :index, **kwargs, &block
    end

    private

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
