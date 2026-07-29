#!/usr/bin/env bash
# Verify the minimal rootful Docker kernel profile after `make olddefconfig`.

set -euo pipefail

CONFIG_FILE="${1:-out/.config}"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "error: kernel config not found: $CONFIG_FILE" >&2
  exit 1
fi

required=(
  NAMESPACES NET_NS PID_NS IPC_NS UTS_NS
  CGROUPS CGROUP_CPUACCT CGROUP_DEVICE CGROUP_FREEZER CGROUP_SCHED
  FAIR_GROUP_SCHED CPUSETS MEMCG BPF BPF_SYSCALL CGROUP_BPF CGROUP_PIDS
  BLK_CGROUP BLK_DEV_THROTTLING
  KEYS FHANDLE POSIX_MQUEUE SECCOMP SECCOMP_FILTER
  DEVTMPFS UNIX98_PTYS TMPFS TMPFS_XATTR
  VETH BRIDGE BRIDGE_NETFILTER
  NF_CONNTRACK NF_NAT
  NETFILTER_XT_MARK NETFILTER_XT_MATCH_ADDRTYPE
  NETFILTER_XT_MATCH_CONNTRACK NETFILTER_XT_TARGET_MASQUERADE
  IP_NF_IPTABLES IP_NF_FILTER IP_NF_MANGLE IP_NF_RAW IP_NF_NAT
  IP_NF_TARGET_MASQUERADE
  IP6_NF_IPTABLES IP6_NF_FILTER IP6_NF_MANGLE IP6_NF_RAW IP6_NF_NAT
  IP6_NF_TARGET_MASQUERADE
  OVERLAY_FS EXT4_FS EXT4_FS_POSIX_ACL EXT4_FS_SECURITY
)

# Report advanced features without changing their vendor-selected values.
not_requested=(
  USER_NS CFS_BANDWIDTH CGROUP_PERF CGROUP_HUGETLB
  HUGETLBFS HUGETLB_PAGE
  NF_TABLES NFT_CT NFT_FIB NFT_FIB_IPV4 NFT_FIB_IPV6 NFT_MASQ NFT_NAT
  IP_VS IP_VS_NFCT IP_VS_PROTO_TCP IP_VS_PROTO_UDP IP_VS_RR
  MACVLAN IPVLAN VXLAN BRIDGE_VLAN_FILTERING
)

failed=0
for symbol in "${required[@]}"; do
  if ! grep -qx "CONFIG_${symbol}=y" "$CONFIG_FILE"; then
    echo "::error::CONFIG_${symbol} did not resolve to built-in (=y)"
    grep -E "^(CONFIG_${symbol}=|# CONFIG_${symbol} is not set)" \
      "$CONFIG_FILE" || true
    failed=1
  fi
done

if (( failed != 0 )); then
  echo "Minimal rootful Docker kernel configuration validation failed." >&2
  exit 1
fi

echo "Minimal rootful Docker kernel configuration validation passed (${#required[@]} required built-ins)."
echo "Required profile:"
for symbol in "${required[@]}"; do
  grep -x "CONFIG_${symbol}=y" "$CONFIG_FILE"
done

echo "Not requested by this minimal profile (informational):"
for symbol in "${not_requested[@]}"; do
  if ! grep -E "^(CONFIG_${symbol}=|# CONFIG_${symbol} is not set)" \
      "$CONFIG_FILE"; then
    echo "CONFIG_${symbol}=not-present"
  fi
done

cat <<'EOF'
Profile limits: rootful Docker only; no rootless containers, CPU quota,
hugetlb limits, nftables backend, IPVS or Swarm overlay networking are promised.
A successful Kconfig check does not validate Android cgroup mounts, SELinux,
containerd/dockerd userspace, or an actual docker run; test those after boot.
EOF