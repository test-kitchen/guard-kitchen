source "https://rubygems.org"

# Specify your gem's dependencies in guard-kitchen.gemspec
gemspec development_group: :test
group :test do
  gem "rake"
  gem "guard"
  gem "guard-rspec"
  gem "ruby_gntp"
  gem "rb-inotify", require: false
  gem "rb-fsevent", require: false
  gem "rb-fchange", require: false
end

group :cookstyle do
  gem "cookstyle"
end
