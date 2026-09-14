"""
Real magic-byte content-sniffing for uploaded papers/reports — closes a
documented SECURITY.md "Known gap": only file size and the client-declared
Content-Type were checked before, so a file renamed to claim a PDF/image
extension it wasn't was never independently verified server-side.

Hand-rolled signature checks, not python-magic — the only three types this
app ever accepts (app/lib/screens/submit/submit_screen.dart's own
allowedExtensions: pdf, jpg/jpeg, png) have short, unambiguous magic
bytes, so pulling in a whole extra system dependency (libmagic, needing
its own Dockerfile apt-get line — see backend/Dockerfile's own history
with Tesseract) isn't worth it for three fixed signatures.
"""

# Longest signature below, in bytes — the most a caller ever needs to read
# to sniff any of these three types.
SNIFF_BYTES = 8

_SIGNATURES: dict[str, bytes] = {
    "application/pdf": b"%PDF-",
    "image/jpeg": b"\xff\xd8\xff",
    "image/png": b"\x89PNG\r\n\x1a\n",
}

_EXTENSION_TO_CONTENT_TYPE: dict[str, str] = {
    "pdf": "application/pdf",
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg",
    "png": "image/png",
}


def expected_content_type_for_filename(filename: str) -> str | None:
    """What content type a file with this name/key claims to be, by its
    extension — None for an extension this app doesn't accept at all
    (validate_storage_key/FilePicker's own allowedExtensions already
    restrict this in practice, but a mismatch here still means "reject",
    not "assume application/octet-stream")."""
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else ""
    return _EXTENSION_TO_CONTENT_TYPE.get(ext)


def sniff_content_type(header: bytes) -> str | None:
    """The real content type implied by these leading bytes, or None if
    they don't match any type this app accepts."""
    for content_type, signature in _SIGNATURES.items():
        if header.startswith(signature):
            return content_type
    return None


def content_matches_filename(filename: str, header: bytes) -> bool:
    """True only if the filename's own extension is one this app accepts
    AND the file's actual leading bytes genuinely match that type — the
    real check a renamed-extension attack (e.g. a .exe saved as
    submission.pdf) fails."""
    expected = expected_content_type_for_filename(filename)
    return expected is not None and sniff_content_type(header) == expected
