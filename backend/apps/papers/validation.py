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

Also backs the plain Django model-field validators below
(validate_pdf_file_content, validate_document_file_content) — reused for
the admin-only upload fields added 2026-09-17 (Note.pdf_file,
PartnerBookshop.cni_document/nui_document) that go through a plain
Django ModelForm rather than a DRF serializer, closing the same
"extension only, never verified" gap for those too.
"""

from django.core.exceptions import ValidationError

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


def _is_new_upload(file) -> bool:
    """True only for a file assigned this request and not yet saved to
    storage. Django's FileField descriptor always wraps whatever's
    assigned in a FieldFile (never hands a validator the raw UploadedFile
    directly) — `_committed` is the real, stable signal Django itself
    uses to distinguish "just assigned, not yet persisted" (False) from
    an existing, already-saved file being resubmitted unchanged (True),
    e.g. when an admin form edits some other field and re-posts this
    one's existing value. Reading/seeking is only guaranteed to behave
    like a genuinely local file for the former."""
    return not getattr(file, "_committed", True)


def _is_real_match(file) -> bool:
    """True if `file`'s actual bytes match what its own extension claims.
    Only ever reads bytes for a genuinely new upload (see
    _is_new_upload) — an already-saved file resubmitted unchanged is
    trusted as already-validated at its original upload time, since
    seeking a remote storage-backed file isn't guaranteed to work the
    same way a fresh local upload's file object does."""
    if not _is_new_upload(file):
        return True
    header = file.read(SNIFF_BYTES)
    file.seek(0)
    return content_matches_filename(file.name, header)


def validate_pdf_file_content(file) -> None:
    """Model-field validator for a field that must always be a real PDF
    (Note.pdf_file) — stricter than validate_document_file_content:
    rejects a non-.pdf extension outright, not just a mismatched one."""
    if _is_new_upload(file) and not file.name.lower().endswith(".pdf"):
        raise ValidationError("Upload a PDF file.")
    if not _is_real_match(file):
        raise ValidationError("This doesn't look like a real PDF file.")


def validate_document_file_content(file) -> None:
    """Model-field validator for a field that accepts either a scanned
    photo or a PDF of a real document (PartnerBookshop.cni_document/
    nui_document) — any of this app's three accepted signatures is fine,
    as long as the file's actual bytes match what its extension claims."""
    if not _is_real_match(file):
        raise ValidationError("This file doesn't look like a real PDF or image.")
