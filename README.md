# rustfs-cli (Docker)

A minimal Docker setup to run the rustfs S3-compatible server alongside the rustfs-cli tool. This lets you quickly spin up a local object storage and manage buckets with a familiar, mc-style CLI.

## Overview
- Runs a RustFS server exposing S3-compatible APIs on ports 9000/9001.
- Builds a lightweight container that installs the rustfs-cli binary and wires a convenient entrypoint.
- Preconfigures an alias named `local` pointing to the RustFS server.
- Supports batch bucket creation using `mb <bucket...>` via the entrypoint.

Key files:
- [docker-compose.yml](file:///Users/administrator/Documents/Labs/rustfs-cli/docker-compose.yml)
- [Dockerfile](file:///Users/administrator/Documents/Labs/rustfs-cli/Dockerfile)

## Prerequisites
- Docker 24+
- Docker Compose (v2)

## Quick Start
```bash
# Start RustFS and the CLI container (creates default buckets)
docker compose up -d

# See container logs
docker compose logs rustfs
docker compose logs rustfs-cli
```

By default, the CLI service starts with a command that creates a set of buckets commonly used by GitLab:
```
mb gitlab-artifacts gitlab-uploads gitlab-packages gitlab-lfs gitlab-backups \
   gitlab-terraform gitlab-dependency-proxy gitlab-secure-files gitlab-pages \
   gitlab-external-diffs gitlab-registry
```
You can edit that list in [docker-compose.yml](file:///Users/administrator/Documents/Labs/rustfs-cli/docker-compose.yml#L1-L44) under the `rustfs-cli` service `command:` section.

## CLI Usage
The image provides the binary as `rc` (symlinked to `rustfs-cli` if needed). An alias named `local` is automatically created and points to the RustFS server.

Common operations:
```bash
# Show top-level help
docker compose run --rm rustfs-cli --help

# List buckets under the 'local' alias
docker compose run --rm rustfs-cli ls local

# Create a single bucket
docker compose run --rm rustfs-cli mb local/my-bucket

# Create multiple buckets in one shot via entrypoint short-hand:
# (the entrypoint expands 'mb' followed by names into alias-correct calls)
docker compose run --rm rustfs-cli mb my-bucket another-bucket
```

If you need to interact with local files, mount your working directory:
```bash
docker compose run --rm -v "$PWD:/work" rustfs-cli --help
```

## Configuration
Environment variables (can be set in compose or at runtime):
- `RUSTFS_ENDPOINT`: RustFS server URL (default `http://rustfs:9000`)
- `RUSTFS_ACCESS_KEY`: Access key (default `rustfsadmin`)
- `RUSTFS_SECRET_KEY`: Secret key (default `rustfsadmin`)
- `RUSTFS_ALIAS_NAME`: Alias name created for the CLI (default `local`)
- `RUSTFS_CLI_BINARY`: CLI binary name (default `rc`)

See how these are consumed in the entrypoint in [Dockerfile](file:///Users/administrator/Documents/Labs/rustfs-cli/Dockerfile#L12-L35).

Ports and data:
- RustFS server ports: `9000` (API) and `9001` (console)
- Data volume: `./rustfs-data:/data` (persisted locally)

## Upstream CLI
The CLI used here is maintained at:
- https://github.com/rustfs/cli

Highlights:
- S3-compatible client supporting RustFS, MinIO, AWS S3, and others
- Human-readable and JSON outputs, secure credential handling, cross-platform

Standalone installation options:
```bash
# Homebrew (macOS/Linux)
brew install rustfs/tap/rc

# Cargo
cargo install rustfs-cli
```

## Batch Bucket Creation via Entrypoint
The entrypoint supports a convenient batch mode:
- If the first argument is `mb` and more names follow, it will create each bucket under the configured alias.
- Otherwise, it will exec the CLI with provided arguments.

Reference: [Dockerfile](file:///Users/administrator/Documents/Labs/rustfs-cli/Dockerfile#L12-L35)

## Changing the CLI Crate
The image builds the CLI using Cargo:
- Build arg `RUSTFS_CLI_CRATE` controls which crate is installed (defaults to `rustfs-cli`).
- You can override it at build time:
```bash
docker build --build-arg RUSTFS_CLI_CRATE=rustfs-cli -t local/rustfs-cli .
```

## Security Notes
- Default credentials are for local development only; change `RUSTFS_ACCESS_KEY` and `RUSTFS_SECRET_KEY` for any non-local use.
- Exposed ports are mapped to the host; avoid public exposure without proper hardening.

## Troubleshooting
- Verify the alias exists:
```bash
docker compose run --rm rustfs-cli alias list
```
- Check server health: open `http://localhost:9001` if console is enabled.
- Inspect logs with `docker compose logs`.

## License
MIT (or as per the upstream rustfs-cli license).
