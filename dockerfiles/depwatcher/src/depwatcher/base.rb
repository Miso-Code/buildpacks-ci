require 'net/http'
require 'uri'
require 'json'

module Depwatcher
  module HTTPClient
    def get(url, headers = nil)
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def inject_oauth_authorization_token_into_header(headers = nil)
      api_key = ENV["OAUTH_AUTHORIZATION_TOKEN"]
      headers ||= {}
      headers["Authorization"] = "token #{api_key}" if api_key
      headers
    end
  end

  class HTTPClientImpl
    include HTTPClient

    def get(url, headers = nil)
      headers = inject_oauth_authorization_token_into_header(headers)
      uri = URI(url)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new(uri)
        headers.each { |key, value| request[key] = value }
        http.request(request)
      end

      case response
      when Net::HTTPRedirection
        get(response['location'], headers)
      when Net::HTTPSuccess
        response
      else
        raise "Could not download data from #{url}: code #{response.code}"
      end
    end
  end
end