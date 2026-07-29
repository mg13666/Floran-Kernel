#!/usr/bin/env bash
# Enable the smallest audited kernel feature set for rootful Docker Engine.
# Apply after all GKI/vendor config fragments have been merged.

set -euo pipefail

CONFIG_FILE="${1:-out/.config}"
CONFIG_TOOL="./scripts/config"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "error: kernel config not found: $CONFIG_FILE" >&2
  exit 1
fi
if [[ ! -x "$CONFIG_TOOL" ]]; then
  echo "error: scripts/config is unavailable" >&2
  exit 1
fi

config_enable() {
  "$CONFIG_TOOL" --file "$CONFIG_FILE" --enable "$1"
}

# Rootful container isolation. USER_NS is deliberately not requested.
for symbol in \
  NAMESPACES UTS_NS IPC_NS PID_NS NET_NS \
  CGROUPS CGROUP_CPUACCT CGROUP_DEVICE CGROUP_FREEZER CGROUP_SCHED \
  FAIR_GROUP_SCHED CPUSETS MEMCG BPF BPF_SYSCALL CGROUP_BPF CGROUP_PIDS \
  BLK_CGROUP BLK_DEV_THROTTLING \
  KEYS FHANDLE POSIX_MQUEUE SECCOMP SECCOMP_FILTER; do
  config_enable "$symbol"
done

# Container pseudo-filesystems and the overlay2 storage driver.
for symbol in \
  DEVTMPFS UNIX98_PTYS TMPFS TMPFS_XATTR \
  OVERLAY_FS EXT4_FS EXT4_FS_POSIX_ACL EXT4_FS_SECURITY; do
  config_enable "$symbol"
done

# Standard Docker bridge networking using iptables/xtables.
# nftables, IPVS, VXLAN, macvlan and ipvlan are intentionally not requested.
for symbol in \
  NET NETFILTER NETFILTER_ADVANCED \
  BRIDGE BRIDGE_NETFILTER VETH \
  NF_CONNTRACK NF_NAT \
  NETFILTER_XT_MARK NETFILTER_XT_MATCH_ADDRTYPE \
  NETFILTER_XT_MATCH_CONNTRACK NETFILTER_XT_TARGET_MASQUERADE \
  IP_NF_IPTABLES IP_NF_FILTER IP_NF_MANGLE IP_NF_RAW IP_NF_NAT \
  IP_NF_TARGET_MASQUERADE \
  IP6_NF_IPTABLES IP6_NF_FILTER IP6_NF_MANGLE IP6_NF_RAW IP6_NF_NAT \
  IP6_NF_TARGET_MASQUERADE; do
  config_enable "$symbol"
done

cat >> "$CONFIG_FILE" <<'EOF'
# Minimal rootful native Docker feature set requested by Floran-Kernel workflow
# Excludes rootless USER_NS, CFS quota, perf/hugetlb, nftables, IPVS and Swarm overlay networking
EOF