require 'sinatra'
require 'active_support'
require 'active_support/core_ext'
require 'zucchini/config'
require 'zucchini/package'
require 'streamio-ffmpeg'

class File
  def self.binary_size (path)
    size = File.size(path)
    i = 0
    ['', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB'].each do |unit|
      unitsize = 1024 ** i
      if size < (unitsize * 1024 * 2)
        return "#{(size / unitsize).floor.commaize}#{unit}"
      end
      i += 1
    end
  end
end

class Integer
  def commaize
    return self.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')
  end
end

module Zucchini
  class Application < Sinatra::Base
    helpers do
      include Rack::Utils
      alias_method :h, :escape_html
    end

    set :public, File.join(ROOT_DIR, 'public')
    set :views, File.join(ROOT_DIR, 'views')

    def initialize
      super
      @config = Config.instance
    end

    get '/' do
      @params = params
      @package = Package.to_h
      @movies = []
      @config['application']['suffixes'].each do |suffix|
        Dir.glob(File.join(ROOT_DIR, "public/movie/*#{suffix}")).each do |f|
          next if (params['q'].present? && !File.basename(f).include?(params['q']))
          movie = FFMPEG::Movie.new(f)
          @movies.push({
            binary_size: File.binary_size(f),
            size: File.size(f),
            name: File.basename(f),
            href: f.sub(File.join(ROOT_DIR, 'public'), ''),
            path: f,
            width: movie.width,
            height: movie.height,
            duration: movie.duration,
          })
        end
      end
      erb :index
    end

    not_found do
      status 404
      'Not found.'
    end

    error do
      status 500
      env['sinatra.error'].message
    end
  end
end
