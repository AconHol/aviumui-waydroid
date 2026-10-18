# 从源码构建

> 基线流程来自 [Waydroid 官方文档](https://docs.waydro.id/development/compile-waydroid-lineage-os-based-images)
> 与 [WayDroid-ATV](https://github.com/WayDroid-ATV)。本文件只写 **AviumUI 树上要改的地方**。

## 机器要求

- Linux x86_64，≥ 16 GiB 内存（`-j8` 时），**≥ 300 GiB 空闲磁盘**
- 完整一轮约 3–6 小时（视 CPU/磁盘）
- 依赖：`repo`、`git-lfs`、`ccache`、`python3-mako`、`python3-yaml`、`bc bison flex gperf lzop pngcrush
  rsync schedtool squashfs-tools xsltproc zip zlib1g-dev libelf-dev liblz4-tool` 等

Arch：

```sh
yay -S lineageos-devel python-mako python-yaml
```

Ubuntu/Debian：

```sh
sudo apt install bc bison build-essential ccache curl flex g++-multilib gcc-multilib git git-lfs \
  gnupg gperf imagemagick lib32readline-dev lib32z1-dev libelf-dev liblz4-tool libsdl1.2-dev \
  libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip \
  zlib1g-dev lib32ncurses5-dev lib32z1 libncurses5 python3-setuptools python3-mako python3-yaml
```

## 1. 拉清单

```sh
mkdir -p ~/avium-waydroid && cd ~/avium-waydroid
repo init -u https://github.com/AviumUI/android_manifests -b avium-16.2 --depth=1 --git-lfs
```

## 2. 放本地清单

把本仓库 `manifests/` 下三个文件拷进 `.repo/local_manifests/`：

| 文件 | 作用 |
|---|---|
| `00-remotes.xml` | 追加 WayDroid-ATV 的 remote |
| `01-removes.xml` | 移除 17 个会被 Waydroid 版本替换的仓库（**已按 AviumUI 真实仓库名翻译**，见 `docs/MANIFEST-TRANSLATION.md`） |
| `02-waydroid-nogapps.xml` | 加入 35 个 Waydroid 专属仓库（`device/waydroid`、`hardware/waydroid` 等），**不含 GApps** —— 默认用这个 |
| `02-waydroid.xml` | 同上但含 `vendor/gapps` + `vendor/gapps_tv`（仅限本机自用，产物不要公开分发） |

```sh
mkdir -p .repo/local_manifests
cp /path/to/aviumui-waydroid/manifests/00-remotes.xml \
   /path/to/aviumui-waydroid/manifests/01-removes.xml \
   /path/to/aviumui-waydroid/manifests/02-waydroid-nogapps.xml \
   .repo/local_manifests/
repo sync -j8 --force-sync
```

验收：`repo list | wc -l` 约为 **1195** 个工程（无 GApps，比含 GApps 的 1197 少 2 个）；`device/waydroid`、`hardware/waydroid`、
`frameworks/waydroid`、8 个 fork 仓库都要在位。

## 3. 打 Waydroid 补丁

AviumUI 树的补丁来自 WayDroid-ATV 的 `base-patches-36`，共 **51 个**：

```sh
. build/envsetup.sh
apply-waydroid-patches
```

实测 **49 个自动落位**，2 个需要处理（细节见 `docs/PATCH-MATRIX.md`）：

1. `build/soong: 0002-Fix-building-on-A16.patch` —— `scripts/check_boot_jars/package_allowed_list.txt`
   单 hunk 与 AviumUI 的 IFAA/支付条目冲突 → 手工合并（两边条目都保留）
2. `lineage-sdk: 0001-trust-Suppress-SELinux-warning.patch` —— 目标文件
   `TrustInterfaceService.java` 在 AviumUI 的 fork 里不存在 → 跳过该补丁

## 4. freeform 补丁（AviumUI 专属）

AviumUI 的 freeform 子系统被替换 fork 带走，构建会在
`isFreeformDisplayId` 处失败。打上本仓库的补丁：

```sh
cd frameworks/base
git am /path/to/aviumui-waydroid/patches/freeform-port/0001-FreeForm-inject-freeform-services.patch
cd -
```

## 5. 构建

```sh
lunch lineage_waydroid_x86_64-bp4a-userdebug
make systemimage vendorimage -j$(nproc)
```

> ⚠️ `lunch` 必须是三段式 `lineage_waydroid_x86_64-bp4a-userdebug`；
> 只写两段会选错发布线。构建 ID 实测 `BP4A.251205.006`（发布镜像为 `BP4A.260205.001`）。

产物：

```
out/target/product/waydroid_x86_64/system.img   # EROFS，~2.3 GiB
out/target/product/waydroid_x86_64/vendor.img   # ext4，~0.8 GiB
```

## 6. 无 GApps

默认清单 `02-waydroid-nogapps.xml` 不含 `vendor/gapps`、`vendor/gapps_tv`，因此产物天然没有
Google 服务。若你本机自用想带上，把 `02-waydroid.xml` 换进去重新 sync 即可 —— 但**不要公开分发**
那种镜像（Google 服务条款限制）。

## 7. 装机验证

```sh
sudo cp out/target/product/waydroid_x86_64/{system,vendor}.img /etc/waydroid-extra/images/
sudo waydroid init -i /etc/waydroid-extra/images -f
sudo systemctl restart waydroid-container
```

首次启动后 `adb connect 192.168.240.112:5555`，`adb shell getprop sys.boot_completed` 应为 `1`。

## 常见问题

| 现象 | 原因 / 处理 |
|---|---|
| `repo sync` 报 manifest 里仓库不存在 | 用了未翻译的 WayDroid-ATV `01-removes.xml`；用本仓库 `manifests/` 里的版本 |
| 构建在 `isFreeformDisplayId` 缺符号处失败 | 没打 `patches/freeform-port/` |
| 卡在 `check_boot_jars` | `0002-Fix-building-on-A16` 冲突没合并 |
| 镜像起来但黑屏 | 先确认宿主合成器能不能导入容器缓冲；NVIDIA 老卡请用软件渲染（见 README「已知限制」） |
