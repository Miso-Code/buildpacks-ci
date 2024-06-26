require "nokogiri"
require "open-uri"

module Depwatcher
  class RubygemsCli < Base
    class Release
      attr_reader :ref, :url

      def initialize(ref, url)
        @ref = ref
        @url = url
      end
    end

    def check
      response = open("https://rubygems.org/pages/download").read
      doc = Nokogiri::HTML(response)
      links = doc.xpath("//a[contains(@class,'download__format')][text()='tgz']")
      raise "Could not parse rubygems download website" unless links.is_a?(Nokogiri::XML::NodeSet)
      links.map do |a|
        v = a["href"].gsub(/.*\/rubygems\-(.*)\.tgz$/, "\\1")
        Internal.new(v)
      end
    end

    def in(ref)
      Release.new(ref, "https://rubygems.org/rubygems/rubygems-#{ref}.tgz")
    end
  end
end
