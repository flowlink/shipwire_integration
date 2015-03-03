# The Order id we use to track is the Spree Shipment Number
#
# The <Bookmark> tag currently has three options:
# “1″ for a dump of everything in the account
# “2″ for a dump of everything since the last bookmark
# “3″ for a dump of everything since the last bookmark AND reset the bookmark to right now
class ShipmentTracking < ShipWire

  def consume
    response = self.class.post('/TrackingServices.php', :body => xml_body)

    if response['TrackingUpdateResponse']['Status'] == 'Error'
      raise SendError, response['TrackingUpdateResponse']['ErrorMessage']
    else
      msgs = []
      shipments = response['TrackingUpdateResponse']['Order']
      shipments = [ shipments ] if !shipments.is_a?(Array)

      shipments.each do |shipment|
        next unless shipment['shipped'] == 'YES'
        msgs << create_message(shipment)
      end

      return { 'messages' => msgs, 'shipwire_response' => response['TrackingUpdateResponse'] }.with_indifferent_access
    end
  end

  private

  def create_message(shipment)
    {
      id: shipment['id'].split(/-/).last,
      number: shipment['id'].split(/-/).last,
      order_id: shipment['id'].split(/-/).first,
      tracking: (shipment['TrackingNumber']['__content__'] || shipment['TrackingNumber']['#text']).strip,
      tracking_url: shipment['TrackingNumber']['href'],
      carrier: shipment['TrackingNumber']['carrier'],
      shipped_date: Time.parse(shipment['shipDate']).utc.to_s,
      delivery_date: Time.parse(shipment['expectedDeliveryDate']).utc.to_s,
      cost: 0.0,
      status: "shipped",
      stock_location: "",
      shipping_method: "",
    }
  end

  def xml_body
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.TrackingUpdate {
        xml.Username config['shipwire_username']
        xml.Password config['shipwire_password']
        xml.Server server_mode
        xml.Bookmark '3'
      }
    end
    builder.to_xml
  end
end
