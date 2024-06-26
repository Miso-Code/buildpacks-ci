require 'nokogiri'
require 'net/http'
require 'uri'

module Depwatcher
  class Miniconda
    class Release
      attr_accessor :ref, :url, :sha256

      def initialize(ref, url, sha256)
        @ref = ref
        @url = url
        @sha256 = sha256
      end
    end

    def check(python_version)
      generation = python_version.split(".")[0]
      releases(generation, python_version).map do |m|
        Internal.new(m[1])
      end.sort_by { |i| Semver.new(i.ref) }
    end

    def in(python_version, ref)
      generation = python_version.split(".")[0]
      releases(generation, python_version).find do |m|
        m[1] == ref
      end
    end

    private

    def releases(generation, python_version)
      response = Net::HTTP.get(URI("https://repo.anaconda.com/miniconda/"))
      doc = Nokogiri::HTML(response)
      elements = doc.xpath("//tr[td[a[starts-with(@href,'Miniconda#{generation}-py#{python_version.delete(".")}')]]]")
      elements.map do |e|
        m = /Miniconda#{generation}-py#{python_version.delete(".")}_([\d\.]+)-([\d]+)-Linux-x86_64.sh/.match(e.text)
        if m
          build_num = m[2]
          url = "https://repo.anaconda.com/miniconda/Miniconda#{generation}-py#{python_version.delete(".")}_#{m[1]}-#{build_num}-Linux-x86_64.sh"
          shasum = e.xpath("td")[3].text.strip # Assuming SHA256 is in the fourth column
          Release.new(m[1], url, shasum)
        end
      end.compact
    end
  end
end