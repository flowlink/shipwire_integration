require "sinatra"
require "endpoint_base"

require File.expand_path(File.dirname(__FILE__) + '/lib/shipwire_integration.rb')

class ShipwireEndpoint < EndpointBase::Sinatra::Base
  endpoint_key ENV["ENDPOINT_KEY"]

  Honeybadger.configure do |config|
    config.api_key = ENV['HONEYBADGER_KEY']
    config.environment_name = ENV['RACK_ENV']
  end if ENV['HONEYBADGER_KEY'].present?

  set :logging, true

  set :show_exceptions, :after_handler

  post '/add_shipment' do
    begin
      shipment_entry = ShipmentEntry.new(@payload, @config)
      response  = shipment_entry.consume

      summary = "Shipwire Shipment #{response["shipwire_response"]['TransactionId']} successfully created. "

      if (warnings = response["shipwire_response"]["OrderInformation"]["Order"]["WarningList"]["Warning"] rescue false)
        warnings = [ warnings ] if !warnings.is_a?(Array)
        summary << "Warnings: #{warnings.map(&:strip).join("\n")}"
      end

      result 200, summary
    rescue => e
      log_exception(e)
      result 500, e.message
    end
  end

  post '/get_shipments' do
    begin
      shipment_tracking = ShipmentTracking.new(@payload, @config)
      response = shipment_tracking.consume

      if messages = response[:messages]
        messages.each { |m| add_object :shipment, m }
        set_summary "Successfully received #{messages.count} shipment(s) from Shipwire"
      else
        set_summary "No new Shipwire shipments"
      end

      result 200
    rescue => e
      log_exception(e)
      result 500, e.message
    end
  end
end
