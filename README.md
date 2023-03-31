# Oxidizer

Oxidizer is a collection of helpers, libraries, and patterns that accelerates the development of your Rails applications by reducing the amount of boilerplate and code needed for controllers and views. Less codes means you'll ship your application faster and be able to iterate more rapidly on user feedback.

It accomplishes this by providing a pattern for Rails shallow routes and a component-first base approach to building applications in Rails. Let's have a closer look.

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

This will add the gems and includes that you need to your project to get going.

```txt
# TODO: Not implemented yet
app/controllers/application_resources_controller.rb
```

## Overview

Oxidizer was designed to be composable, which means you can use different parts of it separately, or all together.

### Rails shallow routes enhancements

There's a lot of [great content](http://weblog.jamisbuck.org/2007/2/5/nesting-resources) written about the importance of [shallow routes](https://guides.rubyonrails.org/routing.html#limits-to-nesting) for building RESTful Rails applications, but the tools Rails gives us out of the box [leaves a lot to be desired](#the-problem-with-rails-shallow-resources).

Oxidizer route helpers make it a little easier to mount your RESTful controllers into your application without much additional magic beyond Rails routing.

#### 🚀 Routes with Oxidizer

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

#### 🐌 Routes before Oxidizer existed

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
  resources :comments, only: %i[create new]
end
```

### Embed Phlex views right in your controller

Build your applications entirely out of Phlex view components, which works great with TailwindCSS. It's not for everybody, but a component-first approach to building applications can make it easier to change things down the road. Best of all? You can still use Rails templates as you always have.

```ruby
# Example Oxidizer controller for comments in a blog post.
class BlogsController
  include Oxidizer::Assignable
  include Oxidizer::Phlexable

  assign :blogs, to: :current_user

  # This implicitly renders for the `index` action
  class Index < Application
    def template
      section do
        h1 { "#{@current_user}'s Blogs" }
        div(class: "flex flex-row gap-20") do
          @blogs.each do |blog|
            div { link_to blog.name, blog }
          end
        end
      end
    end
  end

  # This implicitly renders for the `show` action
  class Show < Application
    def template
      section do
        h1 { @blog.name }
        div(class: "flex flex-row gap-20") do
          @blogs.posts.each do |post|
            div { link_to post.title, post }
          end
        end
      end
    end
  end
end
```

Embedding Phlex views into a controller is a great way to rapidly prototype Rails applications, especially if you already have a set of Phlex components and layouts.

The best part is that it can exist side-by-side with what you already expect from Rails, so you can incrementally upgrade your controllers to be Phlexable or mix Rails views with Phlex views like this:

```ruby
class LegacyBlogsController
  include Oxidizer::Phlexable

  before_filter :load_blog, only: :show

  # This implicitly renders for the `index` action
  class Index < Application
    def template
      section do
        h1 { "#{@current_user}'s Blogs" }
        div(class: "flex flex-row gap-20") do
          @blogs.each do |blog|
            div { link_to blog.name, blog }
          end
        end
      end
    end
  end

  def show
    render :show, layout: "blog_layout"
  end

  private

  def load_blog
    @blog = load_blog
  end
end
```

### Sensible helpers to load and scope data

One of the most tedious parts of building Rails applications is the frequent `before_action :find_resource` code that's in every controller. It gets even more tedious with shallow routes. Oxidizer makes it a one-liner that's compatible with authorization libraries that use ActiveRecord scopes.

```ruby
# Example Oxidizer controller that shows the posts for a users blog.
module Blogs
  class PostsController < ApplicationController
    include Oxidizer::Assignable

    assign :posts, through: :blogs, to: :current_user

    class Index
      h1 { "#{@blog.title} Posts" }
      div(class: "flex flex-col gap-20") do
        @posts.each do |post|
          a(href: url_for(post)) { post.title }
        end
      end
    end
  end
end
```

### Form components built from the ground-up on Phlex

Rails Forms are some of the most boiler-plate heavy parts of building an application. Odidizer streamlines that with a set of form helpers that look and feel like Rails, but are built from the ground up to be composable. That means you could get to a spot with your controllers so that most of your application looks like this:

```ruby
module Posts
  class CommentsController < ApplicationController
    include Oxidizer::Assignable

    assign :comments, through: :posts, to: :current_user

    class Form < ApplicationForm
      def template(&)
        h1 { "#{modify} comment" }
        field :title
        field :text
        submit { "Save comment" }
      end

      def modify
        @model.persisted ? "Create" : "Edit"
      end
    end

    protected
      def permitted_params
        [:title, :text]
      end
  end
end
```

## Prior art

What was Rails like before Oxidizer? The sections below give an overview of the problems Rails presented to give you a better idea of why Oxidizer exists.

### The problem with Rails shallow resources

Rails does a decent job warning us about the perils of shallow routes and even gets us started with the `resources :comments, shallow: true` helper, but as your application grows, it doesn't provide much in the way of code organization and reducing the amount of boiler plate code needed to make this work.

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

## Future projects

In addition to composable views and sane ways of loading data into a controller, Oxidizer will seek to ship a common pattern for handling:

1. Bulk resource selection and manipulation
2. Sorting collections of resources
3. Searching collections of resources
4. Paginating collections of resources

Often, these solutions are re-invented in several gems with slightly different interfaces, which makes it difficult for a common view layer to plug into.

## Contributing

Open issues with reproducible steps.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
