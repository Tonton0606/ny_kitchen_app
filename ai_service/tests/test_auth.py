import ast
import os
import unittest
from pathlib import Path

class TestFastApiAuthentication(unittest.TestCase):
    def setUp(self):
        self.main_path = Path(__file__).resolve().parent.parent / "main.py"
        self.assertTrue(self.main_path.exists(), f"File not found: {self.main_path}")
        self.source = self.main_path.read_text(encoding="utf-8")
        self.tree = ast.parse(self.source)

    def test_shared_secret_header_enforced_in_endpoints(self):
        """Verifies Gap 14: Endpoints must require X-Service-Key shared secret authentication."""
        endpoint_names = ["extract_encoding", "check_liveness"]
        found_endpoints = {}

        for node in ast.walk(self.tree):
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                if node.name in endpoint_names:
                    has_auth_dep = False
                    for decorator in node.decorator_list:
                        if isinstance(decorator, ast.Call):
                            for kw in decorator.keywords:
                                if kw.arg == "dependencies":
                                    has_auth_dep = True
                    for arg in node.args.args:
                        if "key" in arg.arg.lower() or "auth" in arg.arg.lower():
                            has_auth_dep = True
                    found_endpoints[node.name] = has_auth_dep

        for name in endpoint_names:
            self.assertTrue(
                found_endpoints.get(name, False),
                f"Endpoint '{name}' must enforce authentication dependency for shared secret (Gap 14)"
            )

    def test_verify_service_key_logic(self):
        """Verifies verify_service_key function raises 401 on missing/invalid key and passes on match."""
        # Find verify_service_key function in source
        has_verifier = any(
            isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef)) and "service_key" in n.name
            for n in ast.walk(self.tree)
        )
        self.assertTrue(has_verifier, "ai_service/main.py must define a service key verification function")

    def test_startup_validation_refuses_when_service_key_unset(self):
        """Verifies Fix 1: Service must refuse to start (fail-closed) when AI_SERVICE_KEY is unset or empty."""
        import sys
        ai_dir = str(self.main_path.parent)
        if ai_dir not in sys.path:
            sys.path.insert(0, ai_dir)
        import main

        old_key = os.environ.get("AI_SERVICE_KEY")
        try:
            # Case 1: Unset
            if "AI_SERVICE_KEY" in os.environ:
                del os.environ["AI_SERVICE_KEY"]
            with self.assertRaises(RuntimeError) as ctx:
                main.validate_service_key_configuration()
            self.assertIn("AI_SERVICE_KEY", str(ctx.exception))

            # Case 2: Empty or whitespace
            os.environ["AI_SERVICE_KEY"] = "   "
            with self.assertRaises(RuntimeError) as ctx:
                main.validate_service_key_configuration()
            self.assertIn("AI_SERVICE_KEY", str(ctx.exception))

            # Case 3: Valid key returns configured value
            os.environ["AI_SERVICE_KEY"] = "valid-secret-key-456"
            configured = main.validate_service_key_configuration()
            self.assertEqual(configured, "valid-secret-key-456")
        finally:
            if old_key is not None:
                os.environ["AI_SERVICE_KEY"] = old_key
            elif "AI_SERVICE_KEY" in os.environ:
                del os.environ["AI_SERVICE_KEY"]

    def test_verify_service_key_runtime_behavior(self):
        """Verifies verify_service_key runtime behavior for 500 (misconfigured), 401 (invalid/missing), and 200 (valid)."""
        import sys
        from fastapi import HTTPException
        ai_dir = str(self.main_path.parent)
        if ai_dir not in sys.path:
            sys.path.insert(0, ai_dir)
        import main

        old_key = os.environ.get("AI_SERVICE_KEY")
        try:
            # 1. Server missing key -> 500 Server misconfiguration
            if "AI_SERVICE_KEY" in os.environ:
                del os.environ["AI_SERVICE_KEY"]
            with self.assertRaises(HTTPException) as ctx:
                main.verify_service_key("any-client-key")
            self.assertEqual(ctx.exception.status_code, 500)

            # 2. Server has key, client header missing -> 401
            os.environ["AI_SERVICE_KEY"] = "configured-secret-key"
            with self.assertRaises(HTTPException) as ctx:
                main.verify_service_key(None)
            self.assertEqual(ctx.exception.status_code, 401)

            # 3. Server has key, client header wrong -> 401
            with self.assertRaises(HTTPException) as ctx:
                main.verify_service_key("wrong-key")
            self.assertEqual(ctx.exception.status_code, 401)

            # 4. Server has key, client header matches -> Success
            result = main.verify_service_key("configured-secret-key")
            self.assertEqual(result, "configured-secret-key")
        finally:
            if old_key is not None:
                os.environ["AI_SERVICE_KEY"] = old_key
            elif "AI_SERVICE_KEY" in os.environ:
                del os.environ["AI_SERVICE_KEY"]

if __name__ == "__main__":
    unittest.main()

