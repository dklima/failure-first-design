# HTTP Request with Proper Timeouts
#
# A slow service is worse than a failed service.
# When a service returns an error, your circuit breaker opens and life goes on.
# When a service hangs, connections pile up, pools exhaust, queues fill,
# and suddenly you have a cascading failure.

require 'net/http'

class ServiceUnavailableError < StandardError; end

def fetch_with_timeout(uri, open_timeout: 2, read_timeout: 5)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  http.open_timeout = open_timeout  # Timeout to open connection
  http.read_timeout = read_timeout  # Timeout to receive response

  begin
    response = http.request(Net::HTTP::Get.new(uri))
    response
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    # Fail fast, release resources, move on
    Rails.logger.error("Request timeout: #{e.message}") if defined?(Rails)
    raise ServiceUnavailableError, "Service unavailable: #{e.message}"
  end
end

# Usage example:
# uri = URI('https://api.example.com/users/123')
# response = fetch_with_timeout(uri, open_timeout: 2, read_timeout: 5)
