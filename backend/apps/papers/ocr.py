"""
Local OCR via Tesseract (pytesseract) — substitutes for Google Cloud Vision
per the plan's environment-forced substitutions (no GCP credentials exist
for this project). Swappable later behind the same function signature.
"""

import tempfile
from pathlib import Path

import pytesseract
from PIL import Image


def extract_text(file_path: str) -> str:
    """Runs OCR over an image file. PDFs are handled by extract_text_from_pdf."""
    path = Path(file_path)
    if path.suffix.lower() == ".pdf":
        return extract_text_from_pdf(file_path)
    with Image.open(file_path) as image:
        return pytesseract.image_to_string(image).strip()


def extract_text_from_pdf(file_path: str) -> str:
    from pdf2image import convert_from_path

    pages = convert_from_path(file_path)
    return "\n".join(pytesseract.image_to_string(page).strip() for page in pages)


def extract_text_from_fieldfile(field_file) -> str:
    """
    Same as extract_text, but for a Django FieldFile whose storage backend
    has no local filesystem path (e.g. Supabase Storage, an S3-compatible
    bucket) — pytesseract/pdf2image both need a real path, not a byte
    stream, so this stages the file through a local temp copy first.
    """
    suffix = Path(field_file.name).suffix
    with tempfile.NamedTemporaryFile(suffix=suffix) as tmp:
        field_file.open("rb")
        try:
            for chunk in field_file.chunks():
                tmp.write(chunk)
        finally:
            field_file.close()
        tmp.flush()
        return extract_text(tmp.name)
