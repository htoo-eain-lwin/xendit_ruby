module Xendit
  class Configuration
    attr_accessor :api_key, :base_url, :timeout, :open_timeout, :faraday_adapter

    def initialize
      @base_url = 'https://api.xendit.co'
      @timeout = 30
      @open_timeout = 10
      @faraday_adapter = Faraday.default_adapter
    end

    def valid?
      !api_key.nil? && !api_key.empty?
    end
  end
end
