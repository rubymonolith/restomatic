require "spec_helper"
require "rails"
require "action_controller/railtie"
require "action_dispatch/railtie"
require "rspec/rails"
require "restomatic"

# Minimal Rails app for testing
class TestApp < Rails::Application
  config.eager_load = false
  config.session_store :cookie_store, key: "_test_session"
  config.secret_key_base = "a" * 30
  config.hosts.clear
  config.logger = Logger.new(nil)
  config.log_level = :fatal
end

# Test controllers
class BlogsController < ActionController::Base
  def index; render plain: "blogs#index"; end
  def show; render plain: "blogs#show"; end
end

module Blogs
  class PostsController < ActionController::Base
    def index; render plain: "blogs/posts#index"; end
    def new; render plain: "blogs/posts#new"; end
    def create; render plain: "blogs/posts#create"; end
  end
end

class PostsController < ActionController::Base
  def show; render plain: "posts#show"; end
  def edit; render plain: "posts#edit"; end
  def update; render plain: "posts#update"; end
end

module Posts
  class CommentsController < ActionController::Base
    def new; render plain: "posts/comments#new"; end
    def create; render plain: "posts/comments#create"; end
  end

  class AttachmentsController < ActionController::Base
    def destroy; render plain: "posts/attachments#destroy"; end
  end

  class MetadataController < ActionController::Base
    def edit; render plain: "posts/metadata#edit"; end
    def update; render plain: "posts/metadata#update"; end
  end

  class PreviewsController < ActionController::Base
    def show; render plain: "posts/previews#show"; end
  end
end

class UsersController < ActionController::Base
  def show; render plain: "users#show"; end
end

module Users
  class PostsController < ActionController::Base
    def index; render plain: "users/posts#index"; end
  end
end

class AccountsController < ActionController::Base
  def show; render plain: "accounts#show"; end
end

module Accounts
  class ProfilesController < ActionController::Base
    def edit; render plain: "accounts/profiles#edit"; end
    def update; render plain: "accounts/profiles#update"; end
  end

  class PasswordsController < ActionController::Base
    def edit; render plain: "accounts/passwords#edit"; end
    def update; render plain: "accounts/passwords#update"; end
  end
end

TestApp.initialize!

# Define routes
TestApp.routes.draw do
  # Test nest with plural resources
  resources :blogs, only: [:index, :show] do
    nest :posts
  end

  # Test create, destroy, edit, and show helpers
  resources :posts, only: [:show] do
    create :comments
    destroy :attachment
    edit :metadata
    show :preview
  end

  # Test list helper
  resources :users, only: [:show] do
    index :posts
  end

  # Test nest with singular resource and module-only block
  resource :account, only: [:show] do
    nest do
      edit :profile
      edit :password
    end
  end
end

RSpec.describe "Restomatic", type: :request do
  describe "nest helper with plural resources" do
    it "creates index route with proper module scoping" do
      get "/blogs/1/posts"
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("blogs/posts#index")
    end

    it "creates new route with proper module scoping" do
      get "/blogs/1/posts/new"
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("blogs/posts#new")
    end

    it "creates create route with proper module scoping" do
      post "/blogs/1/posts"
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("blogs/posts#create")
    end

    it "does not create show route (excluded by default)" do
      get "/posts/1"
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("posts#show")
    end

    it "does not create edit route for nested posts (excluded by default)" do
      get "/blogs/1/posts/1/edit"
      expect(response).to have_http_status(:not_found)
    end

    it "does not create update route for nested posts (excluded by default)" do
      patch "/blogs/1/posts/1"
      expect(response).to have_http_status(:not_found)
    end

    it "does not create destroy route for nested posts (excluded by default)" do
      delete "/blogs/1/posts/1"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "create helper" do
    it "creates new route" do
      get "/posts/1/comments/new"
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("posts/comments#new")
    end

    it "creates create route" do
      post "/posts/1/comments"
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("posts/comments#create")
    end

    it "does not create index route" do
      get "/posts/1/comments"
      expect(response).to have_http_status(:not_found)
    end

    it "does not create show route" do
      get "/posts/1/comments/1"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "destroy helper" do
    it "creates destroy route only" do
      delete "/posts/1/attachment"
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("posts/attachments#destroy")
    end

    it "does not create index route" do
      get "/posts/1/attachment/index"
      expect(response).to have_http_status(:not_found)
    end

    it "does not create show route" do
      get "/posts/1/attachment/show"
      expect(response).to have_http_status(:not_found)
    end

    it "does not create new route" do
      get "/posts/1/attachment/new"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "edit helper" do
    it "creates edit route" do
      get "/posts/1/metadata/edit"
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("posts/metadata#edit")
    end

    it "creates update route" do
      patch "/posts/1/metadata"
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("posts/metadata#update")
    end

    it "does not create index route" do
      get "/posts/1/metadata"
      expect(response).to have_http_status(:not_found)
    end

    it "does not create new route" do
      get "/posts/1/metadata/new"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "show helper" do
    it "creates show route only" do
      get "/posts/1/preview"
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("posts/previews#show")
    end

    it "does not create index route" do
      get "/posts/1/previews"
      expect(response).to have_http_status(:not_found)
    end

    it "does not create new route" do
      get "/posts/1/preview/new"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "list helper" do
    it "creates index route only" do
      get "/users/1/posts"
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("users/posts#index")
    end

    it "does not create new route" do
      get "/users/1/posts/new"
      expect(response).to have_http_status(:not_found)
    end

    it "does not create create route" do
      post "/users/1/posts"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "nest helper with singular resource and module-only block" do
    it "creates edit route for profile with proper module scoping" do
      get "/account/profile/edit"
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("accounts/profiles#edit")
    end

    it "creates update route for profile with proper module scoping" do
      patch "/account/profile"
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("accounts/profiles#update")
    end

    it "creates edit route for password with proper module scoping" do
      get "/account/password/edit"
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("accounts/passwords#edit")
    end

    it "creates update route for password with proper module scoping" do
      patch "/account/password"
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("accounts/passwords#update")
    end
  end

  describe "route helpers" do
    let(:routes) { TestApp.routes.url_helpers }

    it "generates correct path helpers for nested resources" do
      expect(routes.blog_posts_path(1)).to eq("/blogs/1/posts")
      expect(routes.new_blog_post_path(1)).to eq("/blogs/1/posts/new")
    end

    it "generates correct path helpers for create resources" do
      expect(routes.new_post_comments_path(1)).to eq("/posts/1/comments/new")
      expect(routes.post_comments_path(1)).to eq("/posts/1/comments")
    end

    it "generates correct path helpers for list resources" do
      expect(routes.user_posts_path(1)).to eq("/users/1/posts")
    end

    it "generates correct path helpers for edit resources" do
      expect(routes.edit_post_metadata_path(1)).to eq("/posts/1/metadata/edit")
      expect(routes.post_metadata_path(1)).to eq("/posts/1/metadata")
    end

    it "generates correct path helpers for show resources" do
      expect(routes.post_preview_path(1)).to eq("/posts/1/preview")
    end

    it "generates correct path helpers for destroy resources" do
      expect(routes.post_attachment_path(1)).to eq("/posts/1/attachment")
    end

    it "generates correct path helpers for singular nested resources" do
      expect(routes.edit_account_profile_path).to eq("/account/profile/edit")
      expect(routes.account_profile_path).to eq("/account/profile")
    end
  end

  describe "module scoping" do
    it "routes to Blogs::PostsController for nested posts" do
      get "/blogs/1/posts"
      expect(response.body).to eq("blogs/posts#index")
    end

    it "routes to Posts::CommentsController for post comments" do
      post "/posts/1/comments"
      expect(response.body).to eq("posts/comments#create")
    end

    it "routes to Users::PostsController for user posts" do
      get "/users/1/posts"
      expect(response.body).to eq("users/posts#index")
    end

    it "routes to Account::ProfileController for account profile" do
      get "/account/profile/edit"
      expect(response.body).to eq("accounts/profiles#edit")
    end
  end
end
