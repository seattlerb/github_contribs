# -*- ruby -*-

require "rubygems"
require "hoe"

Hoe.plugin :isolate
Hoe.plugin :seattlerb
Hoe.plugin :rdoc

Hoe.spec "github_contribs" do
  developer "Ryan Davis", "ryand-ruby@zenspider.com"

  dependency "nokogiri", "~> 1.13"

  license "MIT"
end

task :run => :isolate do
  ruby "-Ilib bin/github_contribs zenspider 1998"
end

# vim: syntax=ruby
