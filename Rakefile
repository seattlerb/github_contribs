# -*- ruby -*-

require "rubygems"
require "hoe"

Hoe.plugin :isolate
Hoe.plugin :seattlerb
Hoe.plugin :rdoc

Hoe.spec "github_contribs" do
  developer "Ryan Davis", "ryand-ruby@zenspider.com"

  dependency "nokogiri", "~> 1.12"

  self.isolate_multiruby = true # for nokogiri

  license "MIT"
end

task :run => :isolate do
  WHO = ENV["U"] || "zenspider 1998"
  ruby "-Ilib bin/github_contribs #{WHO}"
end

# vim: syntax=ruby
