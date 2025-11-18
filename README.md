# Restomatic

Better route mappers for Rails applications. Restomatic provides cleaner, more intuitive helpers for defining RESTful routes with proper scoping and namespacing.

## Installation

Add to your Rails application Gemfile:

```ruby
gem "restomatic"
```

Then run:

```bash
bundle install
```

That's it! The routing helpers are automatically available in your `config/routes.rb` file.

## The Problem

Rails provides shallow routes and nested resources, but the syntax becomes verbose and repetitive, especially when you want to properly namespace controllers.

### Before Restomatic

```ruby
resources :blogs do
  scope module: :blogs do
    resources :posts, only: %i[index new create] do
      collection do
        get :search
      end
    end
  end
end

resources :posts do
  scope module: :posts do
    resources :comments, only: %i[new create]
  end
end
```

### With Restomatic

```ruby
resources :blogs do
  nest :posts do
    collection do
      get :search
    end
  end
end

resources :posts do
  create :comments
end
```

Much cleaner! The `nest` helper automatically:
- Scopes to the parent resource's module (e.g., `Blogs::PostsController`)
- Sets sensible defaults for which actions are included
- Reduces boilerplate while maintaining Rails conventions

## Route Helpers

### `nest`

Nest resources under a parent with automatic module scoping and sensible action defaults.

```ruby
resources :blogs do
  nest :posts         # Creates index, new, create actions under Blogs::PostsController
  nest :post          # Singular: creates new, create actions (no edit/update/destroy)
end
```

**Options:**
- `except:` - Exclude specific actions (overrides defaults)
- Singular resources default to excluding: `[:edit, :update, :destroy]`
- Plural resources default to excluding: `[:show, :edit, :update, :destroy]`

**Module-only nesting:**

```ruby
resources :posts do
  nest do
    # Routes defined here will be scoped to Posts module
    # without creating a nested resource
    get :analytics
  end
end
```

### `create`

Define routes for creating a resource (new + create actions only).

```ruby
resources :posts do
  create :comments    # Only new and create actions
end

create :session       # Works with both singular and plural forms
```

### `edit`

Define routes for editing a resource (edit + update actions only).

```ruby
resources :posts do
  edit :metadata      # Only edit and update actions
end
```

### `show`

Define routes for showing a resource (show action only).

```ruby
resources :posts do
  show :preview       # Only show action
end
```

### `destroy`

Define routes for destroying a resource (destroy action only).

```ruby
resources :posts do
  destroy :attachment # Only destroy action
end
```

### `list`

Define routes for listing resources (index action only).

```ruby
resources :users do
  list :posts         # Only index action
end
```

## Real-World Example

```ruby
Rails.application.routes.draw do
  root "home#index"

  # Public blog routes
  resources :blogs, only: [:index, :show] do
    list :posts
  end

  # Admin area with nested resources
  namespace :admin do
    resources :blogs do
      nest :posts do
        create :comments
        collection do
          get :scheduled
          post :bulk_publish
        end
      end
    end

    resources :posts do
      edit :seo
      show :preview
      destroy :featured_image
    end
  end

  # User account management
  resource :account do
    nest do
      edit :profile
      edit :password
      show :billing
    end
  end
end
```

## How It Works

Restomatic extends `ActionDispatch::Routing::Mapper` to add these helper methods. The helpers automatically:

1. Detect singular vs. plural resource names
2. Apply appropriate module scoping
3. Set sensible action defaults based on the helper used
4. Work seamlessly with existing Rails routing features

## Philosophy

Rails routing is powerful but can become verbose when building properly organized applications with shallow routes and namespaced controllers. Restomatic embraces Rails conventions while reducing boilerplate, making your routes file more readable and maintainable.

## Requirements

- Rails 7.0+
- Ruby 3.0+

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).