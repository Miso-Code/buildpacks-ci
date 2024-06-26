require 'net/http'
require 'nokogiri'
require 'uri'

class Python
  class Release
    attr_accessor :ref, :url, :md5_digest, :sha256

    def initialize(ref, url, md5_digest, sha256)
      @ref = ref
      @url = url
      @md5_digest = md5_digest
      @sha256 = sha256
    end
  end

  def check
    uri = URI("https://www.python.org/downloads/")
    response = Net::HTTP.get(uri)
    doc = Nokogiri::HTML(response)
    lis = doc.xpath("//*[contains(@class,'release-number')]/a")
    raise Exception.new("Could not parse python website") if lis.empty?
    lis.map { |v| Internal.new(v.text.strip.gsub('Python ', '')) }[0...50].reverse
  end

  def in_release(ref)
    uri = URI("https://www.python.org/downloads/release/python-#{ref.gsub('.', '')}/")
    response = Net::HTTP.get(uri)
    doc = Nokogiri::HTML(response)
    a = doc.xpath("//a[contains(text(),'Gzipped source tarball')]")
    raise Exception.new("Could not parse python release website") if a.empty?
    a = a.first
    # Further processing to extract and return a Release object would go here
  end

  class Internal
    attr_accessor :ref

    def initialize(ref)
      @ref = ref
    end
  end
end