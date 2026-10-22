import ipaddress
import os
import socket
import urllib.parse
import urllib.request
from typing import Tuple, List

class SSRFValidationError(Exception):
    """Raised when a URL violates SSRF security policy."""
    pass

def is_ip_forbidden(ip: ipaddress.IPv4Address | ipaddress.IPv6Address) -> bool:
    """Checks whether an IP address belongs to private, loopback, link-local, or reserved ranges."""
    if (
        ip.is_private or
        ip.is_loopback or
        ip.is_link_local or
        ip.is_reserved or
        ip.is_multicast or
        ip.is_unspecified
    ):
        return True
    
    # Cloud metadata service IPs (e.g., AWS, GCP, Azure 169.254.169.254)
    if str(ip) == "169.254.169.254":
        return True

    return False

def validate_image_url(url: str) -> Tuple[str, str, int]:
    """
    Validates that a URL satisfies SSRF protection rules:
    - Scheme must be https (reject http, file, ftp, etc.)
    - Host must match configured SUPABASE_URL host or be a valid *.supabase.co domain
    - Credentials (user:pass) are forbidden
    - Non-standard ports are forbidden (only standard 443 permitted)
    
    Returns (normalized_url, hostname, port).
    """
    if not url or not isinstance(url, str):
        raise SSRFValidationError("URL must be a non-empty string")

    try:
        parsed = urllib.parse.urlsplit(url.strip())
    except Exception as e:
        raise SSRFValidationError("Malformed URL") from e

    # 1. Scheme check: only https allowed
    if parsed.scheme.lower() != "https":
        raise SSRFValidationError(f"Forbidden scheme '{parsed.scheme}'. Only 'https' is allowed.")

    # 2. Reject credentials in URL
    if parsed.username or parsed.password:
        raise SSRFValidationError("URL credentials (user:pass@host) are forbidden.")

    # 3. Hostname check
    hostname = parsed.hostname
    if not hostname:
        raise SSRFValidationError("Missing hostname in URL.")
    hostname = hostname.lower()

    # 4. Port check: only 443 or default permitted
    port = parsed.port or 443
    if port != 443:
        raise SSRFValidationError(f"Forbidden port '{port}'. Only port 443 is permitted.")

    # 5. Host whitelist: project SUPABASE_URL host or *.supabase.co
    supabase_env = os.getenv("SUPABASE_URL", "").strip()
    trusted_env_host = None
    if supabase_env:
        try:
            trusted_env_host = urllib.parse.urlsplit(supabase_env).hostname
            if trusted_env_host:
                trusted_env_host = trusted_env_host.lower()
        except Exception:
            pass

    is_trusted = False
    if trusted_env_host and hostname == trusted_env_host:
        is_trusted = True
    elif hostname == "supabase.co" or (hostname.endswith(".supabase.co") and not hostname.startswith(".")):
        is_trusted = True

    if not is_trusted:
        raise SSRFValidationError(f"Host '{hostname}' is not an authorized Supabase host.")

    return url.strip(), hostname, port

def resolve_and_validate_host(hostname: str, port: int = 443) -> List[str]:
    """
    Resolves hostname via DNS and verifies that all resolved IP addresses are public
    and do not point to private, loopback, or metadata addresses.
    """
    try:
        addr_info = socket.getaddrinfo(hostname, port, proto=socket.IPPROTO_TCP)
    except socket.gaierror as e:
        raise SSRFValidationError(f"DNS resolution failed for host '{hostname}'") from e

    resolved_ips = []
    for entry in addr_info:
        sockaddr = entry[4]
        ip_str = sockaddr[0]
        try:
            ip_obj = ipaddress.ip_address(ip_str)
        except ValueError:
            raise SSRFValidationError(f"Invalid IP address format: {ip_str}")

        if is_ip_forbidden(ip_obj):
            raise SSRFValidationError(f"Access to private/loopback/link-local IP '{ip_str}' is forbidden.")
        resolved_ips.append(ip_str)

    if not resolved_ips:
        raise SSRFValidationError(f"No IP addresses resolved for host '{hostname}'")

    return resolved_ips

class _NoRedirectHandler(urllib.request.HTTPRedirectHandler):
    """Custom HTTPRedirectHandler that stops automatic redirects to allow manual hop-by-hop SSRF validation."""
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None

def safe_download_image(
    url: str,
    timeout: float = 10.0,
    max_size_bytes: int = 5 * 1024 * 1024,
    max_redirects: int = 3,
) -> bytes:
    """
    Safely downloads an image from a trusted URL with SSRF protection,
    redirect validation, streaming size limits, and timeout protection.
    """
    current_url = url
    redirect_count = 0
    opener = urllib.request.build_opener(_NoRedirectHandler)

    while True:
        # Validate current URL scheme, credentials, port, and host
        _, hostname, port = validate_image_url(current_url)

        # DNS resolution and private IP rejection
        resolve_and_validate_host(hostname, port)

        req = urllib.request.Request(
            current_url,
            headers={"User-Agent": "NYKitchenPOS/1.0 ImageDownloader"},
        )

        try:
            response = opener.open(req, timeout=timeout)
        except urllib.error.HTTPError as e:
            # Check for redirect status codes when using _NoRedirectHandler
            if e.code in (301, 302, 303, 307, 308):
                if redirect_count >= max_redirects:
                    raise SSRFValidationError(f"Too many redirects: exceeded limit of {max_redirects}")

                location = e.headers.get("Location")
                if not location:
                    raise SSRFValidationError("Redirect response missing Location header")

                current_url = urllib.parse.urljoin(current_url, location)
                redirect_count += 1
                continue
            raise SSRFValidationError(f"HTTP request failed with status {e.code}") from e
        except urllib.error.URLError as e:
            raise SSRFValidationError(f"Connection failed: {e.reason}") from e

        # Handle 3xx in case opener returns a response object with 3xx
        if response.status in (301, 302, 303, 307, 308):
            if redirect_count >= max_redirects:
                raise SSRFValidationError(f"Too many redirects: exceeded limit of {max_redirects}")

            location = response.headers.get("Location")
            if not location:
                raise SSRFValidationError("Redirect response missing Location header")

            current_url = urllib.parse.urljoin(current_url, location)
            redirect_count += 1
            continue

        # Check declared Content-Length
        cl_header = response.headers.get("Content-Length")
        if cl_header:
            try:
                cl_val = int(cl_header)
                if cl_val > max_size_bytes:
                    raise SSRFValidationError(f"Response size ({cl_val} bytes) exceeds limit ({max_size_bytes} bytes)")
            except ValueError:
                pass

        # Stream response and enforce max_size_bytes
        chunks = []
        downloaded = 0
        chunk_size = 64 * 1024

        while True:
            chunk = response.read(chunk_size)
            if not chunk:
                break
            downloaded += len(chunk)
            if downloaded > max_size_bytes:
                raise SSRFValidationError(f"Download size exceeded maximum limit of {max_size_bytes} bytes")
            chunks.append(chunk)

        return b"".join(chunks)
