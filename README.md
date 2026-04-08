# TaishanPi-3 Linux SDK

English | [中文](README.zh.md)

Linux SDK for the TaishanPi-3 development board based on Rockchip RK3576, with multi-repository code managed via the `repo` tool.

## Quick Start

### System Requirements

- Ubuntu 22.04 LTS (x86_64)
- Disk space ≥ 300GB
- RAM ≥ 16GB

### One-Click Installation

```bash
curl -fsSL https://raw.githubusercontent.com/TaishanPi-Rockchip/manifest/refs/heads/TaishanPi-3-260402/TaishanPi-3-Install_CN.sh | bash
```

The script automatically performs the following steps:

1. Detects the network environment and configures the optimal APT mirror source (CERNET / Tsinghua / Alibaba Cloud)
2. Installs build dependencies (cross-compilation toolchain, QEMU, Git LFS, and 70+ packages)
3. Configures the QEMU aarch64 emulation environment
4. Downloads and configures the repo tool
5. Clones all SDK repositories
6. Pulls Git LFS large files

Full logs are saved at `/tmp/taishanpi3-install-*.log`.

## SDK Directory Structure

```
TaishanPi-3-Linux/
├── kernel/              -> kernel-6.1 (Linux 6.1 kernel)
├── u-boot/              U-Boot bootloader
├── buildroot/           Buildroot root filesystem
├── debian/              Debian root filesystem
├── ubuntu/              Ubuntu root filesystem
├── yocto/               Yocto build system
│   ├── poky/
│   ├── meta-rockchip/
│   ├── meta-openembedded/
│   ├── meta-browser/
│   └── meta-clang/
├── device/rockchip/     Board-level configuration and build scripts
├── rkbin/               Rockchip firmware binaries
├── app/                 Applications
│   ├── lvgl_demo/
│   ├── rkipc/
│   └── rkadk/
├── external/            External components
│   ├── mpp/             Media Processing Platform
│   ├── rknpu2/          NPU runtime
│   ├── rknn-toolkit2/   NPU toolkit
│   ├── camera_engine_rkaiq/  ISP image processing (LFS)
│   ├── linux-rga/       2D graphics acceleration
│   ├── libmali/         GPU libraries
│   ├── rkwifibt/        WiFi/BT drivers
│   ├── rockit/          Multimedia framework
│   └── ...
├── hal/                 MCU HAL layer
├── rtos/                RT-Thread RTOS
├── tools/               Flashing and debugging tools (LFS)
├── prebuilts/           Prebuilt toolchains (LFS)
├── docs/                Development documentation
├── build.sh             -> Build entry script
├── envsetup.sh          -> Buildroot environment setup
├── rkflash.sh           -> Flashing script
└── Makefile             -> Top-level Makefile
```

## Building

```bash
cd ~/TaishanPi-3-Linux

# Select the target system and board configuration
./build.sh lunch

# Full build
./build.sh all

# Build individual modules
./build.sh uboot
./build.sh kernel
./build.sh rootfs
./build.sh firmware
```

## Troubleshooting

If you encounter issues during installation, run the diagnostic script to check the host environment:

```bash
curl -fsSL https://raw.githubusercontent.com/TaishanPi-Rockchip/manifest/refs/heads/TaishanPi-3-260402/TaishanPi-3-Diagnose.sh | bash
```

## Repository Information

- Code hosting: [github.com/TaishanPi-Rockchip](https://github.com/TaishanPi-Rockchip)
- Manifest branch: `TaishanPi-3-260402`
- SoC: chip RK3576
- Kernel version: Linux 6.1
