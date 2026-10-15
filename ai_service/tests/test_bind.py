import ast
import unittest
from pathlib import Path

class TestFastApiBinding(unittest.TestCase):
    def test_uvicorn_bind_address_is_localhost_only(self):
        """Verifies Gap 15: FastAPI must not bind to 0.0.0.0; must bind to 127.0.0.1."""
        main_path = Path(__file__).resolve().parent.parent / "main.py"
        self.assertTrue(main_path.exists(), f"File not found: {main_path}")

        source = main_path.read_text(encoding="utf-8")
        tree = ast.parse(source)

        bind_hosts = []
        for node in ast.walk(tree):
            if isinstance(node, ast.Call):
                for kw in node.keywords:
                    if kw.arg == "host" and isinstance(kw.value, ast.Constant):
                        bind_hosts.append(kw.value.value)

        self.assertNotIn(
            "0.0.0.0",
            bind_hosts,
            "Security vulnerability (Gap 15): FastAPI uvicorn.run binds to 0.0.0.0 (exposed to network)"
        )
        self.assertIn(
            "127.0.0.1",
            bind_hosts,
            "FastAPI uvicorn.run must bind to 127.0.0.1 (localhost only)"
        )

if __name__ == "__main__":
    unittest.main()
