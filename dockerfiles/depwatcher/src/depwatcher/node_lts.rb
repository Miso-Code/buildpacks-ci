require 'json'
require 'net/http'
require 'uri'
require 'openssl'

module Depwatcher
  class NodeLTS
    class Dist
      attr_accessor :shasum, :tarball

      def initialize(json)
        @shasum = json['shasum']
        @tarball = json['tarball']
      end
    end

    class Version
      attr_accessor :name, :version, :dist

      def initialize(json)
        @name = json['name']
        @version = json['version']
        @dist = Dist.new(json['dist'])
      end
    end

    class NodeVersionInfo
      attr_accessor :start, :lts, :maintenance, :end, :codename

      def initialize(json)
        @start = json['start']
        @lts = json['lts']
        @maintenance = json['maintenance']
        @end = json['end']
        @codename = json['codename']
      end
    end

    class External
      attr_accessor :versions

      def initialize(json)
        @versions = json['versions'].transform_values { |v| Version.new(v) }
      end
    end

    class Release
      attr_accessor :ref, :url, :sha256

      def initialize(ref, url, sha256)
        @ref = ref
        @url = url
        @sha256 = sha256
      end
    end

    def check
      version_numbers.map do |v|
        Internal.new(v)
      end.sort_by { |i| Semver.new(i.ref) }
    end

    def in(ref)
      Release.new(ref, url(ref), shasum256(ref))
    end

    private

    def getLTSLine
      uri = URI("https://raw.githubusercontent.com/nodejs/Release/main/schedule.json")
      response = Net::HTTP.get(uri)
      raise "Failed to get nodejs LTS schedule" unless response

      latest_lts = ""
      actual_date = Time.now
      actual_year = actual_date.year
      actual_month = actual_date.month
      actual_day = actual_date.day
      JSON.parse(response).each do |version, info|
        if info['lts'] && !info['lts'].empty?
          lts_date = info['lts']
          lts_year, lts_month, lts_day = lts_date.split("-").map(&:to_i)
          if lts_year < actual_year || (lts_year == actual_year && lts_month < actual_month) || (lts_year == actual_year && lts_month == actual_month && lts_day <= actual_day)
            latest_lts = version.sub("v","")
          end
        end
      end
      latest_lts
    end

    def url(version)
      "https://nodejs.org/dist/v#{version}/node-v#{version}.tar.gz"
    end

    def shasum256(version)
      uri = URI("https://nodejs.org/dist/v#{version}/SHASUMS256.txt")
      response = Net::HTTP.get(uri)
      response.lines.find { |line| line.include?("node-v#{version}.tar.gz") }.split.first
    end

    def version_numbers
      latest_lts = getLTSLine
      uri = URI("https://nodejs.org/dist/")
      response = Net::HTTP.get(uri)
      doc = Nokogiri::HTML(response)
      links = doc.css('a').map { |link| link['href'] }.select { |href| href.start_with?("v") && href.end_with?("/") }
      links.map { |link| link[1...-1] }.select do |version|
        Semver.new(version).major == latest_lts.to_i
      end
    end
  end
end