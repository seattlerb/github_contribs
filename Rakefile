# -*- ruby -*-

require "rubygems"
require "hoe"

Hoe.plugin :isolate
Hoe.plugin :seattlerb
Hoe.plugin :rdoc

Hoe.spec "github_contribs" do
  developer "Ryan Davis", "ryand-ruby@zenspider.com"

  self.isolate_multiruby = true # for nokogiri

  license "MIT"
end

task :run => :isolate do
  WHO = ENV["U"] || "zenspider"
  ruby "-Ilib bin/github_contribs -v #{WHO}"
end

# vim: syntax=ruby
