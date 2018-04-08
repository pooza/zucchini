require 'sinatra'
require 'active_support'
require 'active_support/core_ext'
require 'zucchini/slack'
require 'zucchini/config'
require 'zucchini/html'
require 'zucchini/package'
require 'zucchini/logger'

module Zucchini
  class Application < Sinatra::Base
    def initialize
      super
      @config = Config.instance
      @logger = Logger.new(Package.name)
      @slack = Slack.new if @config['local']['slack']
      @logger.info({
        message: 'starting...',
        package: {
          name: Package.name,
          version: Package.version,
          url: Package.url,
        },
        server: {
          port: @config['thin']['port'],
        },
      })
    end

    before do
      @message = {request:{path: request.path, params:params}, response:{}}
      @renderer = HTML.new
    end

    after do
      @message[:response][:status] ||= @renderer.status
      if (@renderer.status < 400)
        @logger.info(@message)
      else
        @logger.error(@message)
      end
      status @renderer.status
      content_type @renderer.type
    end

    ['/', '/index'].each do |route|
      get route do
        @renderer.template_file = 'index.erb'
        movies = []
        @config['application']['suffixes'].each do |suffix|
          Dir.glob(File.join(@config['local']['dir'], "*#{suffix}")).each do |f|
            movies.push(f)
          end
        end
        @renderer.vars['movies'] = movies
        return @renderer.to_s
      end
    end

    not_found do
      @renderer.status = 404
      @message[:response][:message] = "Resource #{@message[:request][:path]} not found."
      @renderer.template_file = 'not_found.erb'
      @renderer.vars[:message] = @message
      return @renderer.to_s
    end

    error do
      @renderer.status = 500
      @message[:response][:message] = env['sinatra.error'].message
      @renderer.template_file = 'error.erb'
      @renderer.vars[:message] = @message
      @slack.say(@message) if @slack
      return @renderer.to_s
    end
  end
end
