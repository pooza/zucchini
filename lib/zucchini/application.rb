require 'sinatra'
require 'active_support'
require 'active_support/core_ext'
require 'zucchini/config'
require 'zucchini/package'

module Zucchini
  class Application < Sinatra::Base
    set :public, File.join(ROOT_DIR, 'public')
    set :views, File.join(ROOT_DIR, 'views')

    def initialize
      super
      @config = Config.instance
    end

    get '/' do
      @package = Package.to_h
      @movies = []
      @config['application']['suffixes'].each do |suffix|
        Dir.glob(File.join(ROOT_DIR, "public/movie/*#{suffix}")).each do |f|
          f.sub!(File.join(ROOT_DIR, 'public'), '')
          @movies.push(f)
        end
      end
      erb :index
    end

    not_found do
      status 404
      "Not found."
    end

    error do
      status 500
      env['sinatra.error'].message
    end
  end
end
