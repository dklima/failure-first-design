# Retry with Exponential Backoff and Jitter
#
# Prevents retry storms by spreading retry attempts over time.
# Without jitter, all failed clients retry at the same instant,
# creating a thundering herd that can collapse an already degraded system.

def retry_with_backoff(max_retries: 5)
  attempt = 0

  begin
    yield
  rescue StandardError => e
    attempt += 1
    raise e if attempt >= max_retries

    # Exponential backoff: 1s, 2s, 4s, 8s...
    base_delay = 2**attempt

    # Jitter: adds random variation of 0-50%
    # This prevents all clients from retrying at the same instant
    jitter = rand * 0.5 * base_delay

    sleep(base_delay + jitter)
    retry
  end
end

# Usage example:
# retry_with_backoff(max_retries: 3) do
#   api_client.fetch_user(user_id)
# end
