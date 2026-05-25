# Retry with Exponential Backoff and Jitter
#
# Prevents retry storms by spreading retry attempts over time.
# Without jitter, all failed clients retry at the same instant,
# creating a thundering herd that can collapse an already degraded system.

import random
import time
from typing import Callable, TypeVar

T = TypeVar("T")


def retry_with_backoff(
    fn: Callable[[], T],
    max_retries: int = 5,
) -> T:
    for attempt in range(1, max_retries + 1):
        try:
            return fn()
        except Exception:
            if attempt >= max_retries:
                raise

            # Exponential backoff: 2s, 4s, 8s, 16s...
            base_delay = 2**attempt

            # Jitter: adds random variation of 0-50%
            jitter = random.random() * 0.5 * base_delay

            time.sleep(base_delay + jitter)


# Usage example:
# from retry_with_backoff import retry_with_backoff
#
# def fetch_user():
#     return api_client.get(f"/users/{user_id}")
#
# result = retry_with_backoff(fetch_user, max_retries=3)
