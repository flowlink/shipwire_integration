require 'nokogiri'

class ShipWire
  include HTTParty
  base_uri 'https://api.shipwire.com/exec/'
  format :xml

  attr_accessor :order, :api_key, :config, :payload

  def initialize(payload, config={})
    @payload = payload
    @config = config

    if @config['shipwire_beta']
      self.class.base_uri 'https://api.beta.shipwire.com/exec/'
    end

    authenticate!
  end

  def authenticate!
    raise AuthenticationError if @config['shipwire_username'].nil? || @config['shipwire_password'].nil?
  end

  def server_mode
    # Augury.test? ? 'Test' : 'Production'
    (ENV['SHIPWIRE_ENDPOINT_SERVER_MODE'] || 'Test').capitalize
  end

end

class AuthenticationError < StandardError; end
class ShipWireSubmitOrderError < StandardError; end
class SendError < StandardError; end
