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
  
  it "should create experiments" do
    Abingo::Experiment.count.should == 0
    Abingo::Alternative.count.should == 0
    alternatives = %w{A B}
    alternative_selected = @abingo.test("unit_test_sample_A", alternatives)
    Abingo::Experiment.count.should == 1
    Abingo::Alternative.count.should == 2
    alternatives.should include(alternative_selected)
  end
  
  it "should be able to call exists" do
    @abingo.test("exist words right", %w{does does_not})
    Abingo::Experiment.exists?(@abingo, "exist words right").should be_true
    Abingo::Experiment.exists?(@abingo, "other words right").should_not be_true
  end
  
=begin
  test "alternatives picked consistently" do
    alternative_picked = Abingo.test("consistency_test", 1..100)
    100.times do
      assert_equal alternative_picked, Abingo.test("consistency_test", 1..100)
    end
  end

  test "participation works" do
    new_tests = %w{participationA participationB participationC}
    new_tests.map do |test_name|
      Abingo.test(test_name, 1..5)
    end

    participating_tests = Abingo.cache.read("Abingo::participating_tests::#{Abingo.identity}") || []

    new_tests.map do |test_name|
      assert participating_tests.include? test_name
    end
  end

  test "participants counted" do
    test_name = "participants_counted_test"
    alternative = Abingo.test(test_name, %w{a b c})

    ex = Abingo::Experiment.find_by_test_name(test_name)
    lookup = Abingo::Alternative.calculate_lookup(test_name, alternative)
    chosen_alt = Abingo::Alternative.find_by_lookup(lookup)
    assert_equal 1, ex.participants
    assert_equal 1, chosen_alt.participants
  end

  test "conversion tracking by test name" do
    test_name = "conversion_test_by_name"
    alternative = Abingo.test(test_name, %w{a b c})
    Abingo.bingo!(test_name)
    ex = Abingo::Experiment.find_by_test_name(test_name)
    lookup = Abingo::Alternative.calculate_lookup(test_name, alternative)
    chosen_alt = Abingo::Alternative.find_by_lookup(lookup)
    assert_equal 1, ex.conversions
    assert_equal 1, chosen_alt.conversions
    Abingo.bingo!(test_name)

    #Should still only have one because this conversion should not be double counted.
    #We haven't specified that in the test options.
    assert_equal 1, Abingo::Experiment.find_by_test_name(test_name).conversions
  end

  test "conversion tracking by conversion name" do
    conversion_name = "purchase"
    tests = %w{conversionTrackingByConversionNameA conversionTrackingByConversionNameB conversionTrackingByConversionNameC}
    tests.map do |test_name|
      Abingo.test(test_name, %w{A B}, :conversion => conversion_name)
    end

    Abingo.bingo!(conversion_name)
    tests.map do |test_name|
      assert_equal 1, Abingo::Experiment.find_by_test_name(test_name).conversions
    end
  end

  test "short circuiting works" do
    conversion_name = "purchase"
    test_name = "short circuit test"
    alt_picked = Abingo.test(test_name, %w{A B}, :conversion => conversion_name)
    ex = Abingo::Experiment.find_by_test_name(test_name)
    alt_not_picked = (%w{A B} - [alt_picked]).first

    ex.end_experiment!(alt_not_picked, conversion_name)

    ex.reload
    assert_equal "Finished", ex.status
    
    Abingo.bingo!(test_name)  #Should not be counted, test is over.
    assert_equal 0, ex.conversions

    old_identity = Abingo.identity
    Abingo.identity = "shortCircuitTestNewIdentity"
    Abingo.test(test_name, %w{A B}, :conversion => conversion_name)
    Abingo.identity = old_identity
    ex.reload
    assert_equal 1, ex.participants  #Original identity counted, new identity not counted b/c test stopped
  end
=end
end  
  