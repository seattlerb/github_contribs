require "minitest/autorun"
require "github_contribs"

class TestGithubContribs < Minitest::Test
  def test_generate
    name = "zenspider"
    last = Time.now.year

    gh = GithubContribs.new

    str = +""
    io = StringIO.new str

    gh.generate name, last, io, :testing

    assert_includes str, "<title>zenspider's contribution calendar</title>"
    assert_match(/<table class="heatmap calendar">/, str)
  end
end
