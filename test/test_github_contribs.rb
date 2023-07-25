require "minitest/autorun"
require "github_contribs"

class TestGithubContribs < Minitest::Test
  def test_oauth_token
    gh = GithubContribs.new
    assert_match(/^gho_\w{36}/, gh.oauth_token, "if this fails, they all fail")
  end

  def test_generate
    name = "zenspider"
    last = Time.now.year

    gh = GithubContribs.new

    str = ""
    io = StringIO.new str

    gh.generate name, last, io, :testing

    assert_includes str, "<title>zenspider (Ryan Davis) · GitHub</title>"
    assert_match(/div class="js-calendar-graph /, str)
  end
end
