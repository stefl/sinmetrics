#This class is outside code's main interface into the ABingo A/B testing framework.
#Unless you're fiddling with implementation details, it is the only one you need worry about.

#Usage of ABingo, including practical hints, is covered at http://www.bingocardcreator.com/abingo

begin
  require 'sinatra/base'
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
        [:identity, :backend, :enable_specification, :cache_read, :cache_write].each do |var|
          instance_variable_set("@#{var}", app.options.send("abingo_#{var}"))
        end
      else
        [:identity, :backend, :enable_specification, :cache_read, :cache_write].each do |var|
          instance_variable_set("@#{var}", app[var]) if app.has_key?(var)
        end
      end      
      @identity ||= rand(10 ** 10).to_i.to_s
      @backend ||= :data_mapper
    end

    attr_reader :app, :identity, :backend, :enable_specification, :cache_read, :cache_write

    #A simple convenience method for doing an A/B test.  Returns true or false.
    #If you pass it a block, it will bind the choice to the variable given to the block.
    def flip(test_name)
      if block_given?
        yield(test(test_name, [true, false]))
      else
        test(test_name, [true, false])
      end
    end

    #This is the meat of A/Bingo.
    #options accepts
    #  :multiple_participation (true or false)
    #  :conversion  name of conversion to listen for  (alias: conversion_name)
    def test(test_name, alternatives, options = {})
      short_circuit = cache_read("Abingo::Experiment::short_circuit(#{test_name})".gsub(" ", "_"))
      unless short_circuit.nil?
        return short_circuit  #Test has been stopped, pick canonical alternative.
      end
    
      unless Abingo::Experiment.exists?(test_name)
        conversion_name = options[:conversion] || options[:conversion_name]
        Abingo::Experiment.start_experiment!(test_name, self.parse_alternatives(alternatives), conversion_name)
      end

      choice = self.find_alternative_for_user(test_name, alternatives)
      participating_tests = cache_read("Abingo::participating_tests::#{Abingo.identity}") || []
    
      #Set this user to participate in this experiment, and increment participants count.
      if options[:multiple_participation] || !(participating_tests.include?(test_name))
        unless participating_tests.include?(test_name)
          participating_tests << test_name
          cache_write("Abingo::participating_tests::#{Abingo.identity}", participating_tests)
        end
        Abingo::Alternative.score_participation(test_name)
      end

      if block_given?
        yield(choice)
      else
        choice
      end
    end


    #Scores conversions for tests.
    #test_name_or_array supports three types of input:
    #
    #A conversion name: scores a conversion for any test the user is participating in which
    #  is listening to the specified conversion.
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
          participating_tests = Abingo.cache.read("Abingo::participating_tests::#{Abingo.identity}") || []
          participating_tests.each do |participating_test|
            self.bingo!(participating_test, options)
          end
        else #Could be a test name or conversion name.
          conversion_name = name.gsub(" ", "_")
          tests_listening_to_conversion = Abingo.cache.read("Abingo::tests_listening_to_conversion#{conversion_name}")
          if tests_listening_to_conversion
            if tests_listening_to_conversion.size > 1
              tests_listening_to_conversion.map do |individual_test|
                self.score_conversion!(individual_test.to_s)
              end
            elsif tests_listening_to_conversion.size == 1
              test_name_str = tests_listening_to_conversion.first.to_s
              self.score_conversion!(test_name_str)
            end
          else
            #No tests listening for this conversion.  Assume it is just a test name.
            test_name_str = name.to_s
            self.score_conversion!(test_name_str)
          end
        end
      end
    end

    protected

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
    def self.parse_alternatives(alternatives)
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

    def self.retrieve_alternatives(test_name, alternatives)
      cache_key = "Abingo::Experiment::#{test_name}::alternatives".gsub(" ","_")
      alternative_array = self.cache.fetch(cache_key) do
        self.parse_alternatives(alternatives)
      end
      alternative_array
    end

    def self.find_alternative_for_user(test_name, alternatives)
      alternatives_array = retrieve_alternatives(test_name, alternatives)
      alternatives_array[self.modulo_choice(test_name, alternatives_array.size)]
    end

    #Quickly determines what alternative to show a given user.  Given a test name
    #and their identity, we hash them together (which, for MD5, provably introduces
    #enough entropy that we don't care) otherwise
    def self.modulo_choice(test_name, choices_count)
      Digest::MD5.hexdigest(Abingo.salt.to_s + test_name + self.identity.to_s).to_i(16) % choices_count
    end

    def self.score_conversion!(test_name)
      test_name.gsub!(" ", "_")
      participating_tests = Abingo.cache.read("Abingo::participating_tests::#{Abingo.identity}") || []
      if options[:assume_participation] || participating_tests.include?(test_name)
        cache_key = "Abingo::conversions(#{Abingo.identity},#{test_name}"
        if options[:multiple_conversions] || !Abingo.cache.read(cache_key)
          Abingo::Alternative.score_conversion(test_name)
          if Abingo.cache.exist?(cache_key)
            Abingo.cache.increment(cache_key)
          else
            Abingo.cache.write(cache_key, 1)
          end
        end
      end
    end
  end
  
  module AbingoHelper
    def abingo
      env['abingo.helper'] ||= AbingoObject.new(self)
    end
    
    alias ab abingo
  end
  
  class AbingoSettings
    def initialize app, &blk
      @app = app
      instance_eval &blk
    end
    %w[identity backend enable_specification cache_read cache_write].each do |param|
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
