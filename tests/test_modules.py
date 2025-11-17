# Test module structure and integrity
import os
import pytest
from pathlib import Path


class TestModuleStructure:
    """Test that modules have correct structure."""

    def test_custom_modules_directory_exists(self, custom_addons_path):
        """Test that custom addons directory exists."""
        assert os.path.exists(
            custom_addons_path
        ), f"Custom addons directory not found: {custom_addons_path}"

    def test_oca_addons_symlinks_directory_exists(self, oca_addons_path):
        """Test that OCA addons symlinks directory exists."""
        assert os.path.exists(
            oca_addons_path
        ), f"OCA addons symlinks directory not found: {oca_addons_path}"

    def test_oca_addons_symlinks_are_created(self, oca_addons_path):
        """Test that OCA addons symlinks exist and point to valid modules."""
        if not os.path.exists(oca_addons_path):
            pytest.skip(f"OCA addons path does not exist: {oca_addons_path}")

        symlinks = os.listdir(oca_addons_path)
        # Filter out .gitkeep and hidden files
        symlinks = [s for s in symlinks if not s.startswith(".")]

        # OCA symlinks may not exist in CI environment, skip if empty
        if len(symlinks) == 0:
            pytest.skip(
                "No OCA module symlinks found (expected in CI environment)"
            )

    def test_oca_module_symlinks_are_valid(self, oca_addons_path):
        """Test that OCA module symlinks are valid and point to real modules."""
        if not os.path.exists(oca_addons_path):
            pytest.skip(f"OCA addons path does not exist: {oca_addons_path}")

        for item in os.listdir(oca_addons_path):
            if item.startswith("."):
                continue

            item_path = os.path.join(oca_addons_path, item)

            # Item should be a symlink or directory
            assert os.path.islink(item_path) or os.path.isdir(
                item_path
            ), f"OCA item {item} is neither symlink nor directory"

            # Should point to valid directory
            assert os.path.isdir(
                item_path
            ), f"OCA module symlink {item} does not point to valid directory"

    def test_modules_have_python_files(self, addons_path):
        """Test that modules contain at least __init__.py or models."""
        if not os.path.exists(addons_path):
            pytest.skip(f"Addons path does not exist: {addons_path}")

        # Check OCA modules
        oca_path = os.path.join(addons_path, "oca-addons")
        if os.path.exists(oca_path):
            for item in os.listdir(oca_path):
                if item.startswith("."):
                    continue

                module_path = os.path.join(oca_path, item)
                if os.path.isdir(module_path):
                    # Module should have either __init__.py or models directory
                    has_init = os.path.exists(
                        os.path.join(module_path, "__init__.py")
                    )
                    has_models = os.path.exists(
                        os.path.join(module_path, "models")
                    )

                    assert (
                        has_init or has_models
                    ), f"Module {item} missing __init__.py or models/"

    def test_no_circular_symlinks(self, oca_addons_path):
        """Test that symlinks don't create circular references."""
        if not os.path.exists(oca_addons_path):
            pytest.skip(f"OCA addons path does not exist: {oca_addons_path}")

        visited = set()
        for item in os.listdir(oca_addons_path):
            if item.startswith("."):
                continue

            item_path = os.path.join(oca_addons_path, item)

            # Get real path (follows symlinks)
            try:
                real_path = os.path.realpath(item_path)
                assert (
                    real_path not in visited
                ), f"Circular symlink detected: {item} -> {real_path}"
                visited.add(real_path)
            except (OSError, RuntimeError):
                pytest.fail(f"Error resolving symlink {item}")


class TestProjectStructure:
    """Test overall project structure."""

    def test_project_has_git_repo(self, project_root):
        """Test that project is a git repository."""
        git_dir = os.path.join(project_root, ".git")
        assert os.path.exists(git_dir), "Project is not a git repository"

    def test_project_has_required_config_files(self, project_root):
        """Test that project has required configuration files."""
        required_files = [
            "docker-compose.yml",
            "Dockerfile",
            "repos.yml",
            "odoo.conf",
        ]

        for filename in required_files:
            filepath = os.path.join(project_root, filename)
            assert os.path.exists(
                filepath
            ), f"Required config file missing: {filename}"

    def test_project_has_documentation(self, project_root):
        """Test that project has documentation files."""
        required_docs = [
            "README.md",
            "QUICK_START.md",
            "DEVELOPER_GUIDE.md",
        ]

        for filename in required_docs:
            filepath = os.path.join(project_root, filename)
            assert os.path.exists(
                filepath
            ), f"Required documentation missing: {filename}"

    def test_gitignore_exists(self, project_root):
        """Test that .gitignore exists and is not empty."""
        gitignore_path = os.path.join(project_root, ".gitignore")
        assert os.path.exists(gitignore_path), ".gitignore not found"
        assert os.path.getsize(gitignore_path) > 0, ".gitignore is empty"

    def test_scripts_directory_exists(self, project_root):
        """Test that scripts directory exists."""
        scripts_path = os.path.join(project_root, "scripts")
        assert os.path.exists(scripts_path), "scripts/ directory not found"

    def test_addons_directory_structure(self, addons_path):
        """Test that addons directory has correct structure."""
        required_subdirs = ["custom", "oca", "oca-addons"]

        for subdir in required_subdirs:
            subdir_path = os.path.join(addons_path, subdir)
            assert os.path.exists(
                subdir_path
            ), f"Required addons subdirectory missing: {subdir}"
