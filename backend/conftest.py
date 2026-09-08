import pytest
from django.core.cache import cache
from django.test import override_settings


@pytest.fixture(autouse=True)
def _local_file_storage(tmp_path):
    """CI never has real AWS_* credentials, so config/settings/base.py's own
    documented STORAGES fallback (FileSystemStorage when AWS_STORAGE_BUCKET_NAME
    is unset) already makes it hermetic there. But any developer running
    tests locally against a real .env — which RUNNING_LOCALLY.md explicitly
    recommends for testing real uploads — has real credentials configured,
    so every uploaded_file/avatar save in the suite silently becomes a live
    network call to the real Supabase Storage bucket instead. Confirmed live
    (2026-09-08): a transient real S3 blip failed 14 unrelated tests with an
    unparseable, empty botocore error, momentarily looking like a real
    regression from an unrelated Django/DRF dependency bump — it wasn't; the
    exact same tests passed cleanly minutes later, unchanged.

    Forces local disk storage (a fresh pytest tmp_path per test, so runs
    stay isolated from each other and from the real dev media/ directory)
    regardless of what real credentials happen to be in .env. A no-op for
    CI, which already gets this by omission; a real fix for anyone running
    the suite locally with real credentials configured — same "tests must
    not depend on a live external service's uptime" reasoning as this
    file's own _clear_cache fixture, just for file storage instead of Redis.

    Individual tests that need to exercise the real S3-backed code path on
    purpose (e.g. apps.papers.tests's fake_s3_storage-driven presign tests)
    mock the storage client directly rather than going through Django's
    storage abstraction at all, so this fixture doesn't affect them; a test
    that instead sets settings.STORAGES itself (e.g.
    test_upload_url_returns_503_when_storage_has_no_presign_concept) simply
    overrides this fixture's own baseline for its own duration, same as any
    nested override_settings would.
    """
    with override_settings(
        STORAGES={
            "default": {"BACKEND": "django.core.files.storage.FileSystemStorage", "OPTIONS": {"location": str(tmp_path)}},
            "staticfiles": {"BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage"},
        }
    ):
        yield


@pytest.fixture(autouse=True)
def _clear_cache():
    """CACHES now points at real Redis (see config/settings/base.py), not
    an in-memory per-process cache — its state survives across test runs,
    unlike the DB (which pytest-django rolls back per test). Without this,
    DRF's guest-mint throttle (backed by this same cache) would accumulate
    hits across repeated local test runs and eventually 429 a test that
    has nothing to do with rate limiting."""
    cache.clear()
    yield
