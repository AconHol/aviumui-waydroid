# AviumUI 16.2 for Waydroid (x86_64)

把 **AviumUI 16.2**（Android 16 QPR2 / SDK 36，LineageOS 派生）移植成 **Waydroid** 可用的
`system.img` + `vendor.img`，在 Linux 桌面上以容器方式跑完整的 Avium 桌面。

本仓库包含：移植用的本地清单、补丁、构建与安装脚本、移植记录；镜像本体发布在 Releases。

| 项目 | 值 |
|---|---|
| 版本标识 | `AviumUI-16.2.2-waydroid_x86_64` |
| Android | 16 (SDK 36)，`BP4A.260205.001` |
| 架构 | x86_64（容器）/ 宿主 Linux x86_64 |
| system.img | EROFS，1.75 GiB（1,876,254,720 字节） |
| vendor.img | ext4，754 MiB（790,847,488 字节） |
| 上游 | `AviumUI/android_manifests` @ `avium-16.2` + WayDroid-ATV `lineage-23.2` 的 51 个补丁 |
| 状态 | 可启动；Avium 桌面 / 设置 / 多窗口正常 |
| GApps | **不含**（本项目的构建与分发配置为无 GApps） |

## 这是什么

AviumUI 是 LineageOS 派生的中文定制 ROM。本项目把它"搬进"Waydroid：

- **清单适配**：WayDroid-ATV 的 `base-patches-36` 是按 LineageOS 仓库写的，AviumUI 大量仓库换了名字
  （`frameworks/base` → `android_frameworks_base` 等）。这里给出翻译后的 `local_manifests`（17 条替换）。
- **补丁适配**：51 个 Waydroid 补丁里 49 个可直接落位，2 个需要手工合并（见 `docs/PATCH-MATRIX.md`）。
- **freeform 修复**：AviumUI 的 freeform 子系统被替换 fork 带走，导致 `isFreeformDisplayId` 缺失；
  用 `patches/freeform-port/` 里的补丁打桩（语义等价）。
- **产物**：`system.img`（EROFS）+ `vendor.img`（ext4），直接喂给 `waydroid init`。

本仓库**只开源移植配方**（清单、补丁、脚本、文档），不随仓库分发镜像本体；
按 `docs/BUILD.md` 在本地构建出的镜像**不含 GApps**。

## 安装

镜像已发布在 [Releases](https://github.com/AconHol/aviumui-waydroid/releases/latest)（`system.img`、`vendor.img`、`SHA256SUMS`）。
下载后：

```sh
mkdir -p images && mv system.img vendor.img SHA256SUMS images/
git clone https://github.com/AconHol/aviumui-waydroid.git
cd aviumui-waydroid
./scripts/install.sh ./images
```

也可以自己按 `docs/BUILD.md` 构建（构建产物同样不含 GApps），再走同样的安装流程：

```sh
git clone https://github.com/AconHol/aviumui-waydroid.git
cd aviumui-waydroid
./scripts/install.sh ./images      # images/ 里放你构建出的 system.img、vendor.img
```

脚本会校验 `SHA256SUMS`、把镜像装到 `/etc/waydroid-extra/images` 并 `waydroid init -i <dir> -f`。
也可以手动：

```sh
sudo mkdir -p /etc/waydroid-extra/images
sudo cp images/system.img images/vendor.img /etc/waydroid-extra/images/
sudo waydroid init -i /etc/waydroid-extra/images -f
sudo systemctl restart waydroid-container
```

> 换镜像会清掉 userdata 层（Magisk 模块、已装应用都在那一层）。

## 构建

见 [`docs/BUILD.md`](docs/BUILD.md)。要点：

```sh
repo init -u https://github.com/AviumUI/android_manifests -b avium-16.2 --depth=1 --git-lfs
# 放入 manifests/ 里的三个 local_manifest（用 02-waydroid-nogapps.xml）
repo sync -j8 --force-sync
. build/envsetup.sh && apply-waydroid-patches
lunch lineage_waydroid_x86_64-bp4a-userdebug
make systemimage vendorimage -j$(nproc)
```

## 已知限制

- **NVIDIA 老卡（Maxwell / Pascal）上没有 GPU 上屏**：Android 侧 NVK 渲染正常
  （`GLES: ANGLE (NVIDIA ... (NVK))`、`nvidia-smi` 能看到 surfaceflinger/composer），
  但 Waydroid 的 HWC 会把 NVK 的 block-linear dma-buf 直接附到宿主 Wayland 表面；
  闭源 GL 采样时抛 `Xid 13 TEX LAYOUT`，整机合成器冻结。改用软件渲染即正常。
  完整排查记录见 [`docs/PORT-NOTES.md`](docs/PORT-NOTES.md)。
- 首次启动比官方镜像慢（系统分区更大、EROFS 解压）。
- 只做了 x86_64；arm64 未验证。

## 许可与合规

- 本仓库的脚本、清单、文档：**MIT**（见 `LICENSE`）。
- 构建产物包含 LineageOS（Apache-2.0 等）与 AviumUI 组件，各自遵循其上游许可证。
- 本项目的清单、脚本与文档按 **无 GApps** 配置（`manifests/02-waydroid-nogapps.xml` 不含
  `vendor/gapps`、`vendor/gapps_tv`）。请勿把 GApps 打进再分发的镜像：那受 Google 服务条款限制。
- 需要在本机自用 GApps 时，可改用 `manifests/02-waydroid.xml`（含 `vendor/gapps`）自行构建，
  但由此产生的镜像不应公开分发。
- 镜像里其余组件（LineageOS、AviumUI）遵循各自上游许可证。

## 致谢
