# TaishanPi-3 Linux SDK

[English](README.md) | 中文

基于 Rockchip RK3576 的 TaishanPi-3 开发板 Linux SDK，通过 `repo` 工具管理多仓库代码。

## 快速开始

### 系统要求

- Ubuntu 22.04 LTS (x86_64)
- 磁盘空间 ≥ 300GB
- 内存 ≥ 16GB

### 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/TaishanPi-Rockchip/manifest/refs/heads/TaishanPi-3-260402/TaishanPi-3-Install_CN.sh | bash
```

脚本会自动完成以下步骤：

1. 检测网络环境，配置最优 APT 镜像源（CERNET / 清华 / 阿里云）
2. 安装编译依赖（交叉编译工具链、QEMU、Git LFS 等 70+ 软件包）
3. 配置 QEMU aarch64 模拟环境
4. 下载并配置 repo 工具
5. 克隆 SDK 全部仓库
6. 拉取 Git LFS 大文件

完整日志保存在 `/tmp/taishanpi3-install-*.log`。

## SDK 目录结构

```
TaishanPi-3-Linux/
├── kernel/              -> kernel-6.1 (Linux 6.1 内核)
├── u-boot/              U-Boot 引导
├── buildroot/           Buildroot 根文件系统
├── debian/              Debian 根文件系统
├── ubuntu/              Ubuntu 根文件系统
├── yocto/               Yocto 构建系统
│   ├── poky/
│   ├── meta-rockchip/
│   ├── meta-openembedded/
│   ├── meta-browser/
│   └── meta-clang/
├── device/rockchip/     板级配置与构建脚本
├── rkbin/               Rockchip 固件二进制
├── app/                 应用程序
│   ├── lvgl_demo/
│   ├── rkipc/
│   └── rkadk/
├── external/            外部组件
│   ├── mpp/             媒体处理平台
│   ├── rknpu2/          NPU 运行时
│   ├── rknn-toolkit2/   NPU 工具链
│   ├── camera_engine_rkaiq/  ISP 图像处理 (LFS)
│   ├── linux-rga/       2D 图形加速
│   ├── libmali/         GPU 库
│   ├── rkwifibt/        WiFi/BT 驱动
│   ├── rockit/          多媒体框架
│   └── ...
├── hal/                 MCU HAL 层
├── rtos/                RT-Thread RTOS
├── tools/               烧录与调试工具 (LFS)
├── prebuilts/           预编译工具链 (LFS)
├── docs/                开发文档
├── build.sh             -> 构建入口脚本
├── envsetup.sh          -> Buildroot 环境配置
├── rkflash.sh           -> 烧录脚本
└── Makefile             -> 顶层 Makefile
```

## 编译

```bash
cd ~/TaishanPi-3-Linux

# 选择编译的目标系统与板级配置
./build.sh lunch

# 全量编译
./build.sh all

# 单独编译各模块
./build.sh uboot
./build.sh kernel
./build.sh rootfs
./build.sh firmware
```

## 故障排查

如果安装过程中遇到问题，运行诊断脚本检查宿主机环境：

```bash
curl -fsSL https://raw.githubusercontent.com/TaishanPi-Rockchip/manifest/refs/heads/TaishanPi-3-260402/TaishanPi-3-Diagnose.sh | bash
```

## 仓库信息

- 代码托管：[github.com/TaishanPi-Rockchip](https://github.com/TaishanPi-Rockchip)
- Manifest 分支：`TaishanPi-3-260402`
- SoC：Rockchip RK3576
- 内核版本：Linux 6.1
