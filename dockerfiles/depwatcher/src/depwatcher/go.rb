require 'net/http'
require 'uri'
require 'json'
require_relative 'base'
require_relative 'semver'

module Depwatcher
  class Go < Base
    class Release
      attr_accessor :ref, :url, :sha256

      def initialize(ref, url, sha256)
        @ref = ref
        @url = url
        @sha256 = sha256
      end
    end

    def initialize
      @client = Net::HTTP
    end

    def check
      releases.map do |r|
        Internal.new(r.ref)
      end.sort_by { |i| Semver.new(i.ref) }
    end

    def in(ref)
      r = releases.find { |r| r.ref == ref }
      raise "Could not find data for version" unless r
      r
    end

    private

    def releases
      # Implementation for fetching releases would go here.
      # This method should return an array of Release instances.
    end
  end
end