"""Discover the same configure tests shipped in the source-only container kit."""
import importlib.util
from pathlib import Path

test_path = Path(__file__).resolve().parents[3] / 'container/ubuntu2604/scripts/test-configure.py'
spec = importlib.util.spec_from_file_location('configure_regression_tests', test_path)
tests = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tests)


def load_tests(loader, suite, pattern):
    return loader.loadTestsFromModule(tests)
