#!/usr/bin/env bash
# Apply the selected KernelSU profile after all defconfig fragments have been
# merged. Run from the kernel source root.

set -euo pipefail

CONFIG_FILE="${1:-out/.config}"
KSU_TYPE="${2:-None}"
CONFIG_TOOL="./scripts/config"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "error: kernel config not found: $CONFIG_FILE" >&2
  exit 1
fi
if [[ ! -x "$CONFIG_TOOL" ]]; then
  echo "error: scripts/config is unavailable" >&2
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

config_enable() {
  "$CONFIG_TOOL" --file "$CONFIG_FILE" --enable "$1"
}

config_disable() {
  "$CONFIG_TOOL" --file "$CONFIG_FILE" --disable "$1"
}

if [[ "$KSU_TYPE" == "None" ]]; then
  config_disable KSU
else
  config_enable KSU
fi

# ReSukiSU supports the custom/multi-manager layout used by the currently
# installed Floran kernel and com.kowx712.supermanager.
if [[ "$KSU_TYPE" == ReSukiSU* ]]; then
  config_enable KSU_MULTI_MANAGER_SUPPORT
fi

susfs_symbols=(
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

if [[ "$KSU_TYPE" == *-susfs ]]; then
  for symbol in "${susfs_symbols[@]}"; do
    config_enable "$symbol"
  done
else
  # Do not allow a non-SUSFS-labelled artifact to inherit SUSFS accidentally.
  config_disable KSU_SUSFS
fi

# Preserve an auditable marker in the generated config.
echo "# KernelSU profile requested by Floran-Kernel workflow: $KSU_TYPE" >> "$CONFIG_FILE"
