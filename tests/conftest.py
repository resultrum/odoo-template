# Pytest configuration and fixtures
import os
import sys
import pytest

# Add project root to path
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, PROJECT_ROOT)


@pytest.fixture(scope="session")
def project_root():
    """Return project root directory."""
    return PROJECT_ROOT


@pytest.fixture(scope="session")
def addons_path():
    """Return path to addons directory."""
    return os.path.join(PROJECT_ROOT, "addons")


@pytest.fixture(scope="session")
def custom_addons_path():
    """Return path to custom addons directory."""
    return os.path.join(PROJECT_ROOT, "addons", "custom")


@pytest.fixture(scope="session")
def oca_addons_path():
    """Return path to OCA addons symlinks directory."""
    return os.path.join(PROJECT_ROOT, "addons", "oca-addons")


@pytest.fixture(scope="session")
def oca_repos_path():
    """Return path to OCA repositories directory."""
    return os.path.join(PROJECT_ROOT, "addons", "oca")
