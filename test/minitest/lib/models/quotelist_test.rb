require 'minitest/autorun'

require File.join Dir.pwd, 'lib/models/quotelist.rb'


class TestQuotelist < Minitest::Test
  def setup
    @quotes = {
      'test' => {
        :aliases => ['tester', 'testivus'],
        :quotes => [
          'A test tests a test of tests.',
          'Testing tests tests nothing but testing.'
        ]
      }
    }
    @quote_list = QuoteList.new(@quotes)
  end
  
  def test_initialization?
    quote_list = QuoteList.new(nil)
    assert_equal Hash.new, quote_list.quotes
    
    quote_list = QuoteList.new(nil)
    assert_equal Hash.new, quote_list.quotes
    
    quote_list = QuoteList.new(@quotes)
    assert_equal ["test"], quote_list.quotes.keys
    assert_equal [:aliases, :quotes], quote_list.quotes["test"].keys
    assert_equal ['A test tests a test of tests.', 'Testing tests tests nothing but testing.'], 
                 quote_list.quotes["test"][:quotes]
    assert_equal ['tester', 'testivus'], quote_list.quotes["test"][:aliases]
  end
  
  def test_quote_for?
    quote = @quote_list.quote_for("Test") 
    assert quote == "A test tests a test of tests." || 
           quote == "Testing tests tests nothing but testing."
    quote = @quote_list.quote_for("testivus")
    assert quote == "A test tests a test of tests." || 
           quote == "Testing tests tests nothing but testing."
    quote = @quote_list.quote_for("failure")
    assert quote == ''
  end
  
  def test_add?
    @quote_list.add("Test", "Tested tests can be testy.")
    @quote_list.add("Mr. Testy", "Testing tests tests my patience.")
    assert_equal(["test", "mr. testy"], @quote_list.quotes.keys)
    assert_equal(["Testing tests tests my patience."], @quote_list.quotes["mr. testy"][:quotes])
    assert_equal(["A test tests a test of tests.", "Testing tests tests nothing but testing.", "Tested tests can be testy.", ], @quote_list.quotes["test"][:quotes])
  end
  
  def test_del?
    @quote_list.del("Test", "A test tests a test of tests.")
    assert_equal(["Testing tests tests nothing but testing."], @quote_list.quotes["test"][:quotes])
    @quote_list.del("Test", "Testing tests tests nothing but testing.")
    assert_equal(Hash.new, @quote_list.quotes)
  end
  
  def test_add_alias?
    @quote_list.add_alias("Test", "McTest")
    assert_equal(["tester", "testivus", "McTest"], @quote_list.quotes["test"][:aliases])
  end
  
  def test_del_alias?
    @quote_list.del_alias("test", "testivus")
    assert_equal(["tester"], @quote_list.quotes["test"][:aliases])
  end
  
  def test_canonicalize?
    assert_equal("test", @quote_list.send(:canonicalize, "Test"))
    assert_equal("test", @quote_list.send(:canonicalize, "testivus"))
  end
  
  def test_match_canonical?
    assert @quote_list.send(:match_canonical?, "Test", "Test")
    refute @quote_list.send(:match_canonical?, "test", "testy")
  end
  
  def test_match_aliases?
    assert @quote_list.send(:in_aliases?, @quote_list.quotes["test"][:aliases], "tester")
    assert @quote_list.send(:in_aliases?, @quote_list.quotes["test"][:aliases], "tester")
    refute @quote_list.send(:in_aliases?, @quote_list.quotes["test"][:aliases], "hello")
  end
end