require "yaml"
require "open-uri"

module Depwatcher
  class Ruby < Base
    class GithubRelease
      attr_reader :version, :url, :sha256

      def initialize(version:, url: {}, sha256: {})
        @version = version
        @url = url
        @sha256 = sha256
      end

      def self.from_yaml(yaml_string)
        data = YAML.safe_load(yaml_string, [Symbol])
        new(
          version: data['version'],
          url: data['url']&.transform_keys(&:to_s),
          sha256: data['sha256']&.transform_keys(&:to_s)
        )
      end
    end

    class Release
      attr_reader :ref, :url, :sha256

      def initialize(ref, url, sha256)
        @ref = ref
        @url = url
        @sha256 = sha256
      end
    end

    def check
      name = "ruby/ruby"
      regexp = "^v\\d+_\\d+_\\d+$"
      GithubTags.new(client).matched_tags(name, regexp).map do |r|
        Internal.new(r.name.gsub("_", ".").gsub(/^v/, ""))
      end.sort_by { |i| Semver.new(i.ref) }
    end

    def in(ref)
      result = release_from_github(ref)
      result ||= release_from_index(ref)
      result
    end

    private

    def release_from_github(ref)
      result = nil
      response = open("https://raw.githubusercontent.com/ruby/www.ruby-lang.org/master/_data/releases.yml").read
      versions = YAML.safe_load(response)

      versions.each do |data|
        release = GithubRelease.from_yaml(data)
        if release.version == ref
          if release.url["gz"] && release.sha256["gz"]
            result = Release.new(release.version, release.url["gz"], release.sha256["gz"])
          end
          break
        end
      end
      result
    end

    def release_from_index(ref)
      result = Release.new("", "", "")
      response = open("https://cache.ruby-lang.org/pub/ruby/index.txt").read

      response.each_line do |line|
        release_array = line.split(" ")
        raise "Could not parse ruby website" if release_array.empty?

        version = release_array[0].sub("ruby-", "")
        url = release_array[1]
        sha = release_array[3]

        if version == ref && url.end_with?("tar.gz")
          result = Release.new(version, url, sha)
          break
        end
      end
      raise "No release with ref: #{ref} found" if result.url.empty?

      result
    end
  end
end
