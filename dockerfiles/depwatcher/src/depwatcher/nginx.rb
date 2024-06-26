require 'json'
require 'net/http'
require 'uri'
require 'openssl'
require_relative 'base'
require_relative 'github_tags'
require 'nokogiri'

module Depwatcher
  class Nginx < Base
    class Release
      attr_accessor :ref, :url, :pgp, :sha256

      def initialize(ref, url, pgp, sha256)
        @ref = ref
        @url = url
        @pgp = pgp
        @sha256 = sha256
      end
    end

    def check
      name = "nginx/nginx"
      regexp = /^release-\d+\.\d+\.\d+$/
      GithubTags.new.matched_tags(name, regexp).map do |r|
        Internal.new(r.name.gsub(/^release-/, ''))
      end.sort_by { |i| Semver.new(i.ref) }
    end

    def in(ref)
      url = "http://nginx.org/download/nginx-#{ref}.tar.gz"
      Release.new(ref, url, "http://nginx.org/download/nginx-#{ref}.tar.gz.asc", get_sha256(url))
    end

    private

    def get_sha256(url)
      uri = URI(url)
      response = Net::HTTP.get(uri)
      Digest::SHA256.hexdigest(response)
    end
  end
end