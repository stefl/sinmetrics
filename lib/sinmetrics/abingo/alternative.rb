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

  def self.calculate_lookup(abingo, test_name, alternative_name)
    Digest::MD5.hexdigest(abingo.salt + test_name + alternative_name.to_s)
  end

  def self.score_conversion(abingo, test_name)
    viewed_alternative = abingo.find_alternative_for_user(test_name,
      Abingo::Experiment.alternatives_for_test(abingo, test_name))
    all(:lookup => self.calculate_lookup(abingo, test_name, viewed_alternative)).adjust!(:conversions => 1)
  end

  def self.score_participation(abingo, test_name)
    viewed_alternative = abingo.find_alternative_for_user(test_name,
      Abingo::Experiment.alternatives_for_test(abingo, test_name))
    all(:lookup => self.calculate_lookup(abingo, test_name, viewed_alternative)).adjust!(:participants => 1)
  end

end