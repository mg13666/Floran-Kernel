#!/usr/bin/env bash
# Enable native Docker/LXC kernel features after all defconfig fragments have
# been merged. Run from the kernel source root.

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

# Namespaces and cgroups.
for symbol in \
  NAMESPACES UTS_NS IPC_NS USER_NS PID_NS NET_NS \
  CGROUPS CGROUP_SCHED FAIR_GROUP_SCHED CFS_BANDWIDTH \
  CGROUP_CPUACCT CGROUP_DEVICE CGROUP_FREEZER CGROUP_PIDS \
  CPUSETS MEMCG BLK_CGROUP BLK_DEV_THROTTLING CGROUP_BPF \
  CGROUP_PERF HUGETLBFS HUGETLB_PAGE CGROUP_HUGETLB \
  NET_CLS NET_CLS_CGROUP CGROUP_NET_PRIO; do
  config_enable "$symbol"
done

# Runtime isolation and container filesystems.
for symbol in \
  KEYS FHANDLE POSIX_MQUEUE SECCOMP SECCOMP_FILTER \
  DEVTMPFS DEVPTS_FS UNIX98_PTYS TMPFS TMPFS_POSIX_ACL TMPFS_XATTR \
  OVERLAY_FS EXT4_FS EXT4_FS_POSIX_ACL EXT4_FS_SECURITY; do
  config_enable "$symbol"
done

# Docker bridge/NAT, macvlan/ipvlan and Swarm overlay networking.
for symbol in \
  NET NETFILTER NETFILTER_ADVANCED NET_SCHED NET_CLS \
  BRIDGE BRIDGE_NETFILTER BRIDGE_VLAN_FILTERING VETH DUMMY \
  MACVLAN IPVLAN VXLAN TUN \
  NF_CONNTRACK NF_NAT \
  IP_NF_IPTABLES IP_NF_FILTER IP_NF_MANGLE IP_NF_RAW IP_NF_NAT \
  IP_NF_TARGET_MASQUERADE IP_NF_TARGET_REDIRECT \
  IP6_NF_IPTABLES IP6_NF_FILTER IP6_NF_MANGLE IP6_NF_RAW IP6_NF_NAT \
  IP6_NF_TARGET_MASQUERADE \
  NETFILTER_XT_MARK NETFILTER_XT_MATCH_ADDRTYPE \
  NETFILTER_XT_MATCH_CONNTRACK NETFILTER_XT_MATCH_IPVS; do
  config_enable "$symbol"
done

# Kubernetes/Swarm IPVS support.
for symbol in \
  IP_VS IP_VS_NFCT IP_VS_PROTO_TCP IP_VS_PROTO_UDP IP_VS_RR; do
  config_enable "$symbol"
done

# nftables is useful for modern Docker frontends; iptables support above remains
# enabled for compatibility with Android and iptables-legacy.
for symbol in \
  NF_TABLES NFT_CT NFT_FIB NFT_FIB_IPV4 NFT_FIB_IPV6 NFT_MASQ NFT_NAT; do
  config_enable "$symbol"
done

# Preserve an auditable marker in the generated config.
echo "# Native Docker feature set requested by Floran-Kernel workflow" >> "$CONFIG_FILE"
