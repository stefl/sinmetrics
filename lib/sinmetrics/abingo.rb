#This class is outside code's main interface into the ABingo A/B testing framework.
#Unless you're fiddling with implementation details, it is the only one you need worry about.

#Usage of ABingo, including practical hints, is covered at http://www.bingocardcreator.com/abingo

begin
  require 'sinatra/base'
  require 'active_support'
rescue LoadError
  retry if require 'rubygems'
  raise
end


module Sinatra  
  class AbingoObject
    
    #Defined options:
    #  :enable_specification => if true, allow params[test_name] to override the calculated value for a test.
    def initialize app={}
      if app.respond_to?(:options)
        @app = app
        [:identity, :enable_specification, :cache, :salt].each do |var|
          begin
            instance_variable_set("@#{var}", app.options.send("abingo_#{var}"))
          rescue NoMethodError
          end
        end
      else
        [:identity, :enable_specification, :cache, :salt].each do |var|
          instance_variable_set("@#{var}", app[var]) if app.has_key?(var)
        end
      end      
      @identity ||= rand(10 ** 10).to_i.to_s
      @cache ||= ActiveSupport::Cache::MemoryStore.new
      @salt ||= ''
    end

    attr_reader :app, :enable_specification, :cache, :salt
    attr_accessor :identity

    #A simple convenience method for doing an A/B test.  Returns true or false.
    #If you pass it a block, it will bind the choice to the variable given to the block.
    def flip(test_name)
      choice = test(test_name, [true, false])
      if block_given?
        yield choice
      else
        choice
      end
    end

    #This is the meat of A/Bingo.
    #options accepts
    #  :multiple_participation (true or false)
    #  :no_particiation (true or false)
    def test(test_name, alternatives, options = {})
      experiment = Experiment.get(test_name)
      experiment ||= Experiment.start_experiment!(self, test_name, parse_alternatives(alternatives))

      # Test has been stopped, pick canonical alternative.
      unless experiment.short_circuit.nil?
        return experiment.short_circuit
      end
    
      choice = find_alternative_for_user(test_name, alternatives)
      score_participation!(test_name, options) unless options[:no_participation]

      if block_given?
        yield(choice)
      else
        choice
      end
    end

    #Scores conversions for tests.
    #test_name_or_array supports three types of input:
    #
    #A test name: scores a conversion for the named test if the user is participating in it.
    #
    #An array of either of the above: for each element of the array, process as above.
    #
    #nil: score a conversion for every test the u
    def bingo!(name = nil, options = {})
      if name.kind_of? Array
        name.map do |single_test|
          self.bingo!(single_test, options)
        end
      else
        if name.nil?
          #Score all participating tests
          participating_tests = cache.read("Abingo::participating_tests::#{identity}") || []
          participating_tests.each do |participating_test|
            self.bingo!(participating_test, options)
          end
        else
          self.score_conversion!(name.to_s, options)
        end
      end
    end

    #protected

    #For programmer convenience, we allow you to specify what the alternatives for
    #an experiment are in a few ways.  Thus, we need to actually be able to handle
    #all of them.  We fire this parser very infrequently (once per test, typically)
    #so it can be as complicated as we want.
    #   Integer => a number 1 through N
    #   Range   => a number within the range
    #   Array   => an element of the array.
    #   Hash    => assumes a hash of something to int.  We pick one of the 
    #              somethings, weighted accorded to the ints provided.  e.g.
    #              {:a => 2, :b => 3} produces :a 40% of the time, :b 60%.
    #
    #Alternatives are always represented internally as an array.
    def parse_alternatives(alternatives)
      if alternatives.kind_of? Array
        return alternatives
      elsif alternatives.kind_of? Integer
        return (1..alternatives).to_a
      elsif alternatives.kind_of? Range
        return alternatives.to_a
      elsif alternatives.kind_of? Hash
        alternatives_array = []
        alternatives.each do |key, value|
          if value.kind_of? Integer
            alternatives_array += [key] * value
          else
            raise "You gave a hash with #{key} => #{value} as an element.  The value must be an integral weight."
          end
        end
        return alternatives_array
      else
        raise "I don't know how to turn [#{alternatives}] into an array of alternatives."
      end
    end

    def find_alternative_for_user(test_name, alternatives)
      cache_key = "Abingo::Experiment::#{test_name}::alternatives".gsub(" ","_")
      alternative_array = self.cache.fetch(cache_key) do
        self.parse_alternatives(alternatives)
      end

      #Quickly determines what alternative to show a given user.  Given a test name
      #and their identity, we hash them together (which, for MD5, provably introduces
      #enough entropy that we don't care) otherwise
      choice = Digest::MD5.hexdigest(salt.to_s + test_name + self.identity.to_s).to_i(16) % alternative_array.size
      alternative_array[choice]
    end
    
    def alternatives_for_test(test_name)
      cache_key = "Abingo::Experiment::#{test_name}::alternatives".gsub(" ","_")    
      self.cache.fetch(cache_key) do
        Experiment.get(test_name).alternatives.map do |alt| 
          if alt.weight > 1 
            [alt.content] * alt.weight
          else
            alt.content
          end
        end.flatten
      end
    end

    def score_conversion!(test_name, options = {})
      participating_tests = cache.read("Abingo::participating_tests::#{identity}") || []
      if options[:assume_participation] || participating_tests.include?(test_name)
        cache_key = "Abingo::conversions(#{identity},#{test_name}"
        if options[:multiple_conversions] || !cache.read(cache_key)
          viewed_alternative = find_alternative_for_user(test_name, alternatives_for_test(test_name))
          lookup = calculate_alternative_lookup(test_name, viewed_alternative)
          Alternative.all(:lookup => lookup).adjust!(:conversions => 1)
          if cache.exist?(cache_key)
            cache.increment(cache_key)
          else
            cache.write(cache_key, 1)
          end
        end
      end
    end
    
    def score_participation!(test_name, options = {})
      participating_tests = cache.read("Abingo::participating_tests::#{identity}") || []
    
      #Set this user to participate in this experiment, and increment participants count.
      if options[:multiple_participation] || !(participating_tests.include?(test_name))
        participating_tests = participating_tests.dup if participating_tests.frozen?
        unless participating_tests.include?(test_name)
          participating_tests << test_name
          cache.write("Abingo::participating_tests::#{identity}", participating_tests)
        end
        
        choice = find_alternative_for_user(test_name, alternatives_for_test(test_name))
        lookup = calculate_alternative_lookup(test_name, choice)
        Alternative.all(:lookup => lookup).adjust!(:participants => 1)
      end
    end
    
    def end_experiment(alternative_id)
      alternative = Alternative.get(alternative_id)
      experiment = alternative.experiment
      if (experiment.status != "Completed")
        experiment.end_experiment!(self, alternative.content)
      end
    end
    
    def calculate_alternative_lookup(test_name, alternative_name)
      Digest::MD5.hexdigest(self.salt + test_name + alternative_name.to_s)
    end
  end
  
  module AbingoObject::ConversionRate
    def conversion_rate
      return 0 if participants == 0
      1.0 * conversions / participants
    end

    def pretty_conversion_rate
      sprintf("%4.2f%%", conversion_rate * 100)
    end
  end
  
  module AbingoHelper
    def abingo
      env['abingo.helper'] ||= AbingoObject.new(self)
    end
    
    def ab_test(test_name, alternatives = nil, options = {})
      if (abingo.enable_specification && !params[test_name].blank?)
        choice = params[test_name]
      elsif (alternatives.nil?)
        choice = abingo.flip(test_name)
      else
        choice = abingo.test(test_name, alternatives, options)
      end

      if block_given?
        yield(choice)
      else
        choice
      end
    end
    
    alias ab abingo
  end
  
  class AbingoSettings
    def initialize app, &blk
      @app = app
      instance_eval &blk
    end
    %w[identity backend enable_specification cache salt].each do |param|
      class_eval %[
        def #{param} val, &blk
          @app.set :abingo_#{param}, val
        end
      ]
    end
  end

  module Abingo
    def abingo &blk
      AbingoSettings.new(self, &blk)
    end
    
    def self.registered app
      app.helpers AbingoHelper
    end
  end
  
  Application.register Abingo
end

Abingo = Sinatra::AbingoObject

require 'dm-core'
require 'dm-transactions'
require 'dm-aggregates'
require 'dm-validations'
require 'dm-adjust'
require 'abingo/statistics'
require 'abingo/alternative'
require 'abingo/experiment'
