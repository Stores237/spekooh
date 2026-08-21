"""
Auto-watermarking for Academic Report uploads (owner decision: static
Spekooh branding, applied once when the file is submitted — not
per-viewer). PDFs and images are the only formats Submit's file picker
accepts (see app's SubmitScreen), so those are the only two handled;
anything else passes through unchanged rather than raising.
"""

import io
import logging
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
from pypdf import PdfReader, PdfWriter
from pypdf.errors import PyPdfError
from reportlab.lib.colors import Color
from reportlab.pdfgen import canvas

logger = logging.getLogger(__name__)

WATERMARK_TEXT = "Spekooh — spekooh.com"


def watermark_bytes(content: bytes, filename: str) -> bytes:
    """Never blocks a submission — a corrupt/unsupported file falls back to
    the original bytes rather than failing the whole request. Real user
    uploads can be malformed in ways a test fixture never is."""
    suffix = Path(filename).suffix.lower()
    try:
        if suffix == ".pdf":
            return _watermark_pdf(content)
        if suffix in (".jpg", ".jpeg", ".png"):
            return _watermark_image(content, suffix)
    except (PyPdfError, OSError) as exc:
        logger.warning("Watermarking failed for %s, storing the original file: %s", filename, exc)
    return content


def _watermark_pdf(content: bytes) -> bytes:
    # clone_from (not PdfWriter() + writer.add_page(reader_page)) — merging
    # an overlay onto a page that was never attached to its writer is
    # deprecated in pypdf and slated for removal in 7.0.
    writer = PdfWriter(clone_from=io.BytesIO(content))

    for page in writer.pages:
        width = float(page.mediabox.width)
        height = float(page.mediabox.height)

        overlay_buf = io.BytesIO()
        c = canvas.Canvas(overlay_buf, pagesize=(width, height))
        c.saveState()
        c.setFillColor(Color(0, 0, 0, alpha=0.15))
        c.setFont("Helvetica-Bold", min(width, height) * 0.06)
        c.translate(width / 2, height / 2)
        c.rotate(45)
        c.drawCentredString(0, 0, WATERMARK_TEXT)
        c.restoreState()
        c.save()
        overlay_buf.seek(0)

        overlay_page = PdfReader(overlay_buf).pages[0]
        page.merge_page(overlay_page)

    out = io.BytesIO()
    writer.write(out)
    return out.getvalue()


def _watermark_image(content: bytes, suffix: str) -> bytes:
    image = Image.open(io.BytesIO(content)).convert("RGBA")
    overlay = Image.new("RGBA", image.size, (255, 255, 255, 0))
    draw = ImageDraw.Draw(overlay)

    font_size = max(18, min(image.size) // 12)
    try:
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", font_size)
    except OSError:
        font = ImageFont.load_default()

    text_layer = Image.new("RGBA", (image.size[0] * 2, font_size * 2), (255, 255, 255, 0))
    text_draw = ImageDraw.Draw(text_layer)
    text_draw.text((0, 0), WATERMARK_TEXT, font=font, fill=(0, 0, 0, 60))
    text_layer = text_layer.rotate(45, expand=True)

    x = (image.size[0] - text_layer.size[0]) // 2
    y = (image.size[1] - text_layer.size[1]) // 2
    overlay.alpha_composite(text_layer, (x, y))

    watermarked = Image.alpha_composite(image, overlay)
    out = io.BytesIO()
    if suffix in (".jpg", ".jpeg"):
        watermarked = watermarked.convert("RGB")
        watermarked.save(out, format="JPEG", quality=92)
    else:
        watermarked.save(out, format="PNG")
    return out.getvalue()
