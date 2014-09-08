source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~>4.1'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Gems needed for our applications ------------------------------------

# Mongodb support - using master, since 3.0.5 does not support Rails 4
gem 'mongoid', "~> 4.0.0.beta1", git: 'git://github.com/mongoid/mongoid.git'
gem 'bson_ext'

# UI Related Gems
gem 'foundation-rails'
gem 'will_paginate_mongoid'
gem 'foundation-icons-sass-rails'

# Strip white spaces from the end of attributes
gem 'strip_attributes'

# Authentication and Authorization
gem 'devise', "~> 3.0"
gem 'cancan', "~> 1.6"

# Paperclip GEM for handling file attachments
gem "mongoid-paperclip", :require => "mongoid_paperclip"
gem 'aws-sdk'

# GEM for reading environment variables from a configuration file
gem 'figaro'

# Stripe GEM for interacting with stripe.com payment service
gem 'stripe'

# Rspec, Cucumber and Webrat GEMs for TDD/BDD
group :test, :development do
	gem "factory_girl_rails"
	gem 'rspec-rails'
	gem "capybara"
	gem 'pry-nav'
	gem 'pry-rails', :group => :development
	gem "webrat"
  gem "database_cleaner"
  gem "vcr"
  gem "webmock"
end

# This needs to be installed so we can run Rails console on OpenShift directly
gem 'minitest'

# ---------------------------------------------------------------------

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]
