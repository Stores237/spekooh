"""
Real concurrent-load pass against live spekooh-staging, per the release
roadmap's own P1 item ("A load pass at realistic volume"). Thread-pool
based (not async) so it needs nothing beyond `requests`, already a real
dependency everywhere else in this codebase.

Deliberately uses @example.com emails throughout — this codebase's own
reserved test domain (see apps.accounts.management.commands
.delete_test_accounts) — so real registrations from this run are safely
identifiable and cleanable afterward via the real
/internal/tasks/delete-test-accounts/ endpoint (needs the real
TASK_TRIGGER_TOKEN, which isn't available from this sandbox — the owner
has it on Render).

Reports latency percentiles and status-code distribution per phase, and
flags the first 5xx/timeout it sees — this is a "find the first thing
that breaks," not a benchmark-for-its-own-sake run.
"""

import statistics
import sys
import time
import uuid
from concurrent.futures import ThreadPoolExecutor

import requests

BASE = "https://spekooh-staging.onrender.com"
RUN_ID = uuid.uuid4().hex[:8]


def _timed_request(method: str, path: str, **kwargs) -> tuple[int, float, str]:
    start = time.monotonic()
    try:
        response = requests.request(method, f"{BASE}{path}", timeout=30, **kwargs)
        elapsed = time.monotonic() - start
        return response.status_code, elapsed, ""
    except requests.RequestException as exc:
        elapsed = time.monotonic() - start
        return 0, elapsed, type(exc).__name__


def _report(phase: str, results: list[tuple[int, float, str]]) -> None:
    statuses = [r[0] for r in results]
    latencies = [r[1] for r in results]
    errors = [r for r in results if r[0] == 0 or r[0] >= 500]
    ok = sum(1 for s in statuses if 200 <= s < 400)
    print(f"\n=== {phase} ({len(results)} requests) ===")
    print(f"  2xx/3xx: {ok}   4xx: {sum(1 for s in statuses if 400 <= s < 500)}   5xx/error: {len(errors)}")
    if latencies:
        sorted_lat = sorted(latencies)
        p50 = sorted_lat[len(sorted_lat) // 2]
        p95 = sorted_lat[int(len(sorted_lat) * 0.95)]
        print(f"  latency: min={min(latencies):.2f}s  p50={p50:.2f}s  p95={p95:.2f}s  max={max(latencies):.2f}s  mean={statistics.mean(latencies):.2f}s")
    if errors:
        print(f"  FIRST ERROR: status={errors[0][0]} detail={errors[0][2]}")
        # Show up to 3 distinct error shapes, not just the first.
        seen = set()
        for status, _, detail in errors:
            key = (status, detail)
            if key not in seen:
                seen.add(key)
                print(f"    - status={status} detail={detail}")
            if len(seen) >= 3:
                break


def warm_up() -> None:
    print("Warming up (waking any cold instance)...")
    for attempt in range(3):
        status, elapsed, err = _timed_request("GET", "/healthz/")
        print(f"  attempt {attempt + 1}: status={status} elapsed={elapsed:.2f}s err={err}")
        if status == 200:
            return
        time.sleep(5)
    print("  WARNING: /healthz/ never returned 200 during warm-up — proceeding anyway.")


def phase_guest_mint(n: int, concurrency: int) -> None:
    def _one(_i):
        return _timed_request("POST", "/api/auth/guest/", json={})

    with ThreadPoolExecutor(max_workers=concurrency) as pool:
        results = list(pool.map(_one, range(n)))
    _report(f"Guest mint x{n} (concurrency={concurrency})", results)


def phase_register(n: int, concurrency: int) -> list[str]:
    emails = [f"loadtest-{RUN_ID}-{i}@example.com" for i in range(n)]

    def _one(email):
        return _timed_request(
            "POST",
            "/api/auth/register/",
            json={
                "email": email,
                "name": "Load Test",
                "password": "S0mePass!23",
                "terms_accepted": True,
            },
        )

    with ThreadPoolExecutor(max_workers=concurrency) as pool:
        results = list(pool.map(_one, emails))
    _report(f"Register x{n} (concurrency={concurrency})", results)
    return emails


def phase_login(emails: list[str], concurrency: int) -> None:
    def _one(email):
        return _timed_request("POST", "/api/auth/login/", json={"email": email, "password": "S0mePass!23"})

    with ThreadPoolExecutor(max_workers=concurrency) as pool:
        results = list(pool.map(_one, emails))
    _report(f"Login x{len(emails)} (concurrency={concurrency})", results)


def phase_browse(n: int, concurrency: int) -> None:
    def _one(_i):
        return _timed_request("GET", "/api/papers/categories/")

    with ThreadPoolExecutor(max_workers=concurrency) as pool:
        results = list(pool.map(_one, range(n)))
    _report(f"Browse categories x{n} (concurrency={concurrency})", results)


if __name__ == "__main__":
    # Two different scales on purpose. /api/papers/categories/ is
    # unthrottled and read-only — a real, honest concurrency/capacity
    # signal at real volume. register/guest_mint/login are all per-IP
    # throttled (10/hour, 10/hour, 20/hour) — from this sandbox's single
    # IP, anything near those limits just tests the throttle itself
    # (a real distributed attack would come from many IPs, which this
    # single-machine script can't simulate). Kept deliberately under each
    # endpoint's own cap so the run actually reaches the real
    # register/login code path instead of a wall of 429s.
    browse_n = int(sys.argv[1]) if len(sys.argv) > 1 else 200
    browse_concurrency = int(sys.argv[2]) if len(sys.argv) > 2 else 40
    auth_n = 8

    print(f"Run ID: {RUN_ID}  |  browse_n={browse_n} (concurrency={browse_concurrency})  auth_n={auth_n}  target={BASE}")
    warm_up()
    phase_browse(browse_n, browse_concurrency)
    phase_guest_mint(auth_n, auth_n)
    emails = phase_register(auth_n, auth_n)
    phase_login(emails, auth_n)
    print(f"\nDone. Test accounts use emails matching 'loadtest-{RUN_ID}-*@example.com' "
          f"— safe to clean up via /internal/tasks/delete-test-accounts/ (real TASK_TRIGGER_TOKEN needed).")
