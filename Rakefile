require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:test) do |t|
  t.pattern = "spec/**/*_spec.rb"
end

# Documentation is generated on demand and deliberately not part of the
# default task -- doc warnings should never fail a build.
begin
  require "yard"

  YARD::Rake::YardocTask.new(:doc) do |task|
    task.stats_options = ["--list-undoc"]
  end
rescue LoadError
  desc "Generate YARD documentation (yard is not installed)"
  task :doc do
    abort "yard is not available. Run `bundle install` to install it."
  end
end

task default: %i{test}
