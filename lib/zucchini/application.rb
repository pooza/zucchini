require 'sinatra'
require 'active_support'
require 'active_support/core_ext'
require 'zucchini/slack'
require 'zucchini/config'
require 'zucchini/xml'
require 'zucchini/html'
require 'zucchini/atom/toei'
require 'zucchini/atom/abc'
require 'zucchini/atom/garden'
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
      @renderer = XML.new
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
        @renderer = HTML.new
        @renderer.template_file = 'index.erb'
        return @renderer.to_s
      end
    end

    get '/mechokku' do
      @renderer.status = 302
      redirect @config['application']['external_urls']['mechokku']
    end

    get '/about' do
      @message[:response][:message] = Package.full_name
      @renderer.message = @message
      return @renderer.to_s
    end

    get '/feed/v1.0/site/:site' do
      begin
        @renderer = "Zucchini::#{params[:site].capitalize}Atom".constantize.new
        return @renderer.to_s
      rescue NameError => e
        @renderer = XML.new
        @renderer.status = 404
        @message[:response][:message] = "#{params[:site].capitalize}Atom not found."
        @renderer.message = @message
        return @renderer.to_s
      end
    end

    not_found do
      @renderer = XML.new
      @renderer.status = 404
      @message[:response][:message] = "Resource #{@message[:request][:path]} not found."
      @renderer.message = @message
      return @renderer.to_s
    end

    error do
      @renderer = XML.new
      @renderer.status = 500
      @message[:response][:message] = env['sinatra.error'].message
      @renderer.message = @message
      @slack.say(@message) if @slack
      return @renderer.to_s
    end
  end
end
