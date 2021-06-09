require "rake/testtask"
require 'pathname'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
	t.verbose = false
  t.warning = false
end

task :default => :test
