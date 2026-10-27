#!/usr/bin/env bash
# EC2 bootstrap commands appended to the reusable EC2 module's Bash user data.
# Keep this file as shell code: the module invokes setup_script after its own
# SSM, EBS, and CloudWatch setup rather than passing it to cloud-init as YAML.
set -euo pipefail

log() {
  printf '[%s] [ec2-common-bootstrap] %s\n' "$(date --iso-8601=seconds)" "$*"
}

log "Installing required Amazon Linux packages"
dnf install -y awscli docker git zip unzip telnet python3-pip

# AL2023 normally provides the curl command through curl-minimal. Requesting
# the full curl package in the transaction conflicts with that installed
# provider, so only install curl-minimal when no curl implementation exists.
if ! command -v curl >/dev/null 2>&1; then
  dnf install -y curl-minimal
fi

log "Enabling and starting Docker"
systemctl enable --now docker

# AL2023 provides Docker in its core repositories, but the enabled repository
# for this AMI does not provide docker-compose-plugin. Install the official
# Compose CLI plugin only when it is not already available.
if ! docker compose version >/dev/null 2>&1; then
  compose_version="v5.6.0"
  case "$(uname -m)" in
    x86_64) compose_arch="x86_64" ;;
    aarch64) compose_arch="aarch64" ;;
    *) log "Unsupported CPU architecture for Docker Compose: $(uname -m)" >&2; exit 1 ;;
  esac

  compose_plugin_dir="/usr/local/lib/docker/cli-plugins"
  install -d -m 0755 "$compose_plugin_dir"
  curl --fail --location --retry 3 \
    "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-linux-${compose_arch}" \
    --output "$compose_plugin_dir/docker-compose"
  chmod 0755 "$compose_plugin_dir/docker-compose"
fi

# Install Buildx as a system-wide Docker CLI plugin when it is not already
# available. The pinned version keeps bootstrap behavior reproducible.
if ! docker buildx version >/dev/null 2>&1; then
  buildx_version="v0.17.1"
  case "$(uname -m)" in
    x86_64) buildx_arch="amd64" ;;
    aarch64) buildx_arch="arm64" ;;
    *) log "Unsupported CPU architecture for Docker Buildx: $(uname -m)" >&2; exit 1 ;;
  esac

  buildx_plugin_dir="/usr/local/lib/docker/cli-plugins"
  install -d -m 0755 "$buildx_plugin_dir"
  curl --fail --location --retry 3 \
    "https://github.com/docker/buildx/releases/download/${buildx_version}/buildx-${buildx_version}.linux-${buildx_arch}" \
    --output "$buildx_plugin_dir/docker-buildx"
  chmod 0755 "$buildx_plugin_dir/docker-buildx"
fi

log "Package versions"
aws --version
docker --version
docker compose version
docker buildx version
git --version
curl --version | head -n 1
zip --version | head -n 1
unzip -v | head -n 1

log "EC2 bootstrap installation complete"
