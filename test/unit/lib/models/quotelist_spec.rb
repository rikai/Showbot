require 'rspec'

require File.join Dir.pwd, 'lib/models/quotelist.rb'

describe QuoteList do
  before(:context) do
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

  it 'matches a name' do
    expect(@quote_list.quote_for 'test').to satisfy do |value|
      @quotes['test'][:quotes].include? value
    end
  end

  it 'matches a name case insensitively' do
    expect(@quote_list.quote_for 'tesT').to satisfy do |value|
      @quotes['test'][:quotes].include? value
    end
  end

  it 'matches an alias' do
    expect(@quote_list.quote_for 'teSter').to satisfy do |value|
      @quotes['test'][:quotes].include? value
    end
  end

  it 'does not match everything' do
    expect(@quote_list.quote_for 'everything').to eq ''
  end
end
