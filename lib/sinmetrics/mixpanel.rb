module Sinatra
  require 'digest/md5'
  require 'net/http'

  class MixpanelObject
    @@version = 1
    def initialize app
      @app = app
    end

    attr_reader :app
    [ :api_key, :secret, :token, :request ].each do |var|
      class_eval %[
        def #{var}=(val)
          @app.set :mixpanel_#{var}, val
        end
        def #{var} *args
          @app.options.mixpanel_#{var} *args
        end
      ]
    end
    
    def log_event(event, user_id, opts = {})      
      options = {}
      options['ip'] = @app.request.ip
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
      
      data = Base64.encode64( { 'event' => event, 'properties' => options }.to_json ).gsub(/\n/, '') + "&ip=1"
      request( data )
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
      @app.set :mixpanel_request, Proc.new { |data| Net::HTTP.get(URI.parse("http://api.mixpanel.com/track/?data=#{data}")) }
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
