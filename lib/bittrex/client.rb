require 'faraday'
require 'base64'
require 'json'

module Bittrex
  class Client
    HOST = 'https://bittrex.com/api/v1.1'

    attr_reader :key, :secret

    def initialize(attrs = {})
      @key    = attrs[:key]
      @secret = attrs[:secret]
    end

    def get(path, params = {}, headers = {})
      nonce = Time.now.to_i
      response = connection.get do |req|
        url = "#{HOST}/#{path}"
        req.params.merge!(params)
        req.url(url)

        if key
          req.params[:apikey]   = key
          req.params[:nonce]    = nonce
          url = Faraday::Connection.new.build_exclusive_url(
            req.path,
            req.params,
            req.options.params_encoder
          ).to_s
          req.headers[:apisign] = signature(url, nonce)
        end
      end

      JSON.parse(response.body)['result']
    end

    private

    def signature(url, nonce)
      OpenSSL::HMAC.hexdigest('sha512', secret, url)
    end

    def connection
      @connection ||= Faraday.new(:url => HOST) do |faraday|
        faraday.request  :url_encoded
        faraday.adapter  Faraday.default_adapter
      end
    end
  end
end
