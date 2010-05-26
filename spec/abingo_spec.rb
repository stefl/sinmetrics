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

end

describe 'Abingo Specs' do
  before :each do
    @abingo = Abingo.new
  end
    
  it "should automatically assign identity" do
    @abingo.identity.should_not be_nil
  end

  it "should parse alternatives" do
    array = %w{a b c}
    @abingo.parse_alternatives(array).should == array
    @abingo.parse_alternatives(65).size.should == 65
    @abingo.parse_alternatives(2..5).size.should == 4
    @abingo.parse_alternatives(2..5).should_not include(1)
  end
  
  it "should parse weighted alternatives" do
    hash = { 'a' => 2, 'b' => 3, 'c' => 1}
    array = %w{a a a b b c}
    @abingo.parse_alternatives(array).should == array
  end
  
  
  it "should create experiments" do
    Abingo::Experiment.count.should == 0
    Abingo::Alternative.count.should == 0
    alternatives = %w{A B}
    alternative_selected = @abingo.test("unit_test_sample_A", alternatives)
    Abingo::Experiment.count.should == 1
    Abingo::Alternative.count.should == 2
    alternatives.should include(alternative_selected)
  end
  
  it "should pick alternatives consistently" do
    alternative_picked = @abingo.test("consistency_test", 1..100)
    100.times do
      @abingo.test("consistency_test", 1..100).should == alternative_picked
    end
  end
  
  it "should have working participation" do
    new_tests = %w{participationA participationB participationC}
    new_tests.map do |test_name|
      @abingo.test(test_name, 1..5)
    end

    participating_tests = @abingo.cache.read("Abingo::participating_tests::#{@abingo.identity}") || []

    new_tests.map do |test_name|
      participating_tests.should include(test_name)
    end
  end

  it "should count participants" do
    test_name = "participants_counted_test"
    alternative = @abingo.test(test_name, %w{a b c})

    ex = Abingo::Experiment.get(test_name)
    lookup = @abingo.calculate_alternative_lookup(test_name, alternative)
    chosen_alt = Abingo::Alternative.first(:lookup => lookup)
    ex.participants.should == 1
    chosen_alt.participants.should == 1
  end

  it "should track conversions by test name" do
    test_name = "conversion_test_by_name"
    alternative = @abingo.test(test_name, %w{a b c})
    @abingo.bingo!(test_name)
    ex = Abingo::Experiment.get(test_name)
    lookup =  @abingo.calculate_alternative_lookup(test_name, alternative)
    chosen_alt = Abingo::Alternative.first(:lookup => lookup)
    ex.conversions.should == 1
    chosen_alt.conversions.should == 1

    @abingo.bingo!(test_name)

    #Should still only have one because this conversion should not be double counted.
    #We haven't specified that in the test options.
    ex = Abingo::Experiment.get(test_name)
    ex.conversions.should == 1
  end

  it "should know the best alternative" do
    test_name = "conversion_test_by_name"
    alternative = @abingo.test(test_name, {'a' => 3, 'b' => 2, 'c' => 1})
    @abingo.bingo!(test_name)
    ex = Abingo::Experiment.get(test_name)
    ex.best_alternative.content.should == alternative
  end
  
  it "should be possible to short circuit tests" do
    test_name = "short circuit test"
    alt_picked = @abingo.test(test_name, %w{A B})
    ex = Abingo::Experiment.get(test_name)
    alt_not_picked = (%w{A B} - [alt_picked]).first

    ex.end_experiment!(@abingo, alt_not_picked)

    ex.reload
    ex.status.should == "Finished"
    
    @abingo.bingo!(test_name)  #Should not be counted, test is over.
    ex.conversions.should == 0

    old_identity = @abingo.identity
    @abingo.identity = "shortCircuitTestNewIdentity"
    @abingo.test(test_name, %w{A B})
    @abingo.identity = old_identity
    ex.reload

    # Original identity counted, new identity not counted b/c test stopped
    ex.participants.should == 1
  end
end  
  