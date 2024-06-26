require 'net/http'
require 'nokogiri'
require 'json'
require 'digest'

module Depwatcher
  class R < Base
    Release = Struct.new(:ref, :url, :sha256)

    def check
      uri = URI('https://svn.r-project.org/R/tags/')
      response = Net::HTTP.get(uri)
      doc = Nokogiri::HTML(response)
      lis = doc.xpath("//li/a")

      raise "Could not parse R SVN website" if lis.empty?

      lis.map do |a|
        href = a['href'].to_s
        m = href.match(/^R\-([\d\-]+)\//)
        version = m[1].gsub("-", ".") if m
        Internal.new(version) if version
      end.compact.sort_by { |i| Semver.new(i.ref) }.last(10)
    end

    def in(ref)
      major = ref.split(".")[0]
      url = "https://cran.r-project.org/src/base/R-#{major}/R-#{ref}.tar.gz"
      sha256 = get_sha256(url)
      Release.new(ref, url, sha256)
    end

    private

    def get_sha256(url)
      uri = URI(url)
      response = Net::HTTP.get(uri)
      Digest::SHA256.hexdigest(response)
    end
  end
end