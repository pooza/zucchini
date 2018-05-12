ROOT_DIR = File.expand_path(__dir__)
$LOAD_PATH.push(File.join(ROOT_DIR, 'lib'))
ENV['BUNDLE_GEMFILE'] ||= File.join(ROOT_DIR, 'Gemfile')

require 'bundler/setup'
require 'fileutils'
require 'zucchini/config'

@config = Zucchini::Config.instance

[:start, :stop, :restart].each do |action|
  desc "#{action} thin"
  task action => ["server:#{action}"]
end

namespace :server do
  [:start, :stop, :restart].each do |action|
    task action do
      sh "thin --config config/thin.yaml #{action}"
    end
  end
end

namespace :link do
  desc 'update symbolic link'
  task update: [:delete, :create]

  task :delete do
    FileUtils.rm(path) if File.symlink?(path)
  end

  task :create do
    File.symlink(@config['local']['dir'], path) unless File.exist?(path)
  end

  def path
    return File.join(ROOT_DIR, 'public/movie')
  end
end
