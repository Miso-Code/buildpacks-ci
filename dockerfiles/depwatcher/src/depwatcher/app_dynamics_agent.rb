require 'json'
require 'net/http'
require_relative 'base'
require_relative 'semver'

module Depwatcher
  class AppDynamicsAgent < Base
    class Release
      attr_accessor :ref, :url, :sha256

      def initialize(ref, url, sha256)
        @ref = ref
        @url = url
        @sha256 = sha256
      end
    end

    def check
      releases.map do |r|
        Internal.new(r.ref)
      end
    end

    def in(ref)
      r = releases.find { |release| release.ref == ref }
      raise "Could not find data for version" unless r
      r
    end

    private

    def releases
      all_releases = []
      uri = URI("https://download.run.pivotal.io/appdynamics-php/index.yml")
      response = Net::HTTP.get(uri)

      response.each_line do |appd_version|
        split_array = appd_version.split(": ")
        version = split_array[0].gsub("_", "-")
        url = split_array[1].strip
        temp_file = "#{version}"

        File.write(temp_file, Net::HTTP.get(URI(url)))
        sha256 = Digest::SHA256.file(temp_file).hexdigest
        File.delete(temp_file)

        all_releases.push(Release.new(version, url, sha256))
      end

      all_releases.sort_by { |r| Version.new(r.ref) }.last(10)
    end
  end
end