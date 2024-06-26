require 'json'
require 'net/http'
require 'uri'
require_relative 'base'
require_relative 'semver'

module Depwatcher
  class GithubReleases < Base
    class Release
      attr_accessor :ref, :url, :sha256

      def initialize(ref, url, sha256)
        @ref = ref
        @url = url
        @sha256 = sha256
      end
    end

    class GithubAsset
      attr_accessor :name, :browser_download_url

      def initialize(name, browser_download_url)
        @name = name
        @browser_download_url = browser_download_url
      end
    end

    class GithubRelease
      attr_accessor :tag_name, :draft, :prerelease, :assets

      def initialize(tag_name, draft, prerelease, assets)
        @tag_name = tag_name
        @draft = draft
        @prerelease = prerelease
        @assets = assets.map { |asset| GithubAsset.new(asset['name'], asset['browser_download_url']) }
      end
    end
  end
end