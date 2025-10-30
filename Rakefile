# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

begin
  require 'yard'
  
  YARD::Rake::YardocTask.new(:doc) do |t|
    t.files = ['lib/**/*.rb']
    t.options = ['--output-dir', 'doc', '--readme', 'README.md']
  end

  desc 'Generate and preview YARD documentation in browser'
  task :'docs:preview' do
    sh 'yard server --reload --port 8808'
  end
rescue LoadError
  # YARD not available
end
