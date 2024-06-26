require 'net/http'
require 'nokogiri'
require_relative 'base'
require_relative 'semver'

module Depwatcher
  class CRAN < Base
    class Release
      attr_accessor :ref, :url

      def initialize(ref, url)
        @ref = ref
        @url = url
      end
    end

    def check(name)
      uri = URI("https://cran.r-project.org/web/packages/#{name}/index.html")
      response = Net::HTTP.get(uri)
      doc = Nokogiri::HTML(response)

      version_node = doc.xpath("//td/text()[normalize-space(.) = \"Version:\"]/following::td[1]")
      raise "Could not parse #{name} website" if version_node.empty?

      version = version_node.text.strip.gsub("-", ".")
      [Internal.new(version)]
    end

    def in(name, ref)
      semver = ref.split(".")
      major = semver[0]
      minor = semver[1]
      patch = ""
      if semver.size > 2
        patch = "#{(name == "Rserve") ? "-" : "."}#{semver[2]}"
      end
      # The method continues...
    end
  end
end