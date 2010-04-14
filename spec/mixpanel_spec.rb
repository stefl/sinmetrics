require 'spec_helper'

describe 'Sinatra Mixpanel' do  

  it 'should be configurable standalone' do
    mp = Mixpanel.new :token => "abcdefghijklmnopqrstuvwyxz"
  end
  
  it 'should be configurable w/in sinatra' do
    class MixpanelApp < Sinatra::Base
      register Sinatra::Mixpanel
      mixpanel do
        token "abcdefghijklmnopqrstuvwyxz"
      end
    end
    
    app = MixpanelApp.new
  end
end  
  