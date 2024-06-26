require 'nokogiri'
require 'net/http'
require 'uri'

module Depwatcher
  class Php
    class Release
      attr_accessor :ref, :url, :sha256

      def initialize(ref, url, sha256)
        @ref = ref
        @url = url
        @sha256 = sha256
      end
    end

    def check
      uri = URI('https://www.php.net/downloads.php')
      response = Net::HTTP.get(uri)
      doc = Nokogiri::HTML(response)
      links = doc.xpath("//h3[starts-with(@id,'v')]/@id")
      versions = links.map { |e| e.content[1..-1] }.map { |v| Internal.new(v) }
      versions += old_versions
      versions.sort_by { |i| Semver.new(i.ref) }
    end

    def in(ref)
      url = "https://www.php.net/distributions/php-#{ref}.tar.gz"
      uri = URI('https://www.php.net/downloads.php')
      response = Net::HTTP.get(uri)
      doc = Nokogiri::HTML(response)
      links = doc.xpath("//h3[@id=\"v#{ref}\"]/following-sibling::div/ul/li[a[contains(@href,'.tar.gz')]]/span[@class='sha256']")
      links = links_for_old_versions(ref) if links.empty?
      sha256 = links.first.text.strip.sub(/^sha256: /, '')
      Release.new(ref, url, sha256)
    end

    def links_for_old_versions(ref)
      uri = URI('https://www.php.net/releases/')
      response = Net::HTTP.get(uri)
      doc = Nokogiri::HTML(response)
      doc.xpath("//a[text()='PHP #{ref} (tar.gz)']/following-sibling::span[@class='sha256sum']")
    end

    def old_versions
      uri = URI('https://www.php.net/releases/')
      response = Net::HTTP.get(uri)
      doc = Nokogiri::HTML(response)
      php7_versions = doc.xpath("//h2[starts-with(text(),'7.')]").map { |e| Internal.new(e.content) }
      php8_versions = doc.xpath("//h2[starts-with(text(),'8.')]").map { |e| Internal.new(e.content) }
      php7_versions + php8_versions
    end
  end
end