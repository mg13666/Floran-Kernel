#!/usr/bin/env bash
# Fail the build if the requested KernelSU profile was silently changed by
# Kconfig dependencies or vendor config fragments. Run after `make olddefconfig`.

set -euo pipefail

CONFIG_FILE="${1:-out/.config}"
KSU_TYPE="${2:-None}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "error: kernel config not found: $CONFIG_FILE" >&2
  exit 1
fi

case "$KSU_TYPE" in
  KernelSU-Official|KernelSU-Official-susfs|KernelSU-Next|KernelSU-Next-susfs|ReSukiSU|ReSukiSU-susfs|None)
    ;;
  *)
    echo "error: unsupported KernelSU profile: $KSU_TYPE" >&2
    exit 1
    ;;
esac

failed=0
required=()

require_builtin() {
  local symbol="$1"
  if ! grep -qx "CONFIG_${symbol}=y" "$CONFIG_FILE"; then
    echo "::error::CONFIG_${symbol} did not resolve to built-in (=y) for ${KSU_TYPE}"
    grep -E "^(CONFIG_${symbol}=|# CONFIG_${symbol} is not set)" "$CONFIG_FILE" || true
    failed=1
  fi
}

if [[ "$KSU_TYPE" == "None" ]]; then
  if grep -Eq '^CONFIG_KSU=[ym]$' "$CONFIG_FILE"; then
    echo "::error::CONFIG_KSU is enabled even though the selected profile is None"
    grep -E '^(CONFIG_KSU=|# CONFIG_KSU is not set)' "$CONFIG_FILE" || true
    failed=1
  fi
else
  required+=(KSU)
fi

if [[ "$KSU_TYPE" == ReSukiSU* ]]; then
  required+=(KSU_MULTI_MANAGER_SUPPORT)
  if ! grep -q '^CONFIG_KSU_FULL_NAME_FORMAT=' "$CONFIG_FILE"; then
    echo "::error::CONFIG_KSU_FULL_NAME_FORMAT is missing for ${KSU_TYPE}"
    failed=1
  fi
fi

if [[ "$KSU_TYPE" == *-susfs ]]; then
  required+=(
    KSU_SUSFS
    KSU_SUSFS_SUS_PATH
    KSU_SUSFS_SUS_MOUNT
    KSU_SUSFS_SUS_KSTAT
    KSU_SUSFS_SPOOF_UNAME
    KSU_SUSFS_ENABLE_LOG
    KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS
    KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG
    KSU_SUSFS_OPEN_REDIRECT
    KSU_SUSFS_SUS_MAP
  )
else
  if grep -qx 'CONFIG_KSU_SUSFS=y' "$CONFIG_FILE"; then
    echo "::error::CONFIG_KSU_SUSFS is enabled for a non-SUSFS profile: ${KSU_TYPE}"
    failed=1
  fi
fi

for symbol in "${required[@]}"; do
  require_builtin "$symbol"
done

if (( failed != 0 )); then
  echo "KernelSU configuration validation failed for ${KSU_TYPE}." >&2
  exit 1
fi

echo "KernelSU configuration validation passed for ${KSU_TYPE} (${#required[@]} required built-ins)."
if [[ "$KSU_TYPE" == "None" ]]; then
  grep -E '^(CONFIG_KSU=|# CONFIG_KSU is not set)' "$CONFIG_FILE" || echo "CONFIG_KSU is unavailable and disabled"
else
  for symbol in "${required[@]}"; do
    grep -x "CONFIG_${symbol}=y" "$CONFIG_FILE"
  done
  if [[ "$KSU_TYPE" == ReSukiSU* ]]; then
    grep '^CONFIG_KSU_FULL_NAME_FORMAT=' "$CONFIG_FILE"
  fi
fi
