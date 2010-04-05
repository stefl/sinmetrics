begin
  require 'sinatra/base'
rescue LoadError
  retry if require 'rubygems'
  raise
end

module Sinatra
  require 'digest/md5'
  require 'net/http'

  class KontagentObject
    @@version = 1
    def initialize app
      @app = app
    end

    attr_reader :app
    [ :api_key, :secret, :env, :request ].each do |var|
      class_eval %[
        def #{var}=(val)
          @app.set :kontagent_#{var}, val
        end
        def #{var} *args
          @app.options.kontagent_#{var} *args
        end
      ]
    end

    class APIProxy
      Types = %w[ 
        ins inr
        nts ntr
        nes nei
        pst psr
        apa apr
        ucc
        pgr
        cpu
        gci
        mtu
      ]
    end

    APIProxy::Types.each do |n|
      class_eval %[
        def #{n}_url args
          make_url '#{n}', args
        end
        def #{n} args = {}
          request( #{n}_url( args ) ) unless env == :test
        end
      ]
    end
    
    def base_url
      case env
      when :production ; 'http://api.geo.kontagent.net/api'
      else ;             'http://api.test.kontagent.com/api'
      end
    end
    
    def make_url method, args = {}
      args = { :ts => Time.now.getgm.strftime("%Y-%m-%dT%H:%M:%S") }.merge(args)
      sorted = args.map{ |k,v|
                       next nil unless v
                       next nil if k == :url_only
                       "#{k}=" + case v
                                  when Array
                                    v.join('%2C')
                                  else
                                    v.to_s
                                  end
                     }.compact.sort

      sorted << "an_sig=" + Digest::MD5.hexdigest(sorted.join+self.secret)
      query = sorted.map{|v| v.gsub('&', '%26').gsub(' ', '+')}.join('&')
      "#{base_url}/v#{@@version}/#{api_key}/#{method}/?#{query}"
    end
  end

  module KontagentHelper
    def kontagent
      env['kontagent.helper'] ||= KontagentObject.new(self)
    end
    
    alias kt kontagent
  end
  
  class KontagentSettings
    def initialize app, &blk
      @app = app
      @app.set :kontagent_env, @app.environment
      @app.set :kontagent_request, Proc.new { |url| Net::HTTP.get( URI.parse(url) ) }
      instance_eval &blk
    end
    %w[ api_key secret env request ].each do |param|
      class_eval %[
        def #{param} val, &blk
          @app.set :kontagent_#{param}, val
        end
      ]
    end
  end

  module Kontagent
    def kontagent &blk
      KontagentSettings.new(self, &blk)
    end
    
    def self.registered app
      app.helpers KontagentHelper
    end
  end
  
  Application.register Kontagent  
end
