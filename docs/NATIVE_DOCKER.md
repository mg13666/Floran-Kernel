# Minimal native Docker support

This repository's Docker option targets **rootful Docker Engine running directly on the Android host kernel**. It does not use AVF, a virtual machine, proot, or a nested kernel.

## Scope

The profile is intentionally limited to the ordinary Docker path:

- Linux namespaces required by rootful containers;
- device and PIDs cgroups plus the Android/GKI cgroup baseline;
- seccomp and file-handle support;
- `overlay2` storage on ext4;
- veth, Linux bridge, conntrack, NAT, and iptables/xtables networking.

It does not request:

- `CONFIG_USER_NS` or rootless Docker;
- `CONFIG_CFS_BANDWIDTH` or CPU quota;
- cgroup perf or hugetlb accounting;
- nftables, IPVS, Kubernetes, or Swarm overlay networking;
- macvlan, ipvlan, VXLAN, or bridge VLAN filtering.

The profile does not apply `patch/fix_cgroup.patch`. That source patch is not part of the upstream Floran-Kernel build workflow and is unnecessary for the first boot-safety test.

## What a successful build proves

The workflow runs `olddefconfig` and then verifies every required option in the final `.config`. The resulting report proves that the built `Image` requested the minimal kernel capabilities. It does **not** by itself prove that Docker works on a particular ROM.

Native Docker is considered validated only after all of the following pass on the device:

1. Android boots and the expected KernelSU/SUSFS profile remains available.
2. `/proc/config.gz` matches the build report.
3. Required cgroup v1/v2 controllers are mounted and visible inside a dedicated chroot/mount namespace.
4. SELinux policy permits the intended trusted root service, or an explicitly documented test policy is used.
5. Native arm64 `containerd`, `runc`, and `dockerd` start without a VM or proot.
6. `docker info`, `docker run --rm hello-world`, bridge networking, DNS, bind mounts, and an `overlay2` write test pass.

Do not unmount or replace Android's live cgroup hierarchy from the Android root mount namespace. Any cgroup adaptation must be performed during early init or inside a dedicated mount namespace.

## Flashing safety

The earlier broad 61-feature profile enabled scheduler/cgroup, hugetlb, IPVS, nftables, and additional network features at once. On a `giuliac` device running LineageOS 23.2, its test image reached the first boot screen and rebooted. That image is not considered bootable and must not be flashed again.

Before every test:

- verify the active slot;
- back up the active slot's `boot` partition;
- copy the backup off-device;
- verify its size and SHA-256;
- keep a tested fastboot recovery path.

The minimal profile reduces changes but cannot guarantee bootability before a real-device boot test.
