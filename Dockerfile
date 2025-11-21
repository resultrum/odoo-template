# Dockerfile for Development - Community Edition
# Base Image: Odoo Community Edition (public, no auth needed)
#
# For Enterprise Edition development:
#   docker-compose -f docker-compose.yml -f docker-compose.enterprise.yml up -d
#
# Enterprise image is built weekly by GitHub Actions and pushed to:
#   ghcr.io/resultrum/odoo:18.0-enterprise-latest

FROM odoo:18.0

USER root

# Install git and git-aggregator
RUN apt-get update && apt-get install -y \
    git \
    && pip3 install --break-system-packages git-aggregator \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/python3 /usr/bin/python

# Create symlinks for project addons (custom and oca-addons are mounted at runtime)
RUN ln -sf /mnt/extra-addons/custom /usr/lib/python3/dist-packages/odoo/addons/custom && \
    ln -sf /mnt/extra-addons/oca-addons /usr/lib/python3/dist-packages/odoo/addons/oca-addons

# Copy custom entrypoint script
COPY entrypoint.sh /entrypoint-custom.sh
RUN chmod +x /entrypoint-custom.sh

ENTRYPOINT ["/entrypoint-custom.sh"]
CMD ["odoo"]
