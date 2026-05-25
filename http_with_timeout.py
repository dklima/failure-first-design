# HTTP Request with Proper Timeouts
#
# A slow service is worse than a failed service.
# When a service returns an error, your circuit breaker opens and life goes on.
# When a service hangs, connections pile up, pools exhaust, queues fill,
# and suddenly you have a cascading failure.

import requests


class ServiceUnavailableError(Exception):
    pass


def fetch_with_timeout(
    url: str,
    connect_timeout: float = 2.0,
    read_timeout: float = 5.0,
) -> requests.Response:
    try:
        response = requests.get(url, timeout=(connect_timeout, read_timeout))
        response.raise_for_status()
        return response
    except (requests.ConnectionError, requests.Timeout) as e:
        raise ServiceUnavailableError(f"Service unavailable: {e}") from e


# Usage example:
# from http_with_timeout import fetch_with_timeout, ServiceUnavailableError
#
# try:
#     response = fetch_with_timeout("https://api.example.com/users/123")
#     data = response.json()
# except ServiceUnavailableError as e:
#     logging.error(str(e))
