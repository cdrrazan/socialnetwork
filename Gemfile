source "https://rubygems.org"

ruby ">= 3.3"

gem "rails", "~> 8.1.4"

# Database
gem "mysql2", "~> 0.5"

# Web server
gem "puma", ">= 6.0"

# Asset pipeline. Sprockets is kept (rather than Propshaft) because
# ActiveAdmin 3.x and the bootstrap gem compile their Sass through it.
gem "sprockets-rails"
gem "dartsass-sprockets"
gem "bootstrap", "~> 5.3"
gem "jquery-rails" # required by ActiveAdmin

# Hotwire + import maps (replaces Turbolinks, jquery_ujs and CoffeeScript)
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

gem "jbuilder"

# Rails 8 database-backed adapters for cache, jobs and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

gem "bootsnap", require: false

# Active Storage variants (replaces Paperclip)
gem "image_processing", "~> 1.14"

# Authentication / authorization
gem "devise", "~> 5.0"
gem "pundit", "~> 2.5"

# Admin
gem "activeadmin", "~> 3.5"

# Domain features
gem "acts_as_votable", "~> 0.14"
gem "acts-as-taggable-on", "~> 13.0"
gem "public_activity", "~> 3.0"
gem "recaptcha", "~> 5.21"
gem "simple_form", "~> 5.4"

# Post recommendations (TF-IDF cosine similarity)
gem "tf-idf-similarity", "~> 0.3"
gem "matrix" # no longer a default gem since Ruby 3.1

gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "dotenv-rails"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "cuprite"
end
