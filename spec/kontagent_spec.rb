require 'spec_helper'

describe 'Sinatra Kontagent' do
  
  it 'should be configurable standalone' do
    kontagent = Kontagent.new :api_key => '1234', :secret => '5678'
  end
  
  it 'should be configurable w/in sinatra' do
    class KontagentApp < Sinatra::Base
      register Sinatra::Kontagent
      kontagent do
        api_key "1234"
        secret  "5678"
      end
    end
    
    app = KontagentApp.new
  end
    
  
end  
  