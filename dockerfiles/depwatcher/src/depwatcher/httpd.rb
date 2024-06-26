require 'json'
require 'net/http'
require 'uri'
require_relative 'base'
require_relative 'semver'
require_relative 'github_tags'

module Depwatcher
  class Httpd < Base
    class Release
      attr_accessor :ref, :url, :sha256

      def initialize(ref, url, sha256)
        @ref = ref
        @url = url
        @sha256 = sha256
      end
    end

    def check
      repo = "apache/httpd"
      regexp = /^\\d+\\.\\d+\\.\\d+$/
      GithubTags.new.matched_tags(repo, regexp).map do |r|
        Internal.new(r.name)
      end.sort_by { |i| Semver.new(i.ref) }
    end

    def in(ref)
      sha_response = Net::HTTP.get(URI("https://archive.apache.org/dist/httpd/httpd-#{ref}.tar.bz2.sha256"))
      sha256 = sha_response.split(" ")[0]
      Release.new(ref, "https://dlcdn.apache.org/httpd/httpd-#{ref}.tar.bz2", sha256)
    end
  end
end