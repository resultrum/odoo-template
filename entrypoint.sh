#!/bin/bash
set -e

# Setup SSH for git operations (DEV mode only)
if [ "$ENABLE_GIT_AGGREGATE" = "true" ] && [ -d /root/.ssh ]; then
    echo "🔑 Setting up SSH for git operations..."
    mkdir -p /home/odoo/.ssh
    cp -r /root/.ssh/* /home/odoo/.ssh/ 2>/dev/null || true
    chown -R odoo:odoo /home/odoo/.ssh
    chmod 700 /home/odoo/.ssh
    chmod 600 /home/odoo/.ssh/id_* 2>/dev/null || true
fi

# Git-aggregate logic
if [ "$ENABLE_GIT_AGGREGATE" = "true" ] && [ -f /mnt/repos.yml ]; then
    echo "🔧 DEV MODE: Running git-aggregator..."
    mkdir -p /mnt/extra-addons/oca
    cd /mnt

    # Run as odoo user - ignore permission errors from chown
    set +e
    runuser -u odoo -- bash -c "cd /mnt && gitaggregate -c repos.yml" 2>&1 | grep -v "chown.*Permission denied"
    GITAGGREGATE_STATUS=$?
    set -e

    if [ $GITAGGREGATE_STATUS -eq 0 ] || [ $GITAGGREGATE_STATUS -eq 141 ]; then
        echo "✅ git-aggregator completed"
    else
        echo "⚠️  git-aggregator had some issues (status: $GITAGGREGATE_STATUS), continuing..."
    fi
else
    echo "✅ PROD MODE: Using OCA modules from repo"
fi

# Create symlinks for OCA modules
echo "🔗 Setting up OCA addons symlinks..."
mkdir -p /mnt/extra-addons/oca-addons

# Remove old symlinks if they exist
find /mnt/extra-addons/oca-addons -maxdepth 1 -type l -delete

# Create symlinks for all OCA modules (from all subdirectories)
if [ -d /mnt/extra-addons/oca ]; then
    for module_dir in /mnt/extra-addons/oca/*/; do
        if [ -d "$module_dir" ]; then
            # For each subdirectory in oca (e.g., helpdesk/)
            for module in "$module_dir"*/; do
                if [ -f "$module/__manifest__.py" ] || [ -f "$module/__openerp__.py" ]; then
                    module_name=$(basename "$module")
                    symlink_path="/mnt/extra-addons/oca-addons/$module_name"

                    # Create symlink (relative path for portability)
                    ln -sf "$(python3 -c "import os.path; print(os.path.relpath('$module', '/mnt/extra-addons/oca-addons'))")" "$symlink_path" 2>/dev/null || \
                    ln -sf "../oca/$(basename "$module_dir")/$module_name" "$symlink_path"

                    echo "  ✓ $module_name"
                fi
            done
        fi
    done
    echo "✅ OCA addons symlinks created successfully"
else
    echo "⚠️  /mnt/extra-addons/oca directory not found"
fi

# Start Odoo normally (already runs as odoo user via original entrypoint)
exec /entrypoint.sh "$@"
