source "https://rubygems.org"

ruby "~> 3.3.3"

# Rails
gem "rails", "~> 7.1.3"
gem "graphql"

# Drivers
gem "pg"

# Web server
gem "puma"

# Ruby extensions
gem "tzinfo-data"
gem "bootsnap", require: false

# Monitoring
gem "newrelic_rpm"

##### Temporary fix for Ruby 3.3.3
# Needed until Ruby 3.3.4 is released https://github.com/ruby/ruby/pull/11006
gem 'net-pop', github: 'ruby/net-pop'
#####

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
  gem "rspec-rails"
  gem "webmock"
  gem "factory_bot_rails"
end

group :development do
end
