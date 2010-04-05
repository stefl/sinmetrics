module Sinatra
  require 'digest/md5'
  require 'base64'
  require 'net/http'

  class MixpanelObject
    @@version = 1
    def initialize app
      if app.respond_to?(:options)
        @app = app
        [:api_key, :secret, :token].each do |var|
          instance_variable_set("@#{var}", app.options.send("mixpanel_#{var}"))
        end
      else
        [:api_key, :secret, :token, :request ].each do |var|
          instance_variable_set("@#{var}", app[var]) if app.has_key?(var)
        end
      end
    end

    attr_reader :app
    attr_accessor :api_key, :secret, :token

    def request *args
      if @app
        @app.options.mixpanel_request *args
      else
        @request.call *args
      end
    end
    
    def log_event(event, user_id, opts = {})      
      options = {}
      options['ip'] = @app.request.ip if @app
      options['time'] = Time.now.to_i
      options['token'] = token
      options['distinct_id'] = user_id if user_id
      opts.each do |key, value|
        if [:step].include? key
          options[key.to_s] = value.to_i
        else
          options[key.to_s] = value.to_s
        end
      end
      
      data = ::Base64.encode64( { 'event' => event, 'properties' => options }.to_json ).gsub(/\n/, '')
      data = "#{data}&ip=1" if options.has_key? 'ip'
      request "http://api.mixpanel.com/track/?data=#{data}"
    end

    def log_funnel(funnel_name, step_number, step_name, user_id, opts = {})
      funnel_opts = opts.merge({:funnel => funnel_name, :step => step_number, :goal => step_name})
      log_event("mp_funnel", user_id, funnel_opts)
    end

  end

  module MixpanelHelper
    def mixpanel
      env['mixpanel.helper'] ||= MixpanelObject.new(self)
    end
    
    alias mp mixpanel
  end
  
  class MixpanelSettings
    def initialize app, &blk
      @app = app
      @app.set :mixpanel_api_key, nil
      @app.set :mixpanel_secret, nil
      @app.set :mixpanel_request, Proc.new { |url| Net::HTTP.get(URI.parse(url)) }
      instance_eval &blk
    end
    %w[ api_key secret token request ].each do |param|
      class_eval %[
        def #{param} val, &blk
          @app.set :mixpanel_#{param}, val
        end
      ]
    end
  end

  module Mixpanel
    def mixpanel &blk
      MixpanelSettings.new(self, &blk)
    end
    
    def self.registered app
      app.helpers MixpanelHelper
    end
  end
  
  Application.register Mixpanel  
end

Mixpanel = Sinatra::MixpanelObject
