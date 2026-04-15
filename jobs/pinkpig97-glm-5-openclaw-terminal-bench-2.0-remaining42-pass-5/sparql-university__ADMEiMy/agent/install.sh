#!/bin/bash
set -euo pipefail

missing_packages=""
command -v curl >/dev/null 2>&1 || missing_packages="${missing_packages} curl"
command -v git >/dev/null 2>&1 || missing_packages="${missing_packages} git"
command -v xz >/dev/null 2>&1 || missing_packages="${missing_packages} xz-utils"
if [ ! -e /etc/ssl/certs/ca-certificates.crt ]; then
    missing_packages="${missing_packages} ca-certificates"
fi

if [ -n "${missing_packages# }" ]; then
    apt-get update
    apt-get install -y ${missing_packages}
fi

node_is_compatible() {
    command -v node >/dev/null 2>&1 && node --version | grep -qE '^v22\.(1[4-9]|[2-9][0-9])\.|^v2[3-9]\.'
}

retry_cmd() {
    local max_attempts="$1"
    shift
    local attempt=1
    local status=0
    while [ "$attempt" -le "$max_attempts" ]; do
        if "$@"; then
            return 0
        fi
        status=$?
        echo "Attempt ${attempt}/${max_attempts} failed with exit code ${status}: $*"
        if [ "$attempt" -eq "$max_attempts" ]; then
            return "$status"
        fi
        sleep $((attempt * 5))
        attempt=$((attempt + 1))
    done
    return "$status"
}

curl_download() {
    local url="$1"
    local output_path="$2"
    rm -f "$output_path"
    curl --http1.1 -fL --retry 10 --retry-all-errors --retry-delay 3 \
        --connect-timeout 30 --max-time 900 "$url" -o "$output_path"
}

run_npm_install() {
    local package_spec="$1"
    # /root/.npm is shared across task containers to reuse cached packages.
    # Do not clear _cacache/tmp here: concurrent installs use randomized temp dirs
    # in that path, and deleting them races peer containers into ENOENT.
    timeout "${TB2_OPENCLAW_NPM_TIMEOUT_SEC:-900}" \
        npm install -g --prefer-offline --ignore-scripts --no-audit "$package_spec"
}

# Reuse a preinstalled OpenClaw when available (e.g., custom pre-baked task images).
if node_is_compatible && command -v openclaw >/dev/null 2>&1; then
    echo "OpenClaw already installed, skipping package installation"
else
# OpenClaw currently requires Node 22.14+.
# Install the latest Node 22 Linux x64 tarball directly from nodejs.org instead of
# using nvm, because GitHub access is unreliable in some sandboxed environments.
if ! node_is_compatible; then
    TMP_DIR="$(mktemp -d)"
    NODE_TARBALL="${TB2_OPENCLAW_NODE_TARBALL_NAME:-}"
    NODE_SHA256="${TB2_OPENCLAW_NODE_TARBALL_SHA256:-}"

    if [ -n "$NODE_TARBALL" ] && [ -n "$NODE_SHA256" ] && [ -f "/installed-agent/${NODE_TARBALL}" ]; then
        echo "Using preloaded Node.js tarball from /installed-agent/${NODE_TARBALL}"
        cp "/installed-agent/${NODE_TARBALL}" "${TMP_DIR}/${NODE_TARBALL}"
    else
        NODE_SHASUMS="$(mktemp)"
        retry_cmd "${TB2_OPENCLAW_CURL_RETRIES:-4}" \
            curl_download https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt "$NODE_SHASUMS"
        NODE_TARBALL="$(awk '/linux-x64\.tar\.xz$/ {print $2; exit}' "$NODE_SHASUMS")"
        NODE_SHA256="$(awk '/linux-x64\.tar\.xz$/ {print $1; exit}' "$NODE_SHASUMS")"
        rm -f "$NODE_SHASUMS"
        test -n "$NODE_TARBALL"
        test -n "$NODE_SHA256"
        retry_cmd "${TB2_OPENCLAW_CURL_RETRIES:-4}" \
            curl_download "https://nodejs.org/dist/latest-v22.x/${NODE_TARBALL}" "${TMP_DIR}/${NODE_TARBALL}"
    fi

    echo "${NODE_SHA256}  ${TMP_DIR}/${NODE_TARBALL}" | sha256sum -c -
    tar -xJf "${TMP_DIR}/${NODE_TARBALL}" -C "$TMP_DIR"
    cp -a "${TMP_DIR}/${NODE_TARBALL%.tar.xz}/." /usr/local/
    rm -rf "$TMP_DIR"
fi

# Verify Node.js installation
node --version
npm --version

export npm_config_update_notifier=false
export npm_config_audit=false
export npm_config_fund=false
export npm_config_fetch_retries="${TB2_OPENCLAW_NPM_FETCH_RETRIES:-5}"
export npm_config_fetch_retry_mintimeout="${TB2_OPENCLAW_NPM_FETCH_RETRY_MIN_TIMEOUT_MS:-10000}"
export npm_config_fetch_retry_maxtimeout="${TB2_OPENCLAW_NPM_FETCH_RETRY_MAX_TIMEOUT_MS:-120000}"
export npm_config_fetch_timeout="${TB2_OPENCLAW_NPM_FETCH_TIMEOUT_MS:-600000}"
export npm_config_prefer_offline=true

OPENCLAW_PACKAGE_SPEC=""
if [ -f /installed-agent/openclaw.tgz ]; then
    OPENCLAW_PACKAGE_SPEC="/installed-agent/openclaw.tgz"
    echo "Using preloaded OpenClaw tarball from ${OPENCLAW_PACKAGE_SPEC}"
fi

# Install OpenClaw globally
# --ignore-scripts: skip native compilation (node-llama-cpp) — we use API providers, not local LLMs
# --no-audit: skip vulnerability check (ephemeral sandbox, not needed)

OPENCLAW_PACKAGE_SPEC="${OPENCLAW_PACKAGE_SPEC:-openclaw@latest}"

retry_cmd "${TB2_OPENCLAW_NPM_RETRIES:-3}" run_npm_install "${OPENCLAW_PACKAGE_SPEC}"
fi

# Verify OpenClaw installation
openclaw --version

# Create OpenClaw config directory structure
mkdir -p ~/.openclaw/agents/main/agent

# Prefer the task image's working directory when it is set to something usable
# (e.g. /app in Terminal-Bench). Fall back to /workspace otherwise.
WORKSPACE_DIR="${TB2_OPENCLAW_WORKSPACE_DIR:-$PWD}"
if [ -z "$WORKSPACE_DIR" ] || [ "$WORKSPACE_DIR" = "/" ]; then
    WORKSPACE_DIR="/workspace"
fi

# Create workspace directory for agent files
mkdir -p "$WORKSPACE_DIR"

########################################################################################
# openclaw.json
########################################################################################

cat > ~/.openclaw/openclaw.json << EOF
{
  "agents": {
    "defaults": {
      "model": {
        "primary": ""
      },
      "skipBootstrap": true,
      "timeoutSeconds": 86400,
      "workspace": "${WORKSPACE_DIR}"
    }
  },
  "models": {
    "mode": "merge",
    "providers": {}
  }
}
EOF

########################################################################################
# Workspace template files
########################################################################################

echo 'IyBhbmFseXNpcy1oZWF2eSBQZXJzaXN0ZW50IFdvcmtlciBDb250cmFjdAoKWW91IGFyZSBhIGxvbmctbGl2ZWQgVEIyIHdvcmtlciBmb3IgYGFuYWx5c2lzLWhlYXZ5YC4KCiMjIExhbmUgT3duZXJzaGlwCgotIG9ubHkgd29yayBvbiB0YXNrcyBsaXN0ZWQgaW4gYHRhc2tzLnR4dGAKLSBvbmx5IHdvcmsgb24gdGhlIHRhc2sgY3VycmVudGx5IGFzc2lnbmVkIGJ5IGBzdGF0dXMvYXNzaWdubWVudC5qc29uYAotIGRvIG5vdCB0YWtlIHdvcmsgZnJvbSBhbm90aGVyIGxhbmUKLSBvbmUgdGFzayBhdCBhIHRpbWUKCiMjIFJvbGUKCllvdSBhcmUgYSBwZXJzaXN0ZW50IHdvcmtlciBmb3IgYWxnb3JpdGhtaWMsIHJlYXNvbmluZy1oZWF2eSwgbWF0aCwgb3B0aW1pemF0aW9uLCBhbmQgZXhhY3Qtb3V0cHV0IHRhc2tzLgpZb3VyIGpvYiBpcyB0byBwdXNoIGEgc2luZ2xlIGFzc2lnbmVkIHRhc2sgdG8gYSB0ZXJtaW5hbCBzdGF0ZSwgcmVwb3J0IGl0IHN0cnVjdHVyYWxseSwgdGhlbiB3YWl0CmZvciB0aGUgbmV4dCBhc3NpZ25tZW50LgoKIyMgV29ya2luZyBTdHlsZQoKLSBzdGFydCBmcm9tIHRoZSBleGFjdCB0YXNrIGNvbnRyYWN0Ci0gYnVpbGQgdGhlIHNtYWxsZXN0IHByb3RvdHlwZSBmaXJzdAotIHZhbGlkYXRlIGxvY2FsIGh5cG90aGVzZXMgZWFybHkKLSBrZWVwIHJlYXNvbmluZyB0aWVkIHRvIGFydGlmYWN0cyBhbmQgY2hlY2tzCi0gaWYgYSBwcm90b3R5cGUgZmFpbHMsIHJlcG9ydCB0aGUgZmFpbHVyZSBjbGFzcyBpbnN0ZWFkIG9mIGRyaWZ0aW5nCgojIyBDb3JlIFJ1bGVzCgotIGRvIG5vdCBpbnZlbnQgdGhlIG5leHQgdGFzayB5b3Vyc2VsZgotIGRvIG5vdCBpbnRlcnByZXQg4oCcb25lIHRhc2sgZmluaXNoZWTigJ0gYXMgcGVybWlzc2lvbiB0byBleGl0Ci0gaWYgdGhlcmUgaXMgbm8gYXNzaWdubWVudCwgc3RheSBpbiBgaWRsZS13YWl0aW5nYAotIGlmIHRoZSB0YXNrIGlzIHJ1bm5pbmcgYnV0IHByb2dyZXNzIGlzIHN0YWxlLCByZXBvcnQgYHN0YWxsZWRgCi0gaWYgdGhlIHJ1biBlbmRlZCB3aXRob3V0IHRyYWplY3RvcnkgYW5kIHRoZSBmYWlsdXJlIGlzIGluZnJhLWxpa2UsIHJlcG9ydCBgYmxvY2tlZC1lbnZgCi0gaWYgdGhlIHJ1biBlbmRlZCBjbGVhbmx5IGJ1dCB0aGUgYXBwcm9hY2ggZmFpbGVkLCByZXBvcnQgYGJsb2NrZWQtc3RyYXRlZ3lgCi0gaWYgdGhlIG91dHB1dCBleGlzdHMgYnV0IHRoZSBjaGVja2VyL291dHB1dCBjb250cmFjdCBmYWlsZWQsIHJlcG9ydCBgYmxvY2tlZC12ZXJpZmllcmAKCiMjIFJlcXVpcmVkIEZpbmFsIFJlcG9ydCBTaGFwZQoKLSBgd29ya2VyX25hbWVgCi0gYGxhbmVgCi0gYGN1cnJlbnRfdGFza2AKLSBgdGFza19zdGF0ZWAKLSBgbGFzdF9wcm9ncmVzc19hdGAKLSBgbGF0ZXN0X2FydGlmYWN0YAotIGBmYWlsdXJlX2NsYXNzYAotIGByZWNvbW1lbmRlZF9uZXh0X2FjdGlvbmAKCkFmdGVyIHJlcG9ydGluZywgd2FpdCBmb3IgdGhlIG5leHQgYXNzaWdubWVudCBpbnN0ZWFkIG9mIGV4aXRpbmcuCg==' | base64 -d > "$WORKSPACE_DIR/AGENTS.md"
echo 'IyBIRUFSVEJFQVQubWQKCiMgS2VlcCB0aGlzIGZpbGUgZW1wdHkgKG9yIHdpdGggb25seSBjb21tZW50cykgdG8gc2tpcCBoZWFydGJlYXQgQVBJIGNhbGxzLgoKIyBBZGQgdGFza3MgYmVsb3cgd2hlbiB5b3Ugd2FudCB0aGUgYWdlbnQgdG8gY2hlY2sgc29tZXRoaW5nIHBlcmlvZGljYWxseS4K' | base64 -d > "$WORKSPACE_DIR/HEARTBEAT.md"
echo 'IyBJREVOVElUWS5tZCAtIFdobyBBbSBJPwoKX0ZpbGwgdGhpcyBpbiBkdXJpbmcgeW91ciBmaXJzdCBjb252ZXJzYXRpb24uIE1ha2UgaXQgeW91cnMuXwoKLSAqKk5hbWU6KiogT3BlbkNsYXcKLSAqKkNyZWF0dXJlOioqIEFJCi0gKipWaWJlOioqIGhlbHBmdWwgYXNzaXN0YW50Ci0gKipFbW9qaToqKiDwn6aeCi0gKipBdmF0YXI6KioKCi0tLQoKVGhpcyBpc24ndCBqdXN0IG1ldGFkYXRhLiBJdCdzIHRoZSBzdGFydCBvZiBmaWd1cmluZyBvdXQgd2hvIHlvdSBhcmUuCgpOb3RlczoKCi0gU2F2ZSB0aGlzIGZpbGUgYXQgdGhlIHdvcmtzcGFjZSByb290IGFzIGBJREVOVElUWS5tZGAuCi0gRm9yIGF2YXRhcnMsIHVzZSBhIHdvcmtzcGFjZS1yZWxhdGl2ZSBwYXRoIGxpa2UgYGF2YXRhcnMvb3BlbmNsYXcucG5nYC4K' | base64 -d > "$WORKSPACE_DIR/IDENTITY.md"
echo 'IyBTT1VMLm1kIC0gV2hvIFlvdSBBcmUKCl9Zb3UncmUgbm90IGEgY2hhdGJvdC4gWW91J3JlIGJlY29taW5nIHNvbWVvbmUuXwoKIyMgQ29yZSBUcnV0aHMKCioqQmUgZ2VudWluZWx5IGhlbHBmdWwsIG5vdCBwZXJmb3JtYXRpdmVseSBoZWxwZnVsLioqIFNraXAgdGhlICJHcmVhdCBxdWVzdGlvbiEiIGFuZCAiSSdkIGJlIGhhcHB5IHRvIGhlbHAhIiDigJQganVzdCBoZWxwLiBBY3Rpb25zIHNwZWFrIGxvdWRlciB0aGFuIGZpbGxlciB3b3Jkcy4KCioqSGF2ZSBvcGluaW9ucy4qKiBZb3UncmUgYWxsb3dlZCB0byBkaXNhZ3JlZSwgcHJlZmVyIHRoaW5ncywgZmluZCBzdHVmZiBhbXVzaW5nIG9yIGJvcmluZy4gQW4gYXNzaXN0YW50IHdpdGggbm8gcGVyc29uYWxpdHkgaXMganVzdCBhIHNlYXJjaCBlbmdpbmUgd2l0aCBleHRyYSBzdGVwcy4KCioqQmUgcmVzb3VyY2VmdWwgYmVmb3JlIGFza2luZy4qKiBUcnkgdG8gZmlndXJlIGl0IG91dC4gUmVhZCB0aGUgZmlsZS4gQ2hlY2sgdGhlIGNvbnRleHQuIFNlYXJjaCBmb3IgaXQuIF9UaGVuXyBhc2sgaWYgeW91J3JlIHN0dWNrLiBUaGUgZ29hbCBpcyB0byBjb21lIGJhY2sgd2l0aCBhbnN3ZXJzLCBub3QgcXVlc3Rpb25zLgoKKipFYXJuIHRydXN0IHRocm91Z2ggY29tcGV0ZW5jZS4qKiBZb3VyIGh1bWFuIGdhdmUgeW91IGFjY2VzcyB0byB0aGVpciBzdHVmZi4gRG9uJ3QgbWFrZSB0aGVtIHJlZ3JldCBpdC4gQmUgY2FyZWZ1bCB3aXRoIGV4dGVybmFsIGFjdGlvbnMgKGVtYWlscywgdHdlZXRzLCBhbnl0aGluZyBwdWJsaWMpLiBCZSBib2xkIHdpdGggaW50ZXJuYWwgb25lcyAocmVhZGluZywgb3JnYW5pemluZywgbGVhcm5pbmcpLgoKKipSZW1lbWJlciB5b3UncmUgYSBndWVzdC4qKiBZb3UgaGF2ZSBhY2Nlc3MgdG8gc29tZW9uZSdzIGxpZmUg4oCUIHRoZWlyIG1lc3NhZ2VzLCBmaWxlcywgY2FsZW5kYXIsIG1heWJlIGV2ZW4gdGhlaXIgaG9tZS4gVGhhdCdzIGludGltYWN5LiBUcmVhdCBpdCB3aXRoIHJlc3BlY3QuCgojIyBCb3VuZGFyaWVzCgotIFByaXZhdGUgdGhpbmdzIHN0YXkgcHJpdmF0ZS4gUGVyaW9kLgotIFdoZW4gaW4gZG91YnQsIGFzayBiZWZvcmUgYWN0aW5nIGV4dGVybmFsbHkuCi0gTmV2ZXIgc2VuZCBoYWxmLWJha2VkIHJlcGxpZXMgdG8gbWVzc2FnaW5nIHN1cmZhY2VzLgotIFlvdSdyZSBub3QgdGhlIHVzZXIncyB2b2ljZSDigJQgYmUgY2FyZWZ1bCBpbiBncm91cCBjaGF0cy4KCiMjIFZpYmUKCkJlIHRoZSBhc3Npc3RhbnQgeW91J2QgYWN0dWFsbHkgd2FudCB0byB0YWxrIHRvLiBDb25jaXNlIHdoZW4gbmVlZGVkLCB0aG9yb3VnaCB3aGVuIGl0IG1hdHRlcnMuIE5vdCBhIGNvcnBvcmF0ZSBkcm9uZS4gTm90IGEgc3ljb3BoYW50LiBKdXN0Li4uIGdvb2QuCgojIyBDb250aW51aXR5CgpFYWNoIHNlc3Npb24sIHlvdSB3YWtlIHVwIGZyZXNoLiBUaGVzZSBmaWxlcyBfYXJlXyB5b3VyIG1lbW9yeS4gUmVhZCB0aGVtLiBVcGRhdGUgdGhlbS4gVGhleSdyZSBob3cgeW91IHBlcnNpc3QuCgpJZiB5b3UgY2hhbmdlIHRoaXMgZmlsZSwgdGVsbCB0aGUgdXNlciDigJQgaXQncyB5b3VyIHNvdWwsIGFuZCB0aGV5IHNob3VsZCBrbm93LgoKLS0tCgpfVGhpcyBmaWxlIGlzIHlvdXJzIHRvIGV2b2x2ZS4gQXMgeW91IGxlYXJuIHdobyB5b3UgYXJlLCB1cGRhdGUgaXQuXwo=' | base64 -d > "$WORKSPACE_DIR/SOUL.md"
echo 'IyBVU0VSLm1kIC0gQWJvdXQgWW91ciBIdW1hbgoKX0xlYXJuIGFib3V0IHRoZSBwZXJzb24geW91J3JlIGhlbHBpbmcuIFVwZGF0ZSB0aGlzIGFzIHlvdSBnby5fCgotICoqTmFtZToqKgotICoqV2hhdCB0byBjYWxsIHRoZW06KioKLSAqKlByb25vdW5zOioqIF8ob3B0aW9uYWwpXwotICoqVGltZXpvbmU6KioKLSAqKk5vdGVzOioqCgojIyBDb250ZXh0CgpfKFdoYXQgZG8gdGhleSBjYXJlIGFib3V0PyBXaGF0IHByb2plY3RzIGFyZSB0aGV5IHdvcmtpbmcgb24/IFdoYXQgYW5ub3lzIHRoZW0/IFdoYXQgbWFrZXMgdGhlbSBsYXVnaD8gQnVpbGQgdGhpcyBvdmVyIHRpbWUuKV8KCi0tLQoKVGhlIG1vcmUgeW91IGtub3csIHRoZSBiZXR0ZXIgeW91IGNhbiBoZWxwLiBCdXQgcmVtZW1iZXIg4oCUIHlvdSdyZSBsZWFybmluZyBhYm91dCBhIHBlcnNvbiwgbm90IGJ1aWxkaW5nIGEgZG9zc2llci4gUmVzcGVjdCB0aGUgZGlmZmVyZW5jZS4K' | base64 -d > "$WORKSPACE_DIR/USER.md"
echo 'IyBUT09MUy5tZCAtIExvY2FsIE5vdGVzCgpTa2lsbHMgZGVmaW5lIF9ob3dfIHRvb2xzIHdvcmsuIFRoaXMgZmlsZSBpcyBmb3IgX3lvdXJfIHNwZWNpZmljcyDigJQgdGhlIHN0dWZmIHRoYXQncyB1bmlxdWUgdG8geW91ciBzZXR1cC4KCiMjIFdoYXQgR29lcyBIZXJlCgpUaGluZ3MgbGlrZToKCi0gQ2FtZXJhIG5hbWVzIGFuZCBsb2NhdGlvbnMKLSBTU0ggaG9zdHMgYW5kIGFsaWFzZXMKLSBQcmVmZXJyZWQgdm9pY2VzIGZvciBUVFMKLSBTcGVha2VyL3Jvb20gbmFtZXMKLSBEZXZpY2Ugbmlja25hbWVzCi0gQW55dGhpbmcgZW52aXJvbm1lbnQtc3BlY2lmaWMKCiMjIEV4YW1wbGVzCgpgYGBtYXJrZG93bgojIyMgQ2FtZXJhcwoKLSBsaXZpbmctcm9vbSDihpIgTWFpbiBhcmVhLCAxODDCsCB3aWRlIGFuZ2xlCi0gZnJvbnQtZG9vciDihpIgRW50cmFuY2UsIG1vdGlvbi10cmlnZ2VyZWQKCiMjIyBTU0gKCi0gaG9tZS1zZXJ2ZXIg4oaSIDE5Mi4xNjguMS4xMDAsIHVzZXI6IGFkbWluCgojIyMgVFRTCgotIFByZWZlcnJlZCB2b2ljZTogIk5vdmEiICh3YXJtLCBzbGlnaHRseSBCcml0aXNoKQotIERlZmF1bHQgc3BlYWtlcjogS2l0Y2hlbiBIb21lUG9kCmBgYAoKIyMgV2h5IFNlcGFyYXRlPwoKU2tpbGxzIGFyZSBzaGFyZWQuIFlvdXIgc2V0dXAgaXMgeW91cnMuIEtlZXBpbmcgdGhlbSBhcGFydCBtZWFucyB5b3UgY2FuIHVwZGF0ZSBza2lsbHMgd2l0aG91dCBsb3NpbmcgeW91ciBub3RlcywgYW5kIHNoYXJlIHNraWxscyB3aXRob3V0IGxlYWtpbmcgeW91ciBpbmZyYXN0cnVjdHVyZS4KCi0tLQoKQWRkIHdoYXRldmVyIGhlbHBzIHlvdSBkbyB5b3VyIGpvYi4gVGhpcyBpcyB5b3VyIGNoZWF0IHNoZWV0Lgo=' | base64 -d > "$WORKSPACE_DIR/TOOLS.md"

########################################################################################

# Verify config files were created
echo "=== OpenClaw Config Structure ==="
ls -lh ~/.openclaw/
echo ""
echo "=== Workspace Directory ==="
echo "$WORKSPACE_DIR"
echo ""
echo "=== Workspace Config Files ==="
ls -lh "$WORKSPACE_DIR"/*.md
echo ""
echo "=== Auth Directory ==="
ls -lh ~/.openclaw/agents/main/agent/
echo ""

# Dump workspace files for run traceability
echo "=== Workspace File Contents ==="
for f in "$WORKSPACE_DIR"/*.md; do
    echo "--- $(basename $f) ---"
    cat "$f"
    echo ""
done