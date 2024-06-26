require './github_releases.rb'

module Depwatcher
  class Icu < GithubReleases
    class GithubRelease
      attr_accessor :tag_name, :draft, :prerelease, :assets

      def initialize(json)
        @tag_name = json['tag_name']
        @draft = json['draft']
        @prerelease = json['prerelease']
        @assets = json['assets'].map { |asset| GithubAsset.new(asset) }
      end

      def ref
        version = tag_name.gsub(/^release-/, '').gsub(/-/, '.')
        version += '.0' if version =~ /^\d+\.\d+$/
        version
      end
    end

    def check
      repo = 'unicode-org/icu'
      allow_prerelease = false
      super(repo, allow_prerelease)
    end

    def in(ref, dir)
      repo = 'unicode-org/icu'
      ext = '-src.tgz'
      super(repo, ext, ref, dir)
    end
  end
end