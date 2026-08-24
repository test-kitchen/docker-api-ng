# frozen_string_literal: true

require "bundler/gem_tasks"

require "rake/testtask"

Rake::TestTask.new(:unit) do |t|
  t.libs.push "lib", "spec", "tools"
  t.test_files = FileList["spec/**/*_spec.rb"].exclude("spec/integration/**/*")
  t.verbose = false
  t.warning = false
end

desc "Run the integration suite against a real Docker daemon"
Rake::TestTask.new(:integration) do |t|
  t.libs.push "lib", "spec", "tools"
  t.test_files = FileList["spec/integration/**/*_spec.rb"]
  t.verbose = false
  t.warning = false
end

desc "Run all unit tests"
task test: %i{unit}

desc "Run the unit tests with coverage reporting"
task :coverage do
  ENV["COVERAGE"] = "1"
  Rake::Task[:unit].invoke
end

begin
  require "cookstyle/chefstyle"
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:style) do |task|
    task.options += ["--display-cop-names", "--no-color"]
  end
rescue LoadError
  puts "cookstyle is not available. (sudo) gem install cookstyle to do style checking."
end

begin
  require "yard"
  YARD::Rake::YardocTask.new(:doc)

  desc "Report YARD documentation coverage"
  task :doc_stats do
    sh "yard stats --list-undoc"
  end

  desc "Fail if any public method is undocumented"
  task :doc_coverage do
    # Documentation that is merely encouraged is documentation that rots. The
    # generated layer is excluded in .yardopts because its docs come from the
    # specification and are verified by regenerating, not by reading.
    output = `yard stats --list-undoc 2>&1`
    puts output

    undocumented = output[/^\s*Undocumented Objects:\s*(\d+)/, 1].to_i
    abort "#{undocumented} undocumented public objects. Document them, or mark them @api private." if undocumented > 0
  end
rescue LoadError
  puts "yard is not available. (sudo) gem install yard to generate documentation."
end

Dir.glob("tasks/*.rake").each { |r| load r }

task default: %i{style test}
