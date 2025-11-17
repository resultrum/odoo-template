# -*- coding: utf-8 -*-
# Copyright 2025 Metrum SA
# License LGPL-3.0 or later (http://www.gnu.org/licenses/lgpl)

from odoo.tests.common import TransactionCase


class TestMtaBaseModule(TransactionCase):
    """Test mta_base module installation and basic functionality."""

    @classmethod
    def setUpClass(cls):
        """Set up test fixtures."""
        super().setUpClass()

    def test_module_installed(self):
        """Test that mta_base module is installed."""
        module = self.env["ir.module.module"].search(
            [
                ("name", "=", "mta_base"),
                ("state", "=", "installed"),
            ]
        )
        self.assertTrue(module, "mta_base module should be installed")

    def test_dependencies_installed(self):
        """Test that mta_base dependencies are installed."""
        dependencies = ["helpdesk_mgmt", "project", "base"]
        for dep in dependencies:
            module = self.env["ir.module.module"].search(
                [
                    ("name", "=", dep),
                    ("state", "=", "installed"),
                ]
            )
            self.assertTrue(module, f"{dep} dependency should be installed")

    def test_module_metadata(self):
        """Test module metadata is correct."""
        module = self.env["ir.module.module"].search(
            [
                ("name", "=", "mta_base"),
            ]
        )
        self.assertEqual(
            module.author, "Metrum SA", "Module author should be Metrum SA"
        )
