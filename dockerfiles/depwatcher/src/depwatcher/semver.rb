class Semver
  include Comparable

  attr_reader :original, :major, :minor, :patch, :metadata

  def initialize(original)
    @original = original
    m = original.match(/^v?(\d+)(\.(\d+))?(\.(\d+))?(.+)?/)
    if m
      @major = m[1].to_i
      @minor = m[3] ? m[3].to_i : 0
      @patch = m[5] ? m[5].to_i : 0
      @metadata = m[6]
    else
      raise ArgumentError, "Not a semantic version: #{original.inspect}"
    end
  end

  def <=>(other)
    r = major <=> other.major
    return r unless r.zero?
    r = minor <=> other.minor
    return r unless r.zero?
    r = patch <=> other.patch
    return r unless r.zero?

    original <=> other.original
  end

  def is_final_release?
    metadata.nil?
  end
end

class SemverFilter
  def initialize(filter_string)
    @filter_string = filter_string
  end

  def match(semver)
    semver_string = "#{semver.major}.#{semver.minor}.#{semver.patch}"
    first_x_idx = @filter_string.index("X")
    if first_x_idx.nil?
      semver_string == @filter_string
    else
      prefix = @filter_string[0, first_x_idx]
      semver_string.start_with?(prefix) && @filter_string.size <= semver_string.size
    end
  end
end