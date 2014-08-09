require "sinatra"
require "endpoint_base"

require File.expand_path(File.dirname(__FILE__) + '/lib/ship_wire.rb')
Dir['./lib/**/*.rb'].each { |f| require f }

class ShipwireEndpoint < EndpointBase::Sinatra::Base
  set :logging, true

  post '/add_shipment' do
    begin
  	  shipment_entry = ShipmentEntry.new(@payload, @config)
  	  response  = shipment_entry.consume

      summary = "Shipwire Shipment #{response["shipwire_response"]['TransactionId']} successfully created. "

      if (warnings = response["shipwire_response"]["OrderInformation"]["Order"]["WarningList"]["Warning"] rescue false)
        summary << "Warnings: #{warnings.map(&:strip).join("\n")}"
      end

      result 200, summary
    rescue => e
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
      end

      result 200
    rescue => e
      result 500, e.message
    end
  end
end
