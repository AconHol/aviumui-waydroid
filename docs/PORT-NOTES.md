# 移植记录

按时间顺序记录把 AviumUI 16.2 搬进 Waydroid 的过程与踩到的坑。

## 1. 路线选择

AviumUI `avium-16.2` = Android 16 QPR2 / SDK 36，LineageOS 派生。Waydroid 官方镜像仍是
lineage-20（A13），所以整棵树要按 WayDroid-ATV 的 `lineage-23.2` 基线改造。

两条路：

- **省事路线（采用）**：被 Waydroid 替换的 8 个核心仓库直接用 WayDroid-ATV 的 fork，
  AviumUI 在这些仓库里的定制暂时放弃（保真化作为第二步）。
- 保真路线：逐个把 Waydroid 的改动 rebase 到 AviumUI 的 fork 上——工时数天，暂不做。

GApps：按 `vendor/gapps @ baklava` 带上。

## 2. 清单适配（最大的一块）

WayDroid-ATV 的 `base-patches-36` 与 manifest 是按 LineageOS 仓库名写的，AviumUI 把大量仓库换成了
自己的 fork，例如：

```
frameworks/base        → android_frameworks_base
frameworks/native      → android_frameworks_native
system/core            → android_system_core
packages/apps/Settings → android_packages_apps_Settings
```

`manifests/01-removes.xml` 里的 17 条全部按 AviumUI 真实仓库名重写（对照表见
`docs/MANIFEST-TRANSLATION.md`）。最终 `merged-final.xml` = **1197 个工程**，
`repo sync -j8 --force-sync` 零错误。

## 3. 补丁预演

先 dry-run 了 51 个补丁（`apply-waydroid-patches` 的清单）：

| 结果 | 数量 | 备注 |
|---|---|---|
| 干净落位 | 49 | |
| 冲突 | 2 | 见下 |
| 跳过 | 1 | `lineage-sdk 0001`（目标文件在 AviumUI fork 中不存在） |

两个冲突：

1. `build/soong 0002-Fix-building-on-A16` —— `scripts/check_boot_jars/package_allowed_list.txt`
   单 hunk 撞 AviumUI 的 IFAA/支付条目 → 手工合并，两边都保留。
2. `lineage-sdk 0001-trust-Suppress-SELinux-warning` —— `TrustInterfaceService.java` 不存在 → 跳过。

完整矩阵见 `docs/PATCH-MATRIX.md`。

## 4. 构建

`lunch` 必须是三段式：

```sh
lunch lineage_waydroid_x86_64-bp4a-userdebug
make systemimage vendorimage
```

实测踩到的坑：

- **`isFreeformDisplayId` 未定义**：AviumUI 的 freeform 子系统随替换 fork 一起被移走，
  但 `frameworks/base` 里仍有调用 → 用 `patches/freeform-port/0001` 打桩（语义等价）。
- 第一次 `lunch` 用两段式会选到错误发布线，`make` 在 soong 阶段就炸。
- 产物：`system.img`（EROFS，2.26 GiB）+ `vendor.img`（ext4，790 MiB）。

最终镜像属性：

```
ro.build.version.release = 16
ro.build.version.sdk     = 36
ro.build.display.id      = BP4A.260205.001
ro.avium.version         = AviumUI-16.2.2-waydroid_x86_64
ro.product.model         = Pixel 7 Pro
```

## 5. GPU 加速（未解决，已归档）

宿主是 NVIDIA Quadro K620（Maxwell，2 GiB，BAR1 256 MiB）+ niri。自建了 nvidia-prolapse 的
NVK（Mesa 26.2.5）栈并塞进容器，Android 侧渲染**确实跑在 GPU 上**：

- `dumpsys SurfaceFlinger | grep ^GLES` → `ANGLE (NVIDIA ... Quadro K620 (NVK NV117)), OpenGL ES 3.2.0`
- `nvidia-smi` 进程表里能看到容器内的 `surfaceflinger` / `composer` / `allocator`

但**上屏失败**，根因是跨驱动的缓冲布局契约：

1. Waydroid 的 HWC 把 NVK 分配的 **block-linear dma-buf** 直接附到宿主 Wayland 表面；
2. 宿主合成器（闭源 GL）采样时 GPU 抛
   `NvRM: Xid 13 Graphics TEX Exception (TEX LAYOUT)`，异常记在**合成器自己的通道**上；
3. 通道一死，合成器之后每帧 `Failed to bind Framebuffer`，整屏冻结，只能重启合成器。

不是显存不够（崩时显存 ~1.3 GiB/2 GiB，利用率 60–80%）。

试过的绕法都不成立：

| 方案 | 结果 |
|---|---|
| wrapper 强制 LINEAR 分配 | 不再抛异常，但 SF 的渲染不落进缓冲（画面是 VRAM 残留） |
| 改 HWC 走 wl_shm 拷贝（自建 HWC，3 个补丁） | 崩在 `libhwc2on1adapter` ABI、NVK `vk_meta_copy_image_to_buffer`、`GraphicBuffer` 析构三处 |
| scrcpy 走 H.264 上屏 | 能显示，但没有原生窗口就没有输入面（Waydroid 的触摸由 HWC 的 Wayland seat 注入） |

结论：**在这台机器上 GPU 加速与原生窗口二选一**。要彻底解决得让宿主也用 NVK
（nouveau + Mesa，同源 dma-buf 零拷贝），属于整机驱动改造，未做。

## 6. 已知问题

- 首次启动较慢（EROFS + GApps 初始化）。
- 换镜像会清 userdata（Magisk 模块、已装应用）。
- `vendor.img` 曾为扩容 +64 MiB 并内含一个被 init 拒绝的跨 treble override，
  已回滚为原版（`b8cc3c2d…`）。
