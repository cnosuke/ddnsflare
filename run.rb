require 'rubyflare'
require 'open-uri'

CF_API_KEY = ENV['CF_API_KEY']
CF_API_MAIL = ENV['CF_API_MAIL']
CF_ZONE = ENV['CF_ZONE']
CF_DOMAIN_NAME = ENV['CF_DOMAIN_NAME']
CF_TTL = ENV['CF_TTL'] || 300

class DDNSFlare
  class << self
    def connection
      @connection ||= Rubyflare.connect_with(CF_API_MAIL, CF_API_KEY)
    end

    def zone_id
      @zone_id ||= connection.get('zones', { name: CF_ZONE }).result[:id]
    end

    def base_params
      {
        type: 'A',
        name: CF_DOMAIN_NAME,
      }
    end

    def fetch_record
      connection.get(
        "zones/#{zone_id}/dns_records",
        base_params
      ).result
    end

    def create_record!(global_ip)
      record_params = base_params.merge(content: global_ip, ttl: CF_TTL)
      exist_record_id = fetch_record&.fetch(:id, nil)
      if exist_record_id
        connection.put("zones/#{zone_id}/dns_records/#{exist_record_id}", record_params)
      else
        connection.post("zones/#{zone_id}/dns_records", record_params)
      end
    end
  end
end

gip = open('http://dyn.value-domain.com/cgi-bin/dyn.fcg?ip').read
DDNSFlare.create_record!(gip)
