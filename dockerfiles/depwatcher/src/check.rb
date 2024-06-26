require "./depwatcher/*"
require "json"

data = JSON.parse(STDIN.read)
$stderr.puts data.to_json
source = data["source"]

case source["type"].to_s
when "github_releases"
  allow_prerelease = source["prerelease"]&.as_bool
  versions = if allow_prerelease
              Depwatcher::GithubReleases.new.check(source["repo"].to_s, allow_prerelease)
            else
              Depwatcher::GithubReleases.new.check(source["repo"].to_s, false)
            end
when "github_tags"
  versions = Depwatcher::GithubTags.new.check(source["repo"].to_s, source["tag_regex"].to_s)
when "jruby"
  versions = Depwatcher::JRuby.new.check
when "miniconda"
  versions = Depwatcher::Miniconda.new.check(source["python_version"].to_s)
when "rubygems"
  versions = Depwatcher::Rubygems.new.check(source["name"].to_s)
when "rubygems_cli"
  versions = Depwatcher::RubygemsCli.new.check
when "pypi"
  versions = Depwatcher::Pypi.new.check(source["name"].to_s)
when "ruby"
  versions = Depwatcher::Ruby.new.check
when "php"
  versions = Depwatcher::Php.new.check
when "python"
  versions = Depwatcher::Python.new.check
when "go"
  versions = Depwatcher::Go.new.check
when "r"
  versions = Depwatcher::R.new.check
when "npm"
  versions = Depwatcher::Npm.new.check(source["name"].to_s)
when "node"
  version_filter = source["version_filter"]&.to_s
  if version_filter == "node-lts"
    versions = Depwatcher::NodeLTS.new.check
  else
    versions = Depwatcher::Node.new.check
  end
when "nginx"
  versions = Depwatcher::Nginx.new.check
when "openresty"
  versions = Depwatcher::Openresty.new.check
when "httpd"
  versions = Depwatcher::Httpd.new.check
when "ca_apm_agent"
  versions = Depwatcher::CaApmAgent.new.check
when "appd_agent"
  versions = Depwatcher::AppDynamicsAgent.new.check
when "dotnet-sdk"
  versions = Depwatcher::DotnetSdk.new.check(source.fetch("version_filter", "latest").to_s)
when "dotnet-runtime"
  versions = Depwatcher::DotnetRuntime.new.check(source.fetch("version_filter", "latest").to_s)
when "dotnet-aspnetcore"
  versions = Depwatcher::AspnetcoreRuntime.new.check(source.fetch("version_filter", "latest").to_s)
when "rserve"
  versions = Depwatcher::CRAN.new.check("Rserve")
when "forecast"
  versions = Depwatcher::CRAN.new.check("forecast")
when "plumber"
  versions = Depwatcher::CRAN.new.check("plumber")
when "shiny"
  versions = Depwatcher::CRAN.new.check("shiny")
when "icu"
  versions = Depwatcher::Icu.new.check
else
  raise "Unknown type: #{source["type"]}"
end

# Filter out irrelevant versions
version_filter = source["version_filter"]&.to_s
if version_filter && version_filter != "node-lts"
  filter = SemverFilter.new(version_filter)
  versions.select! { |v| filter.match(Semver.new(v.ref)) }
end

# Filter out versions concourse already knows about
version = data["version"]&.fetch("ref", nil)
if version
  ref = Semver.new(version.to_s) rescue nil
  versions.reject! { |v| Semver.new(v.ref) < ref } if ref
end

puts versions.to_json