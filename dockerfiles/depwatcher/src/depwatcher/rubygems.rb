require 'json'
require 'open-uri'

module Depwatcher
  class Rubygems < Base
    class MultiExternal
      attr_accessor :number, :prerelease

      def initialize(number:, prerelease:)
        @number = number
        @prerelease = prerelease
      end

      def self.from_json(json_string)
        data = JSON.parse(json_string)
        new(number: data['number'], prerelease: data['prerelease'])
      end
    end

    class External
      attr_accessor :number, :sha, :prerelease, :source_code_uri

      def initialize(number:, sha:, prerelease:, source_code_uri:)
        @number = number
        @sha = sha
        @prerelease = prerelease
        @source_code_uri = source_code_uri
      end

      def self.from_json(json_string)
        data = JSON.parse(json_string)
        new(number: data['number'], sha: data['sha'], prerelease: data['prerelease'], source_code_uri: data['source_code_uri'])
      end
    end

    class Release
      attr_accessor :ref, :sha256, :url

      def initialize(external)
        @ref = external.number
        @sha256 = external.sha
        @url = external.source_code_uri + "tree/v#{external.number}"
      end
    end

    def check(name)
      releases(name).reject(&:prerelease).map { |r| Internal.new(r.number) }.first(10).reverse
    end

    def in(name, ref)
      Release.new(release(name, ref))
    end

    private

    def releases(name)
      response = open("https://rubygems.org/api/v1/versions/#{name}.json").read
      JSON.parse(response).map { |data| MultiExternal.new(number: data['number'], prerelease: data['prerelease']) }
    end

    def release(name, version)
      response = open("https://rubygems.org/api/v2/rubygems/#{name}/versions/#{version}.json").read
      External.from_json(response)
    end
  end
end
