require 'json'
require 'net/http'
require 'uri'

module Depwatcher
  class Npm
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

    class External
      attr_accessor :versions

      def initialize(json)
        @versions = json['versions'].transform_values { |v| Version.new(v) }
      end
    end

    class Release
      attr_accessor :ref, :url, :sha1

      def initialize(ref, url, sha1)
        @ref = ref
        @url = url
        @sha1 = sha1
      end
    end

    def check(name)
      releases(name).map do |_, r|
        Internal.new(r.version)
      end.sort_by { |i| Semver.new(i.ref) }.last(10)
    end

    def in(name, ref)
      r = releases(name)[ref]
      Release.new(ref, r.dist.tarball, r.dist.shasum)
    end

    private

    def releases(name)
      uri = URI("https://registry.npmjs.com/#{name}/")
      response = Net::HTTP.get(uri)
      External.new(JSON.parse(response)).versions
    end
  end
end