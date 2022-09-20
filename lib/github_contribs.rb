require "pp"
require "nokogiri"
require "fileutils"
require "open-uri"
require "yaml"

class GithubContribs
  VERSION = "1.0.0"

  def oauth_token
    return @token if defined? @token

    @token = ENV["GITHUB_TOKEN"]
    @token ||= begin
                 data = YAML.load_file File.expand_path "~/.config/gh/hosts.yml"
                 data && data.dig("github.com", "oauth_token")
               end
  end

  def get name, year
    base_url = "https://github.com/#{name}?"
    path = ".#{name}.#{year}.html"

    unless File.exist? path then
      warn "#{name} #{year}" if $v

      uri = URI.parse "#{base_url}from=%4d-01-01&to=%4d-12-31" % [year, year]

      File.open path, "w" do |f|
        f.puts uri.read("authorization" => "Bearer #{oauth_token}")
      end
    end

    Nokogiri::HTML File.read path
  end

  def generate name, last, io = $stdout, testing = false
    io.puts <<~EOM
      <!DOCTYPE html>
      <html lang="en">
    EOM

    unless testing then
      FileUtils.rm_f ".#{name}.#{Time.now.year}.html" # always fetch this fresh
    end
    html = get name, Time.now.year

    io.puts html.at_css("head").to_html
    io.puts %(  <body>)
    io.puts html.css("script").to_html

    Time.now.year.downto(last).each do |year|
      graph = get(name, year)
        .at_css("div.graph-before-activity-overview")

      graph.css("div.float-right").remove # NEW!...

      graph.css("div.float-left").first   # Learn how we count...
        .content = graph.previous.previous.content.strip.gsub(/\s+/, " ")

      graph.at_css("div.js-calendar-graph")
        .remove_class("d-flex")
        .remove_class("text-center")
        .remove_class("flex-xl-items-center")

      io.puts graph.to_html
    end # years

    io.puts <<~EOM
      <div class="Popover js-hovercard-content position-absolute" style="display: none; outline: none;" tabindex="0">
        <div class="Popover-message Popover-message--bottom-left Popover-message--large Box box-shadow-large" style="width:360px;"></div>
      </div>
    EOM

    io.puts <<~EOM
        </body>
      </html>
    EOM
  end
end
