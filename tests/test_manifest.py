# Test module manifest validity
import os
import json
import pytest
import ast
from pathlib import Path


class TestManifestFiles:
    """Test that all modules have valid manifest files."""

    def find_modules(self, path):
        """Find all Odoo modules in a directory tree."""
        modules = []
        for root, dirs, files in os.walk(path):
            if "__manifest__.py" in files or "__openerp__.py" in files:
                modules.append(root)
        return modules

    def test_manifest_exists_in_custom_modules(self, custom_addons_path):
        """Test that custom modules have __manifest__.py or __openerp__.py."""
        if not os.path.exists(custom_addons_path):
            pytest.skip(
                f"Custom addons path does not exist: {custom_addons_path}"
            )

        modules = self.find_modules(custom_addons_path)

        # Custom modules directory might be empty, but if it has subdirs, they should have manifests
        for subdir in os.listdir(custom_addons_path):
            module_path = os.path.join(custom_addons_path, subdir)
            if os.path.isdir(module_path) and not subdir.startswith("."):
                assert os.path.exists(
                    os.path.join(module_path, "__manifest__.py")
                ) or os.path.exists(
                    os.path.join(module_path, "__openerp__.py")
                ), f"Module {subdir} missing manifest file"

    def test_oca_modules_have_manifests(self, oca_addons_path):
        """Test that OCA addon symlinks point to valid modules with manifests."""
        if not os.path.exists(oca_addons_path):
            pytest.skip(f"OCA addons path does not exist: {oca_addons_path}")

        for item in os.listdir(oca_addons_path):
            item_path = os.path.join(oca_addons_path, item)

            if item.startswith("."):
                continue

            # Should be a symlink or directory
            if os.path.isdir(item_path):
                assert os.path.exists(
                    os.path.join(item_path, "__manifest__.py")
                ) or os.path.exists(
                    os.path.join(item_path, "__openerp__.py")
                ), f"OCA module {item} missing manifest file"

    def test_manifest_is_valid_python(self, addons_path):
        """Test that all manifest files are valid Python dicts."""
        modules = self.find_modules(addons_path)

        for module_path in modules:
            manifest_path = os.path.join(module_path, "__manifest__.py")
            if not os.path.exists(manifest_path):
                manifest_path = os.path.join(module_path, "__openerp__.py")

            assert os.path.exists(
                manifest_path
            ), f"No manifest in {module_path}"

            # Try to parse as Python dict
            with open(manifest_path, "r", encoding="utf-8") as f:
                try:
                    code = f.read()
                    # Parse as Python code (should be a dict assignment)
                    ast.parse(code)
                except SyntaxError as e:
                    pytest.fail(
                        f"Manifest {manifest_path} has syntax error: {e}"
                    )

    def test_manifest_contains_required_keys(self, addons_path):
        """Test that manifest files contain required metadata."""
        modules = self.find_modules(addons_path)
        required_keys = {"name", "version"}

        for module_path in modules:
            manifest_path = os.path.join(module_path, "__manifest__.py")
            if not os.path.exists(manifest_path):
                manifest_path = os.path.join(module_path, "__openerp__.py")

            with open(manifest_path, "r", encoding="utf-8") as f:
                # Simple check: look for required keys as strings in the file
                content = f.read()
                module_name = os.path.basename(module_path)

                assert (
                    "'name'" in content or '"name"' in content
                ), f"Module {module_name} missing 'name' in manifest"
                assert (
                    "'version'" in content or '"version"' in content
                ), f"Module {module_name} missing 'version' in manifest"
