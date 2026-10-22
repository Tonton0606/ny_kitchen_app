import unittest
import asyncio
from fastapi import HTTPException, UploadFile
import os
import sys
from io import BytesIO
from pathlib import Path

# Add ai_service to path
ai_service_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ai_service_dir))

from main import (
    validate_image_bytes,
    InMemoryRateLimiter,
    MAX_IMAGE_SIZE_BYTES,
    extract_encoding,
    check_liveness,
)

class TestB3Security(unittest.TestCase):
    def setUp(self):
        os.environ["AI_SERVICE_KEY"] = "test-secret-key"
        self.rate_limiter = InMemoryRateLimiter(requests_per_minute=5)

    def test_magic_bytes_valid_formats(self):
        """JPEG, PNG, WEBP, and BMP magic bytes must pass validation."""
        jpeg_sample = b"\xff\xd8\xff\xe0" + b"\x00" * 20
        png_sample = b"\x89PNG\r\n\x1a\n" + b"\x00" * 20
        webp_sample = b"RIFF" + b"\x00\x00\x00\x10" + b"WEBP" + b"\x00" * 10
        bmp_sample = b"BM" + b"\x00" * 20

        # Should not raise
        validate_image_bytes(jpeg_sample)
        validate_image_bytes(png_sample)
        validate_image_bytes(webp_sample)
        validate_image_bytes(bmp_sample)

    def test_magic_bytes_empty_payload(self):
        """Empty payload must raise HTTP 400."""
        with self.assertRaises(HTTPException) as ctx:
            validate_image_bytes(b"")
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertIn("empty", ctx.exception.detail.lower())

    def test_magic_bytes_invalid_format(self):
        """Non-image or unsupported binary payload must raise HTTP 400."""
        html_payload = b"<html><head></head><body>evil script</body></html>"
        with self.assertRaises(HTTPException) as ctx:
            validate_image_bytes(html_payload)
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertIn("magic bytes", ctx.exception.detail.lower())

    def test_payload_exceeds_max_size(self):
        """Payload exceeding MAX_IMAGE_SIZE_BYTES must raise HTTP 413."""
        oversized = b"\xff\xd8\xff" + b"0" * (MAX_IMAGE_SIZE_BYTES + 1)
        with self.assertRaises(HTTPException) as ctx:
            validate_image_bytes(oversized)
        self.assertEqual(ctx.exception.status_code, 413)

    def test_rate_limiter_allows_under_limit(self):
        """Requests under the limit should succeed."""
        client_id = "client-test-1"
        for _ in range(5):
            self.rate_limiter.check(client_id)

    def test_rate_limiter_blocks_over_limit(self):
        """Exceeding requests_per_minute must raise HTTP 429."""
        client_id = "client-test-2"
        for _ in range(5):
            self.rate_limiter.check(client_id)

        with self.assertRaises(HTTPException) as ctx:
            self.rate_limiter.check(client_id)
        self.assertEqual(ctx.exception.status_code, 429)
        self.assertIn("rate limit exceeded", ctx.exception.detail.lower())
        self.assertIn("Retry-After", ctx.exception.headers)

    def test_extract_encoding_rejects_invalid_magic_bytes(self):
        """extract_encoding endpoint must reject files failing magic-byte check with 400."""
        file = UploadFile(filename="corrupt.png", file=BytesIO(b"not a png image"))
        with self.assertRaises(HTTPException) as ctx:
            asyncio.run(extract_encoding(file))
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertIn("magic bytes", ctx.exception.detail.lower())

    def test_check_liveness_rejects_invalid_magic_bytes(self):
        """check_liveness endpoint must reject files failing magic-byte check with 400."""
        file = UploadFile(filename="malicious.html", file=BytesIO(b"<svg>alert(1)</svg>"))
        with self.assertRaises(HTTPException) as ctx:
            asyncio.run(check_liveness(file))
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertIn("magic bytes", ctx.exception.detail.lower())

if __name__ == "__main__":
    unittest.main()
