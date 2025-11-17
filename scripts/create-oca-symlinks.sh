#!/bin/bash
# Helper script to create OCA addons symlinks locally
# Usage: ./scripts/create-oca-symlinks.sh

set -e

ADDONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/addons"
OCA_ADDONS_PATH="$ADDONS_DIR/oca-addons"

echo "🔗 Creating OCA addons symlinks..."
echo "   Source: $ADDONS_DIR/oca"
echo "   Target: $OCA_ADDONS_PATH"
echo ""

# Ensure oca-addons directory exists
mkdir -p "$OCA_ADDONS_PATH"

# Remove old symlinks
find "$OCA_ADDONS_PATH" -maxdepth 1 -type l -delete

# Create symlinks for all OCA modules
if [ -d "$ADDONS_DIR/oca" ]; then
    module_count=0

    # For each subdirectory in oca (e.g., helpdesk/)
    for module_dir in "$ADDONS_DIR/oca"/*/; do
        if [ -d "$module_dir" ]; then
            # For each module in the subdirectory
            for module in "$module_dir"*/; do
                if [ -f "$module/__manifest__.py" ] || [ -f "$module/__openerp__.py" ]; then
                    module_name=$(basename "$module")
                    symlink_path="$OCA_ADDONS_PATH/$module_name"

                    # Create relative symlink
                    rel_path=$(python3 -c "import os.path; print(os.path.relpath('$module', '$OCA_ADDONS_PATH'))" 2>/dev/null || echo "../oca/$(basename "$module_dir")/$module_name")
                    ln -sf "$rel_path" "$symlink_path"

                    echo "  ✓ $module_name -> $rel_path"
                    ((module_count++))
                fi
            done
        fi
    done

    echo ""
    echo "✅ Successfully created $module_count symlinks in $OCA_ADDONS_PATH"
else
    echo "❌ ERROR: $ADDONS_DIR/oca directory not found"
    exit 1
fi
