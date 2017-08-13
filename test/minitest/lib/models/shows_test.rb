require 'minitest/autorun'

require File.join Dir.pwd, 'lib/models/shows.rb'

class ShowsTest < Minitest::Test
    def setup
        show_hashes = JSON.parse(File.open("test/data/shows.json").read)["shows"]
        @shows = Shows.new(show_hashes)
        @returned_show = Show.new({
            "rss" => "http://feeds.feedburner.com/linuxunvid",
	        "url" => "lu",
        	"title" => "Linux Unplugged",
        	"aliases" => [
            	"lup"
        	]
        })
    end
    
    #def test_load?
    #    shows = Shows.new([])
        
    #    test_hash = [{
    #        "rss" => "http://feeds.feedburner.com/linuxunvid",
	#        "url" => "lu",
    #    	"title" => "Linux Unplugged",
    #    	"aliases" => ["lup"]
    #    }]
    #    
    #    shows.load(test_hash)
    #    
    #    shows_array = shows.get_shows
    #    show = shows_array[0]
    #    puts show.inspect
    #    
    #    assert_equal(shows_array.length, 1)
    #    assert_equal(show.(@rss), test_hash.rss)
    #    assert_equal(show.send(@url), test_hash.url)
    #    assert_equal(show.send(@title), test_hash.title)
    #    assert_equal(show.send(@aliases), test_hash.aliases)
    #end
    
    def test_find_show?
        assert @returned_show.rss == @shows.find_show("lu").rss
        assert @returned_show.url == @shows.find_show("lu").url
        assert @returned_show.title == @shows.find_show("lu").title
        assert @returned_show.aliases == @shows.find_show("lu").aliases
    end
    
    def test_find_show_title?
        assert_equal("Linux Unplugged", @shows.find_show_title("lu"))
        assert_equal("Action Show", @shows.find_show_title("Action Show"))
    end
    
end