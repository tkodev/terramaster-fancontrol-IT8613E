# Fan control for TerraMaster NAS with IT8613E chipset (e.g. F4-424)
# https://github.com/rcarmo/terramaster-fancontrol-IT8613E

# ---- build stage ----
FROM --platform=linux/amd64 gcc:latest AS builder

WORKDIR /build
COPY fancontrol.cpp .
RUN gcc -o fancontrol fancontrol.cpp

# ---- runtime stage ----
FROM --platform=linux/amd64 debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends smartmontools lm-sensors && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /build/fancontrol .
COPY ./entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh /app/fancontrol

USER root

ENTRYPOINT ["/bin/sh", "/app/entrypoint.sh"]
# Default: env-driven args. Override with readme-format command (see docker-compose).
CMD []