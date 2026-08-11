"""
Local OCR via Tesseract (pytesseract) — substitutes for Google Cloud Vision
per the plan's environment-forced substitutions (no GCP credentials exist
for this project). Swappable later behind the same function signature.
"""

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
