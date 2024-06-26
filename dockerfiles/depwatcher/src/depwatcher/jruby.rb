require 'nokogiri'
require 'net/http'
require 'uri'
require_relative 'base'
require_relative 'semver'

module Depwatcher
  class JRuby < Base
    class Release
      attr_accessor :ref, :url, :sha256

      def initialize(ref, url, sha256)
        @ref = ref
        @url = url
        @sha256 = sha256
      end
    end

    private def get_versions
      uri = URI("https://www.jruby.org/download")
      response = Net::HTTP.get(uri)
      doc = Nokogiri::HTML(response)
      elements = doc.xpath("//a[starts-with(@href,'https://repo1.maven.org/maven2/org/jruby/jruby-dist/')]")
      elements.map do |e|
        m = /https:\/\/repo1.maven.org\/maven2\/org\/jruby\/jruby-dist\/([\d.]+)\/jruby-dist-([\d.]+)-src.zip/.match(e['href'])
        m[1] unless m.nil?
      end.compact.uniq
    end

    def check
      get_versions.map do |v|
        Internal.new(v)
      end.sort_by { |i| Semver.new(i.ref) }
    end
  end
end