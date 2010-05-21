class Abingo::Alternative
  include Abingo::ConversionRate
  include DataMapper::Resource

  property :id, Serial
  property :content, String
  property :lookup, String, :length => 32, :index => true
  property :weight, Integer, :default => 1
  property :participants, Integer, :default => 0
  property :conversions, Integer, :default => 0

  belongs_to :experiment
end