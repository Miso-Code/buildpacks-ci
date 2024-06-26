require 'json'
require 'net/http'
require 'uri'

module Depwatcher
  class Node
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
      attr_accessor :ref, :url, :sha256

      def initialize(ref, url, sha256)
        @ref = ref
        @url = url
        @sha256 = sha256
      end
    end
  end
end