require 'json'
require 'net/http'
require 'uri'

module Depwatcher
  class Pypi
    class External
      attr_accessor :releases

      def initialize(json)
        @releases = json['releases']
      end
    end

    class ExternalRelease
      attr_accessor :ref, :url, :digests, :md5_digest, :packagetype, :size

      def initialize(json)
        @ref = json['ref']
        @url = json['url']
        @digests = json['digests']
        @md5_digest = json['md5_digest']
        @packagetype = json['packagetype']
        @size = json['size']
      end
    end

    class Release
      attr_accessor :ref, :url, :md5_digest, :sha256

      def initialize(ref, url, md5_digest, sha256)
        @ref = ref
        @url = url
        @md5_digest = md5_digest
        @sha256 = sha256
      end
    end
  end
end