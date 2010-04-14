require 'spec_helper'

describe 'Sinatra Abingo' do
  
  it 'should be configurable standalone' do
    ab = Abingo.new :identity => 'abcd'
  end
  
  it 'should be configurable w/in sinatra' do
    class AbingoApp < Sinatra::Base
      register Sinatra::Abingo
      abingo do
        identity 'abcd'
      end
    end
  
    app = AbingoApp.new
  end
  
  it 'should be able to create a new test'
  it 'should be able to call flip for a new test'

end  
  