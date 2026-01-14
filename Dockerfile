FROM rust:bookworm AS builder
ARG RUSTFS_CLI_CRATE=rustfs-cli
RUN cargo install --locked ${RUSTFS_CLI_CRATE}

FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates openssl && rm -rf /var/lib/apt/lists/*
ENV PATH=/usr/local/bin:$PATH
COPY --from=builder /usr/local/cargo/bin/ /usr/local/bin/
# Ensure rc exists even if the crate's binary is named rustfs-cli
RUN if [ ! -x /usr/local/bin/rc ] && [ -x /usr/local/bin/rustfs-cli ]; then ln -s /usr/local/bin/rustfs-cli /usr/local/bin/rc; fi
ENV RUSTFS_CLI_BINARY=rc
ENV RUSTFS_ALIAS_NAME=local
COPY <<'EOF' /entrypoint.sh
#!/bin/sh
set -e
BIN="${RUSTFS_CLI_BINARY:-rustfs-cli}"
ALIAS_NAME="${RUSTFS_ALIAS_NAME:-local}"
ENDPOINT="${RUSTFS_ENDPOINT:-http://rustfs:9000}"
ACCESS="${RUSTFS_ACCESS_KEY:-rustfsadmin}"
SECRET="${RUSTFS_SECRET_KEY:-rustfsadmin}"
# Ensure alias exists (compatible with mc-style CLIs)
"$BIN" alias set "$ALIAS_NAME" "$ENDPOINT" "$ACCESS" "$SECRET" || true
if [ "$1" = "mb" ] && [ "$#" -gt 1 ]; then
  shift
  for b in "$@"; do
    "$BIN" mb "$ALIAS_NAME/$b"
  done
  exit 0
fi
exec "$BIN" "$@"
EOF
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["--help"]
