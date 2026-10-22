import ipaddress
import os
import socket
import sys
import unittest
from io import BytesIO
from pathlib import Path
from unittest.mock import patch, MagicMock

# Add ai_service to path
ai_service_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ai_service_dir))

from ssrf_protection import (
    validate_image_url,
    is_ip_forbidden,
    resolve_and_validate_host,
    safe_download_image,
    SSRFValidationError,
)

class TestSSRFProtection(unittest.TestCase):
    def setUp(self):
        os.environ["SUPABASE_URL"] = "https://xyzproject.supabase.co"

    def test_valid_supabase_url_passes(self):
        """Valid Supabase URLs (project host and *.supabase.co) must pass validation."""
        valid_urls = [
            "https://xyzproject.supabase.co/storage/v1/object/public/food_images/item1.png",
            "https://otherproject.supabase.co/storage/v1/object/public/food_images/adobo.jpg",
            "https://supabase.co/favicon.ico",
        ]
        for url in valid_urls:
            normalized, host, port = validate_image_url(url)
            self.assertTrue(normalized.startswith("https://"))
            self.assertEqual(port, 443)
            self.assertTrue(host.endswith("supabase.co"))

    def test_insecure_schemes_rejected(self):
        """http://, file://, ftp://, and other non-https schemes must be rejected."""
        insecure_urls = [
            "http://xyzproject.supabase.co/image.png",
            "file:///etc/passwd",
            "file://c:/windows/system32/calc.exe",
            "ftp://xyzproject.supabase.co/image.png",
            "gopher://xyzproject.supabase.co/",
            "data:image/png;base64,iVBORw0KGgoAAAANSUhEUg==",
        ]
        for url in insecure_urls:
            with self.assertRaises(SSRFValidationError, msg=f"Scheme in '{url}' must be rejected"):
                validate_image_url(url)

    def test_non_supabase_hosts_rejected(self):
        """Arbitrary external domains must be rejected."""
        foreign_urls = [
            "https://google.com/test.png",
            "https://attacker-controlled-site.org/payload.jpg",
            "https://aws.amazon.com/s3/bucket/img.png",
        ]
        for url in foreign_urls:
            with self.assertRaises(SSRFValidationError, msg=f"Host in '{url}' must be rejected"):
                validate_image_url(url)

    def test_lookalike_hosts_rejected(self):
        """Lookalike hosts (supabase.co.evil.com, evil.com/supabase.co) must be rejected."""
        lookalike_urls = [
            "https://supabase.co.evil.com/image.png",
            "https://evil.com/supabase.co/image.png",
            "https://evil-supabase.co/image.png",
            "https://not-supabase.co/image.png",
            "https://xsupabase.co/image.png",
        ]
        for url in lookalike_urls:
            with self.assertRaises(SSRFValidationError, msg=f"Lookalike host in '{url}' must be rejected"):
                validate_image_url(url)

    def test_credentials_and_non_standard_ports_rejected(self):
        """URLs containing credentials or non-standard ports must be rejected."""
        bad_urls = [
            "https://admin:password@xyzproject.supabase.co/image.png",
            "https://user@xyzproject.supabase.co/image.png",
            "https://xyzproject.supabase.co:8080/image.png",
            "https://xyzproject.supabase.co:8443/image.png",
            "https://xyzproject.supabase.co:22/image.png",
        ]
        for url in bad_urls:
            with self.assertRaises(SSRFValidationError, msg=f"Credentials/ports in '{url}' must be rejected"):
                validate_image_url(url)

    def test_forbidden_ip_ranges(self):
        """Private, loopback, link-local, and cloud metadata IPs must be identified as forbidden."""
        forbidden_ips = [
            "127.0.0.1",
            "127.0.1.1",
            "10.0.0.1",
            "10.254.0.1",
            "172.16.0.1",
            "172.31.255.254",
            "192.168.0.1",
            "192.168.1.100",
            "169.254.169.254", # AWS/GCP metadata service
            "169.254.1.1",     # Link-local
            "::1",             # IPv6 loopback
            "fc00::1",         # IPv6 unique local
            "fe80::1",         # IPv6 link-local
        ]
        for ip_str in forbidden_ips:
            ip_obj = ipaddress.ip_address(ip_str)
            self.assertTrue(
                is_ip_forbidden(ip_obj),
                f"IP address '{ip_str}' must be flagged as forbidden",
            )

        # Public IP must not be forbidden
        public_ip = ipaddress.ip_address("8.8.8.8")
        self.assertFalse(is_ip_forbidden(public_ip))

    def test_resolve_and_validate_host_blocks_private_ip(self):
        """DNS resolution returning private or loopback IP must raise SSRFValidationError."""
        with patch("socket.getaddrinfo") as mock_dns:
            mock_dns.return_value = [
                (socket.AF_INET, socket.SOCK_STREAM, 6, "", ("127.0.0.1", 443))
            ]
            with self.assertRaises(SSRFValidationError) as ctx:
                resolve_and_validate_host("xyzproject.supabase.co")
            self.assertIn("forbidden", str(ctx.exception).lower())

        with patch("socket.getaddrinfo") as mock_dns:
            mock_dns.return_value = [
                (socket.AF_INET, socket.SOCK_STREAM, 6, "", ("169.254.169.254", 443))
            ]
            with self.assertRaises(SSRFValidationError) as ctx:
                resolve_and_validate_host("xyzproject.supabase.co")
            self.assertIn("forbidden", str(ctx.exception).lower())

    @patch("ssrf_protection.resolve_and_validate_host")
    @patch("urllib.request.build_opener")
    def test_redirect_to_non_allowed_host_rejected(self, mock_build_opener, mock_resolve):
        """Redirect attempting to steer request to unauthorized host must be rejected."""
        mock_resolve.return_value = ["104.18.2.1"]
        mock_opener = MagicMock()
        mock_build_opener.return_value = mock_opener

        # First request returns 302 to evil.com
        redirect_response = MagicMock()
        redirect_response.status = 302
        redirect_response.headers = {"Location": "https://evil.com/stolen.png"}
        mock_opener.open.return_value = redirect_response

        with self.assertRaises(SSRFValidationError) as ctx:
            safe_download_image("https://xyzproject.supabase.co/image.png")
        self.assertIn("not an authorized supabase host", str(ctx.exception).lower())

    @patch("ssrf_protection.resolve_and_validate_host")
    @patch("urllib.request.build_opener")
    def test_more_than_3_redirects_rejected(self, mock_build_opener, mock_resolve):
        """Chains with more than 3 redirects must be rejected."""
        mock_resolve.return_value = ["104.18.2.1"]
        mock_opener = MagicMock()
        mock_build_opener.return_value = mock_opener

        # Create responses that perpetually redirect within allowed host
        redirect_response = MagicMock()
        redirect_response.status = 302
        redirect_response.headers = {"Location": "https://xyzproject.supabase.co/redirected"}
        mock_opener.open.return_value = redirect_response

        with self.assertRaises(SSRFValidationError) as ctx:
            safe_download_image("https://xyzproject.supabase.co/initial")
        self.assertIn("too many redirects", str(ctx.exception).lower())

    @patch("ssrf_protection.resolve_and_validate_host")
    @patch("urllib.request.build_opener")
    def test_oversized_response_rejected(self, mock_build_opener, mock_resolve):
        """Responses exceeding max_size_bytes (5MB) must be rejected."""
        mock_resolve.return_value = ["104.18.2.1"]
        mock_opener = MagicMock()
        mock_build_opener.return_value = mock_opener

        # Mock response with declared Content-Length > 5MB
        mock_response = MagicMock()
        mock_response.status = 200
        mock_response.headers = {"Content-Length": str(6 * 1024 * 1024)} # 6MB
        mock_opener.open.return_value = mock_response

        with self.assertRaises(SSRFValidationError) as ctx:
            safe_download_image("https://xyzproject.supabase.co/huge_image.png")
        self.assertIn("exceeds limit", str(ctx.exception).lower())

if __name__ == "__main__":
    unittest.main()
