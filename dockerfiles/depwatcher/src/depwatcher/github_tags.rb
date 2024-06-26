require_relative 'base'
require_relative 'semver'

module Depwatcher
  class GithubTags < Base
    class Tag
      attr_accessor :ref, :url, :git_commit_sha, :sha256

      def initialize(ref, url, git_commit_sha, sha256)
        @ref = ref
        @url = url
        @git_commit_sha = git_commit_sha
        @sha256 = sha256
      end
    end

    class External
      attr_accessor :name, :commit

      def initialize(name, commit)
        @name = name
        @commit = commit
      end
    end

    class Commit
      attr_accessor :sha

      def initialize(sha)
        @sha = sha
      end
    end
  end
end