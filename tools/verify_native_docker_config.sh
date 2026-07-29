#!/usr/bin/env bash
# Fail the build if Kconfig silently drops a feature required by the native
# Docker profile. Run after `make olddefconfig`.

set -euo pipefail

CONFIG_FILE="${1:-out/.config}"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "error: kernel config not found: $CONFIG_FILE" >&2
  exit 1
fi

required=(
  NAMESPACES NET_NS PID_NS IPC_NS UTS_NS USER_NS
  CGROUPS CGROUP_CPUACCT CGROUP_DEVICE CGROUP_FREEZER CGROUP_SCHED
  CPUSETS MEMCG CGROUP_BPF CGROUP_PIDS CFS_BANDWIDTH FAIR_GROUP_SCHED
  BLK_CGROUP BLK_DEV_THROTTLING CGROUP_PERF CGROUP_HUGETLB
  NET_CLS_CGROUP CGROUP_NET_PRIO
  KEYS POSIX_MQUEUE SECCOMP SECCOMP_FILTER
  VETH BRIDGE BRIDGE_NETFILTER BRIDGE_VLAN_FILTERING
  MACVLAN IPVLAN VXLAN DUMMY TUN
  NETFILTER_XT_MATCH_ADDRTYPE NETFILTER_XT_MATCH_CONNTRACK
  NETFILTER_XT_MATCH_IPVS NETFILTER_XT_MARK
  IP_NF_FILTER IP_NF_MANGLE IP_NF_RAW IP_NF_NAT
  IP_NF_TARGET_MASQUERADE IP_NF_TARGET_REDIRECT
  IP6_NF_FILTER IP6_NF_MANGLE IP6_NF_RAW IP6_NF_NAT
  IP6_NF_TARGET_MASQUERADE NF_NAT
  IP_VS IP_VS_NFCT IP_VS_PROTO_TCP IP_VS_PROTO_UDP IP_VS_RR
  OVERLAY_FS EXT4_FS EXT4_FS_POSIX_ACL EXT4_FS_SECURITY
)

failed=0
for symbol in "${required[@]}"; do
  if ! grep -qx "CONFIG_${symbol}=y" "$CONFIG_FILE"; then
    echo "::error::CONFIG_${symbol} did not resolve to built-in (=y)"
    grep -E "^(CONFIG_${symbol}=|# CONFIG_${symbol} is not set)" "$CONFIG_FILE" || true
    failed=1
  fi
done

if (( failed != 0 )); then
  echo "Native Docker kernel configuration validation failed." >&2
  exit 1
fi

echo "Native Docker kernel configuration validation passed (${#required[@]} features)."
printf '%s\n' "${required[@]}" | while read -r symbol; do
  grep -x "CONFIG_${symbol}=y" "$CONFIG_FILE"
done