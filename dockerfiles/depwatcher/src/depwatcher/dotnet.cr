require "./base"
require "./semantic_version"
require "./github_releases"
require "./github_tags"

module Depwatcher
  class Dotnet < Base
    class DotnetRelease
      JSON.mapping(
        ref: String,
        url: String,
        git_commit_sha: String,
      )

      def initialize(
        @ref : String,
        @url : String,
        @git_commit_sha : String
      )
      end
    end

    class External
      JSON.mapping(
        name: String,
        commit: String
      )

      def initialize(
        @name : String,
        @commit : String
      )
      end
    end

    def check : Array(Internal)
      dotnet_tags.map{|t| Internal.new(t.name) }.sort_by { |i| SemanticVersion.new(i.ref) }
    end

    def in(ref : String) : DotnetRelease
      tag = dotnet_tags.select{|t| t.name == ref}.first
      DotnetRelease.new(tag.name, "https://github.com/dotnet/cli", tag.commit)
    end

    private def dotnet_tags() : Array(External)
      GithubTags.new(client).matched_tags("dotnet/cli", ".*\\+dependencies")
        .map do |t|
          m = t.name.match(/\d+\.\d+\.\d+/)
          if !m.nil?
            External.new(m[0], t.commit.sha)
          end
        end.compact
    end
  end
end
