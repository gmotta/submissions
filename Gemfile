# encoding: utf-8
source 'https://rubygems.org'
ruby '2.3.1'

def linux_only(require_as)
  RbConfig::CONFIG['host_os'] =~ /linux/ ? require_as : false
end
# Mac OS X
def darwin_only(require_as)
  RbConfig::CONFIG['host_os'] =~ /darwin/ ? require_as : false
end

gem 'rails', '~> 4.2' # TODO: 5.0 needs konacha > 4.0.0 and lol_dba > 2.0.3
gem 'haml', '~> 4.0'
gem 'will_paginate', '~> 3.1'
gem 'formtastic', '3.1.4'
gem 'devise', '~> 4.0'
gem 'devise-encryptable', '0.2.0'
gem 'devise-i18n', '~> 1.0'
gem 'localized_country_select', '0.9.11'
gem 'brhelper', '3.3.0'
gem 'seed-fu', '~> 2.3'
gem 'acts-as-taggable-on', '~> 4.0'
gem 'cancancan', '~> 1.10'
gem 'acts_as_commentable', '4.0.2'
gem 'state_machine', '1.2.0'
gem 'validates_existence', '0.9.2'
gem 'airbrake', '~> 5.0'
gem 'aws-ses', '0.6.0', require: 'aws/ses'
gem 'mysql2', '~> 0.4'
gem 'doorkeeper', '~> 3.1' # TODO: Remove
gem 'newrelic_rpm'
gem 'paperclip', '~> 5.0'

gem 'jquery-rails', '~> 4.0'
gem 'sass-rails', '~> 5.0'
gem 'coffee-rails', '~> 4.1'
gem 'jquery-ui-rails', '~> 5.0'
gem 'therubyracer', '0.12.2'
gem 'yui-compressor', '~> 0.12'
gem 'fancybox-rails', '~> 0.3'
gem 'uglifier', '~> 3.0'
gem 'modernizr-rails'

gem 'goalie', git: 'https://github.com/hugocorbucci/goalie.git'

platforms :ruby do
  gem 'RedCloth', '~> 4.3', require: 'redcloth'
end

group :development do
  gem 'capistrano', '3.6.1', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-rvm', require: false
  gem 'travis-lint'
  gem 'foreman'
  gem 'bullet'
  gem 'lol_dba' # TODO: Rails 5.0 needs lol_dba > 2.0.3
  gem 'byebug'
  gem 'web-console'
  gem 'dotenv-rails', require: false
  gem 'rubocop', require: false
  gem 'rack-livereload'
end

group :test do
  gem 'mocha'
  gem 'shoulda-matchers'
  gem 'email_spec'
  gem 'codeclimate-test-reporter', require: nil
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'sqlite3'
  gem 'rspec-rails'
  gem 'rspec-its'
  gem 'rspec-collection_matchers'
  gem 'guard-rspec'
  gem 'guard-livereload'
  gem 'pry-rails'
  gem 'rb-fsevent', require: darwin_only('rb-fsevent')
  gem 'terminal-notifier-guard', require: darwin_only('terminal-notifier-guard')
  gem 'rb-inotify', require: linux_only('rb-inotify')
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'konacha' # TODO: Rails 5.0 needs konacha > 4.0.0
  gem 'guard-konacha-rails'
  gem 'poltergeist', require: 'capybara/poltergeist'
  gem 'selenium-webdriver'
  gem 'brakeman'
  gem 'timecop'
  gem 'factory_girl_rails'
  gem 'faker'
end
