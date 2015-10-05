source 'https://rubygems.org'

gem 'rails', '~> 4.0.0'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'mysql2', '~> 0.3.0'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'libv8', '~> 3.11.8'

  gem 'sass-rails', '~> 4.0.0'
  gem 'coffee-rails'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-ui-rails'
gem 'jquery-rails'

gem 'ancestry'

# To use ActiveModel has_secure_password
gem 'bcrypt-ruby', '~> 3.1.0'

# For the importers
gem 'mail'

# Az ExchageRateLog importnek
gem 'nokogiri'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

group :test do
  gem 'ruby-prof'
  gem 'spork'
  gem 'spork-testunit'
end

# Load plugins' Gemfiles
Dir.glob File.expand_path("../plugins/*/{Gemfile,PluginGemfile}", __FILE__) do |file|
  eval_gemfile file
end
