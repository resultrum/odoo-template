FROM odoo:18.0

USER root

# Install git and git-aggregator
RUN apt-get update && apt-get install -y \
    git \
    && pip3 install --break-system-packages git-aggregator \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy custom entrypoint script
COPY entrypoint.sh /entrypoint-custom.sh
RUN chmod +x /entrypoint-custom.sh

ENTRYPOINT ["/entrypoint-custom.sh"]
CMD ["odoo"]
