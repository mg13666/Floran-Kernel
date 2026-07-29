# Floran Kernel

基于 GitHub Actions 的 Android 6.1 GKI 内核自动构建工作流，面向 `sm8650` / `pineapple` 内核源码及其 Oplus GKI 配置。

工作流会拉取指定 ROM 的内核源码，按需集成 KernelSU、SUSFS、Droidspaces、LZ4、网络功能等组件，最终通过 AnyKernel3 打包为可刷写的 ZIP；也可自动创建 GitHub Release。

> [!WARNING]
> 内核与模块源码、ROM、设备及固件版本必须相互匹配。刷写内核存在无法启动、数据丢失或其他不可预期风险，请自行确认兼容性并提前备份数据。

## 功能特性

- 支持多个 ROM 内核源码：
  - YAAP
  - LineageOS
  - crDroid
  - PixelOS
- 支持多种 Root 内核方案：
  - KernelSU Official
  - KernelSU-Next
  - ReSukiSU
  - 上述方案的 SUSFS 变体（部分组合）
  - 不集成 KernelSU
- 可选功能：
  - LZ4 1.10.0 补丁（YAAP 源码不应用）
  - BBR、ECN 与 FQ 队列调度
  - IPSet 与 IPv6 NAT
  - Droidspaces 容器支持
  - Droidspaces Extended：额外启用虚拟 HCI、systemd-coredump 相关配置及 Lindroid EVDI DRM
  - 可选原生 Docker 内核功能：补齐 cgroup、namespace、bridge/netfilter、IPVS、macvlan/ipvlan、VXLAN 与 overlayfs 等配置，并严格校验最终 `.config`
- 使用 AOSP Clang `r563880c` 编译
- 通过 AnyKernel3 输出可刷写 ZIP
- 支持上传 Actions Artifact，并可自动创建 GitHub Release

## 使用方法

### 单独构建

1. Fork 本仓库。
2. 打开仓库的 **Actions** 页面。
3. 选择 **Build Kernel** 工作流。
4. 点击 **Run workflow**，按需填写构建参数。
5. 等待工作流完成：
   - 可在对应工作流运行页面的 **Artifacts** 下载 ZIP；
   - 若启用了 `Create GitHub Release`，可在仓库的 **Releases** 页面下载 ZIP。

### 构建参数

| 参数 | 说明 |
|---|---|
| `ROM Kernel Source Code` | 选择内核源码：`YAAP`、`LineageOS`、`Crdroid` 或 `PixelOS`。 |
| `KernelSU Version` | 选择 KernelSU 集成方案，或选择 `None` 构建非 KernelSU 内核。 |
| `Enable lz4 1.10.0 patch` | 为非 YAAP 源码应用 LZ4 1.10.0 补丁。 |
| `Enable IPSET & IPv6_NAT` | 启用 IPSet、IPv6 NAT 及相关 Netfilter 配置。 |
| `Enable BBR & ECN` | 启用 BBR、ECN 与 FQ。 |
| `Enable native Docker kernel support` | 在所有 vendor 配置合并后启用并校验原生 Docker 所需内核功能；默认开启。 |
| `Droidspaces Container Support` | 选择 `none`、`standard` 或 `extended` 容器支持。YAAP 源码不会应用 Droidspaces 补丁。 |
| `Custom Kernel Name` | 设置内核附加版本名。脚本会自动补上 `-` 前缀。 |
| `创建 GitHub Release？` | 是否在构建成功后创建并上传 GitHub Release。 |

## ROM 源码与分支

单独构建工作流使用以下上游与分支：

| ROM 源码 | Kernel 仓库 / 分支 | Modules 仓库 / 分支 |
|---|---|---|
| YAAP | [`AkiHaza/android_kernel_oneplus_sm8650`](https://github.com/AkiHaza/android_kernel_oneplus_sm8650) / `sixteen` | [`AkiHaza/android_kernel_oneplus_sm8650-modules`](https://github.com/AkiHaza/android_kernel_oneplus_sm8650-modules) / `sixteen` |
| LineageOS | [`LineageOS/android_kernel_oneplus_sm8650`](https://github.com/LineageOS/android_kernel_oneplus_sm8650) / `lineage-23.2` | [`LineageOS/android_kernel_oneplus_sm8650-modules`](https://github.com/LineageOS/android_kernel_oneplus_sm8650-modules) / `lineage-23.2` |
| crDroid | [`crdroidandroid/android_kernel_oneplus_sm8650`](https://github.com/crdroidandroid/android_kernel_oneplus_sm8650) / `16.0` | [`crdroidandroid/android_kernel_oneplus_sm8650-modules`](https://github.com/crdroidandroid/android_kernel_oneplus_sm8650-modules) / `16.0` |
| PixelOS | [`PixelOS-Devices/android_kernel_oneplus_sm8650`](https://github.com/PixelOS-Devices/android_kernel_oneplus_sm8650) / `sixteen-qpr2` | [`PixelOS-Devices/android_kernel_oneplus_sm8650-modules`](https://github.com/PixelOS-Devices/android_kernel_oneplus_sm8650-modules) / `sixteen-qpr2` |

## KernelSU 与 SUSFS

可选择下列 KernelSU 方案：

| 选项 | 内容 |
|---|---|
| `KernelSU-Official` | 官方 KernelSU |
| `KernelSU-Official-susfs` | 官方 KernelSU + SUSFS |
| `KernelSU-Next` | KernelSU-Next |
| `KernelSU-Next-susfs` | KernelSU-Next + SUSFS |
| `ReSukiSU` | ReSukiSU |
| `ReSukiSU-susfs` | ReSukiSU + SUSFS |
| `None` | 不集成 KernelSU |

选择带 `susfs` 的方案时，工作流会拉取 `susfs4ksu` 的 `gki-android14-6.1` 分支，并启用 SUSFS 相关配置。SUSFS 补丁只允许已知的 LineageOS `fs/namespace.c` include 差异由兼容逻辑修复；其他 reject 均会终止构建。

所有 GKI 与 vendor 配置合并后，工作流会通过 `tools/enable_kernelsu_config.sh` 重新应用所选 KernelSU profile，运行 `olddefconfig`，再由 `tools/verify_kernelsu_config.sh` 检查最终 `.config`。选择 ReSukiSU 时会强制检查多管理器支持；选择任何 `-susfs` 方案时，全部 SUSFS 关键配置必须最终解析为内建 `=y`，否则不会生成一个名称与实际功能不符的刷机包。最终 `.config` 与校验报告会上传到 `KernelSU_Kernel_Config` Artifact。

刷入集成 KernelSU 的内核后，请安装与所选方案相对应的管理器：

- [KernelSU](https://github.com/tiann/KernelSU)
- [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next)
- [ReSukiSU](https://github.com/ReSukiSU/ReSukiSU)

## Droidspaces 容器支持

| 模式 | 内容 |
|---|---|
| `none` | 不添加 Droidspaces 相关功能。 |
| `standard` | 启用 PID、IPC、挂载命名空间、SysV IPC、POSIX 消息队列、NTSync 等基础容器支持。 |
| `extended` | 在标准支持基础上，额外启用虚拟 HCI、Lindroid EVDI DRM，以及相关扩展配置。 |

> [!NOTE]
> Droidspaces 补丁仅会应用于非 YAAP 源码。

## 原生 Docker 内核支持

启用 `Enable native Docker kernel support` 后，工作流会在 GKI 与 vendor 配置全部合并之后：

1. 严格应用 `patch/fix_cgroup.patch`（非 YAAP 源码），恢复 Android `noprefix` cgroup 与标准 Linux 文件名的兼容性；
2. 通过 `tools/enable_native_docker_config.sh` 启用 Docker、containerd、runc、Swarm 与可选 IPVS 所需配置；
3. 运行 `olddefconfig` 解析 Kconfig 依赖；
4. 通过 `tools/verify_native_docker_config.sh` 检查最终配置。任何必需选项未解析为内建 `=y` 时，构建会直接失败；
5. 上传 `Native_Docker_Kernel_Config` Artifact，内含最终 `.config` 与验证报告。

> [!IMPORTANT]
> 此选项只补齐**内核能力**。Android 默认可能将 `cpu`、`cpuset`、`blkio` 与 `memory` 分散在 cgroup v1/v2 层级；要完整运行 Docker，还需要与当前 ROM 匹配的 early-init cgroup 挂载配置、真实 chroot 用户空间以及 SELinux 策略。不要在启动后的 Android 根命名空间中强制卸载或重挂现有 cgroup。

> [!WARNING]
> `CONFIG_USER_NS` 与完整容器网络会增加内核攻击面。仅向可信应用授予 root/KernelSU 权限，并保留可刷回的内核和系统镜像。

## 输出文件命名

单独构建的 ZIP 大致遵循：

```text
<KSU 方案>[-dss|-dss-ext][-docker]-<UTC 月日>.zip
```

其中：

- `dss`：Droidspaces Standard
- `dss-ext`：Droidspaces Extended
- `docker`：启用原生 Docker 内核功能并通过最终配置校验

## 本地构建

工作流使用的主要依赖如下：

```bash
sudo apt update
sudo apt install -y \
  bc bison flex libssl-dev libelf-dev libdw-dev build-essential \
  lz4 git python3 curl dwarves cpio gcc-aarch64-linux-gnu
```

编译时使用 AOSP Clang `r563880c`，并执行：

```bash
make O=out gki_defconfig vendor/pineapple_GKI.config vendor/oplus/pineapple_GKI.config
make -j"$(nproc)" O=out Image
```

完整的源码拉取、补丁应用、KernelSU/SUSFS 集成与打包步骤，请以 [`.github/workflows/Build.yml`](.github/workflows/Build.yml) 为准。

## 致谢

- [AnyKernel3](https://github.com/Kernel-SU/AnyKernel3)
- [KernelSU](https://github.com/tiann/KernelSU)
- [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next)
- [ReSukiSU](https://github.com/ReSukiSU/ReSukiSU)
- [SUSFS4KSU](https://gitlab.com/simonpunk/susfs4ksu)
- 各 ROM、内核源码及补丁项目的维护者
