# Oxidizer

There's a lot of [great content](http://weblog.jamisbuck.org/2007/2/5/nesting-resources) written about the importance of [shallow routes](https://guides.rubyonrails.org/routing.html#limits-to-nesting) for building RESTful Rails applications, but the tools Rails gives us out of the box [leaves a lot to be desired](#the-problem-with-rails-shallow-resources).

## How Oxidizer overcomes the shortcomings of Rails shallow routes

Oxidizer delivers on the original promise of Rails: convention over configuration. Here's how it delivers on that.

1. Infer model scopes from controller names and scopes.
2. More intuitive route helpers that better describe the relationship of a sub-resource to its parent resource.

### Controllers

Here's what a typical oxidizer resource controller looks like:

#### 🚀 Controllers with Oxidizer
```ruby
# Example Oxidizer controller for comments in a blog post.
module Posts
  class CommentsController < Oxidizer::NestedResourcesController
    protected
      def assign_attributes
        resource.user = current_user
        resource.post = parent_resource
      end

      def permitted_params
        [:post_id, :body]
      end
  end
end
```

It looks like there's a lot of magic going on, but there's not. It's all accomplished via inheritance. Here's what the controller above looks like when its expanded out.

| :fire: Did you get burned by Inherited Resources? |
|:--------------------------------------------------|
| Me too! [Read about how Inherited Resources is different](#inherited-resources) and not really based on inheritance. |


#### 🐌 Manually implementing the methods that Oxidizer provides

```ruby
# Here's what it would look like if you implemented most of the boiler plate above in a controller without using Oxidizer.
module Posts
  class CommentsController < ApplicationController
    def self.resource
      Comment
    end

    def self.parent_resource
      Post
    end

    def create
      self.resource = resource_class.new(resource_params)
      assign_attributes

      respond_to do |format|
        if resource.save
          format.html { redirect_to create_redirect_url, notice: create_notice }
          format.json { render :show, status: :created, location: resource }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: resource.errors, status: :unprocessable_entity }
        end
      end
    end

    protected
      def assign_attributes
        resource.user = current_user
        resource.post = parent_resource
      end

      def permitted_params
        [:post_id, :body]
      end

      def create_redirect_url
        url_for(action: :create)
      end

      def create_notice
        "#{parent_resource.class.name} was create"
      end

      def resource_class
        resource
      end

      def parent_resource
        @parent_resource ||= find_parent_resource
      end

      def find_parent_resource
        self.class.parent_resource.find_resource params[parent_resource_id_param]
      end

      def parent_resource_id_param
        "#{parent_resource_name}_id".to_sym
      end
  end
end
```

Since there's no DSLs, its easy to extend Oxidizer controllers to implement any type of behavior you need in your controllers if the default behavior doesn't suit your needs.

### Routing

Similar to Oxidizer controllers, Oxidizer route helpers make it a little easier to mount your RESTful controllers into your application without much additional magic beyond Rails routing.

#### 🚀 Routes with Oxidizer
```ruby
resources :items do
  get :search, to: "items/searches#index"
  nest :children do
    collection do
      get :templates
    end
  end
  list :ancestors
  edit :icon
  create :labels
  create :copies
  create :batches
  create :movement
  create :loanable, controller: "loanable_items"
end
```

Here's what the fully expanded routes would look like if you did them all manually by yourself.

#### 🐌 Routes before Oxidizer existed

```ruby
resources :items do
  get :search, to: "items/searches#index"
  scope module: :items do
    resources :children, only: %i[index new create] do
      collection do
        get :templates
      end
    end
    resources :ancestors, only: %i[index]
    resources :labels, only: %i[create]
    resources :copies, only: %i[create new]
    resources :batches, only: %i[new create]
    resource :icon, only: %i[edit update]
    resource :movement, only: %i[new create]
    resource :loanable, only: %i[new create], controller: "loanable_items"
    template_resources :containers, :items, :perishables
  end
end
```

Again, Oxidizer makes it easy to eject from its abstractions into vanilla Rails if you need to change a few things within your application.

## The problem with Rails shallow resources

Rails does a good job warning us about the perils of shallow routes and even gets us started with the `resources :comments, shallow: true` helper, but as your application grows, it doesn't provide much in the way of code organization and reducing the amount of boiler plate code needed to make this work.

Let's start by looking a typical Rails routes file.

```ruby
resources :posts
  # Creates a comment on `Post.find(params[:post_id]).comments.create`
  resources :comments, shallow: true
end

resources :users do
  # We want to display comments for each user via `User.find(params[:user_id]).comments`
  resources :comments, only: :index
end
```

If you use shallow routes, both `resources :comments` entries point to the `CommentsController`. This is where things start getting crazy—what if you want to display different views for each scope but it's pointing to the same controller?

You could implement a conditional within the `CommentsController` that checks for the presence of different ids.

```ruby
# Don't do this!
def show
  if params.key? :post_id
    render "comment_post"
  elsif params.key? :user_id
    render "user_post"
  else
    render "show"
  end
end
```

Don't do that! Having conditions like this is code smell that each scope needs its own controller, which means we break apart `CommentsController` into `Posts::CommentsController` in `./app/controllers/posts/comments_controller.rb` and `Users::CommentsControllers` in `./app/controllers/users/comments_controller.rb`. It eliminates the crazy conditional above, but then it forces us to generate lots of resource controllers with routing entries that don't make a ton of sense.

```ruby
resources :posts
  scope module: :posts do
    # Creates a comment on `Post.find(params[:post_id]).comments.create`
    resources :comments, only: %w[new create index]
  end
end

resources :users do
  scope module: :users do
    # We want to display comments for each user via `User.find(params[:user_id]).comments`
    resources :comments, only: :index
  end
end
```

Then in our controllers we're writing finders like this all over the place:

```ruby
module Posts
  class CommentsController
    before_action :assign_post

    def new
      @post = Post.new
    end

    def create
      @post = Post.new(params)
      if @post.save
        redirect_to @post
      else
        render "new" # Show the form error
      end
    end

    def index
      @comments = @post.comments
    end

    protected

    def assign_post
      @post = Post.find params[:post_id]
    end
  end
end
```

Why are we writing so much code to do something that we should be able to infer from the name of the controller and what's up with the verbosity of our routes file? Gah!

## Oxidizer tries to solve even more shortcomings with Controllers

In addition giving developers "convention over configuration" for Rails shallow resources, Oxidizer aims to give us interfaces between views and controllers.

### Interfaces between controllers and views for common controller concerns

1. Bulk resource selection and manipulation
2. Sorting collections of resources
3. Searching collections of resources
4. Paginating collections of resources

Often, these solutions are re-invented in several gems with slightly different interfaces, which makes it difficult for a common view layer to plug into.

### More composable views

Additionally, inheritance of views leaves a lot to be desired. Oxidizer will provide a sane set of `view_paths` per controller such that your nested `Posts::CommentsController#show` view would first look in `./views/posts/comments/show.html.erb` and then `./views/posts/show.html.erb` if the more deeply nested view is not found.

The project will also look into more radical ways to compose UI's with the [Phlex](https://phlex.fun) project to make the Rails controller & view stack even more composable.

## Getting Started

Add to your Rails application Gemfile by executing:

```bash
bundle add "oxidizer"
```

Then run:

```bash
# TODO: Not implemented yet
rails generate oxidizer:install
```

This will create the folders and files needed to get going with Oxidizer.

```txt
# TODO: Not implemented yet
app/controllers/application_resources_controller.rb
```

The application resources controller is actually a few controllers. You can split them out, but to start its easiest to keep them in one file.

```ruby
class Resources < ApplicationController
  include Oxidizer::ResourceCollection

  class Resource < Resources
    include Oxidizer::SingularResource
  end

  class NestedResource < Resource
    include Oxidizer::NestedResource
  end

  class NestedWeakResource < Resource
    include Oxidizer::NestedWeakResource
  end
end
```

## Concepts

Oxidizer makes it easy to build RESTful Rails applications that follow the CRUD controller pattern and shallow routes.

## Controller types

There's a few types of controllers you'll want to use:

### ResourcesController

The most common type of controller is a resources controller. Its very much like a vanilla RESTful Rails controller where `index` is the collection of resources and `new`, `create`, `show`, `edit`, `update`, and `destroy` operate on the singular resource.

For example, a blog web application might have a `Posts` Resources controller.

### ResourceController

Similar to above, but does not have an `index` action. Singular resources are commonly used in web applications for managing the current users profile and associated resources.

For example, a blog web application might have a `Session` Resource controller that the user can create when they login and destroy when they log out.

### NestedResources

Nested resources are designed to be scoped within a `Resources`. They have `new`, `create`, and `index` actions, but do not have the remaining actions. The remaining CRUD actions for a nested resource should be `Resources` controller.

For example, a blog's `Post` resources might have many `Comment` resources per post. The creation of the comment is within the context of the `Post` resource. After the `Comment` resource is created, the `Post` should be persisted in the `Comment` (probably as `comments.post_id`) if it needs to be accessible after its persisted.

It's possible to have the other CRUD actions in a nested resource, but its discourage since nesting controller scopes can be difficult to maintain as dependencies and business logic change. Best to keep themn flat.

### NestedResource

A nested resources is similar to the nested resources, but is singular. For example, a `Post` may have an `Author` resource at `posts/:id/author`. The singular nested resource supports the full range of CRUD actions, but does not have `index`.

### NestedWeakResource

A nested weak resource is on where the underlying resource is the same as the parent resource.

For example, a `Post` may require a confirmation screen before its deleted available at `posts/:id/delete_confirmation/new`. The user would press the `Confirm deletion` button on that screen which would `POST` to `/posts/:id/delete_confirmation` and destroy the object.

## Contributing

Open issues with reproducible steps.

## Compared to other gems

During the development of this gem, some of these other libraries were mentioned as "similar gems", so I evaluate each one to make sure I'm not implementing the same thing or communicate "how its different this time".

### [Inherited Resources](https://github.com/activeadmin/inherited_resources)

> Sounds a bit like inherited_resources tbh?
>
> I get the feeling I’ve already been there and didn’t like it in the end.

[@julian_rubisch](https://twitter.com/julian_rubisch/status/1587186996879007747?s=61&t=gOFfW6GtJqGs5ETPy_nsog)

Yeah, I've been there too! I used the Inherited Resources gem once for an admin panel and found it difficult to do things around inheritance.

Take for example this:

```ruby
# Code from InheritedResources
class AccountsController < InheritedResources::Base
  defaults :resource_class => User, :collection_name => 'users', :instance_name => 'user'
end
```

That's not really inheritance; rather, it's a class method DSL that configures instances methods. Why not just modify the instance methods themselves?

That's how Oxidizer does it:

```ruby
class AccountsController < ApplicationResourcesController
  def self.resource
    User
  end

  def resource_name
    "user"
  end

  def resources_name
    "users"
  end
end
```

It's inheritance how you'd expect it to work; not a DSL.

Additionally, Inherited Resources made it difficult to "eject" from the abstraction. One of the key principals of the Oxidizer project is to make it easy to break out of abstractions that no longer work and solve the problem with Rails or Plain 'ol Ruby objects.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
