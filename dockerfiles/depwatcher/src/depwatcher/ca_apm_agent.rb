require 'net/http'
require 'nokogiri'
require_relative 'base'
require_relative 'semver'

module Depwatcher
  class CaApmAgent < Base
    class Release
      attr_accessor :ref, :url, :sha256

      def initialize(ref, url, sha256)
        @ref = ref
        @url = url
        @sha256 = sha256
      end
    end

    def check
      uri = URI("https://packages.broadcom.com/artifactory/apm-agents/")
      response = Net::HTTP.get(uri)
      doc = Nokogiri::HTML(response)
      links = doc.xpath("//a[@href]")
      raise "Could not parse apache httpd website" unless links.is_a?(Nokogiri::XML::NodeSet)

      links.map do |link|
        href = link['href'].to_s
        m = href.match(/^CA-APM-PHPAgent-([\d\.]+)_linux.tar.gz/)
        version = m[1] if m
        Internal.new(version) if version
      end.compact.sort_by { |i| Semver.new(i.ref) }.last(10)
    end
  end
end