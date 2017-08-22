require 'minitest/autorun'

require File.join Dir.pwd, 'lib/models/show.rb'

class TestShow < MiniTest::Test
    def setup
        @show = Show.new({
            "title" => "Linux Action Show",
            "url" => "las",
            "rss" => "las.com/rss",
            "aliases" => ["las", "linas"]
        })
    end
    
    def test_matches?
        assert @show.matches?("las")
        refute @show.matches?("lup")
    end
    
    def test_matches_url?
        assert @show.send(:matches_url?, "las")
        refute @show.send(:matches_url?, "lup")
    end
    
    def test_matches_title?
        assert @show.send(:matches_title?, "action sh")
        refute @show.send(:matches_title?, "unpl")
    end
    
    def test_matches_alias?
        assert @show.send(:matches_alias?, "linas")
        refute @show.send(:matches_alias?, "lup")
    end
end
        