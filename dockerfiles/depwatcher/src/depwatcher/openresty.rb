require 'json'
require 'net/http'
require 'uri'
require 'openssl'

module Depwatcher
  class Openresty
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
      name = "openresty/openresty"
      regexp = /\d+\.\d+\.\d+\.\d+$/
      github_releases = GithubReleases.new
      releases = github_releases.matched_releases(name, regexp)
      releases.map do |r|
        Internal.new(r.ref.gsub(/^v/, ''))
      end.sort_by { |i| Semver.new(i.ref) }
    end

    def in(ref)
      url = "http://openresty.org/download/openresty-#{ref}.tar.gz"
      pgp_url = "http://openresty.org/download/openresty-#{ref}.tar.gz.asc"
      sha256 = get_sha256(url)
      Release.new(ref, url, pgp_url, sha256)
    end

    private

    def get_sha256(url)
      uri = URI(url)
      response = Net::HTTP.get(uri)
      Digest::SHA256.hexdigest(response)
    end
  end
end