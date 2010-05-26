class Abingo::Experiment
  include DataMapper::Resource
  include Abingo::Statistics
  include Abingo::ConversionRate

  property :test_name, String, :key => true
  property :status, String
  property :short_circuit, String
  
  has n, :alternatives, "Alternative"

  def cache_keys
  ["Abingo::Experiment::exists(#{test_name})".gsub(" ", "_"),
    "Abingo::Experiment::#{test_name}::alternatives".gsub(" ","_"),
    "Abingo::Experiment::short_circuit(#{test_name})".gsub(" ", "_")
  ]
  end
  
  def before_destroy
    cache_keys.each do |key|
      Abingo.cache.delete key
    end
    true
  end

  def participants
    alternatives.sum(:participants)
  end

  def conversions
    alternatives.sum(:conversions)
  end

  def best_alternative
    alts = Array.new alternatives.each { |a| a }
    alts.max do |a,b|
      a.conversion_rate <=> b.conversion_rate
    end
  end

  def self.start_experiment!(abingo, test_name, alternatives_array)
    cloned_alternatives_array = alternatives_array.clone
    Abingo::Experiment.transaction do |txn|
      experiment = Abingo::Experiment.first_or_create(:test_name => test_name)
      experiment.alternatives.destroy  #Blows away alternatives for pre-existing experiments.
      while (cloned_alternatives_array.size > 0)
        alt = cloned_alternatives_array[0]
        weight = cloned_alternatives_array.size - (cloned_alternatives_array - [alt]).size
        experiment.alternatives << Abingo::Alternative.new(:content => alt, :weight => weight,
          :lookup => abingo.calculate_alternative_lookup(test_name, alt))
        cloned_alternatives_array -= [alt]
      end
      experiment.status = "Live"
      experiment.save
      experiment
    end
  end

  def end_experiment!(abingo, final_alternative)
    Abingo::Experiment.transaction do
      alternatives.each do |alternative|
        alternative.lookup = "Experiment completed.  #{alternative.id}"
        alternative.save!
      end
      update(:status => "Finished", :short_circuit => final_alternative)
    end
  end

end
