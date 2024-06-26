require 'net/http'
require 'nokogiri'
require 'uri'

uri = URI("https://www.ruby-lang.org/en/downloads/")
response = Net::HTTP.get(uri)
doc = Nokogiri::HTML(response)
lis = doc.xpath("//li/a[starts-with(text(),'Ruby ')]")
raise "Could not parse ruby website" unless lis.is_a?(Nokogiri::XML::NodeSet)

lis = lis.map do |a|
  parent = a.parent
  [a.text.gsub(/^Ruby /, ""), a['href'], parent.is_a?(Nokogiri::XML::Node) ? parent.text : ""]
end

lis = lis.map do |version, url, text|
  m = /sha256: ([0-9a-f]+)/.match(text)
  [version, url, m[1]] if m
end.compact!

puts lis