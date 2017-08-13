require 'rspec'

require File.join Dir.pwd, 'lib/models/show.rb'

describe Show do
  before(:context) do
    @show = Show.new({
      'title' => 'Title',
      'url' => 'slug',
      'rss' => 'http://example.com/rss',
      'aliases' => ['tt', 'TL']
    })
  end

  it 'initializes properly without aliases' do
    show = Show.new({
      'title' => 'Title',
      'url' => 'slug',
      'rss' => 'http://example.com/rss'
    })

    expect(show.title).to eq 'Title'
    expect(show.url).to eq 'slug'
    expect(show.rss).to eq 'http://example.com/rss'
    expect(show.aliases.size).to eq 0
  end

  it 'initializes properly' do
    show = @show

    expect(show.title).to eq 'Title'
    expect(show.url).to eq 'slug'
    expect(show.rss).to eq 'http://example.com/rss'
    expect(show.aliases.size).to eq 2
    expect(show.aliases[0]).to eq 'tt'
    expect(show.aliases[1]).to eq 'tl'
  end

  it 'matches a title' do
    expect(@show.matches? 'Title').to be true
  end

  it 'matches a title case insensitively' do
    expect(@show.matches? 'title').to be true
  end

  it 'matches a slug' do
    expect(@show.matches? 'Slug').to be true
  end

  it 'matches an alias' do
    expect(@show.matches? 'Tl').to be true
  end

  it 'does not match everything' do
    expect(@show.matches? 'everything').to be false
  end
end
