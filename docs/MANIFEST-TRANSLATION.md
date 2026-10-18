# build-kit — AviumUI→Waydroid 清单适配记录（2026-10-16）

## 做了什么
把 WayDroid-ATV `lineage-23.2` 的 manifests-36（为 LineageOS 树写的）翻译成 **AviumUI `avium-16.2` 树**可用的 local_manifests。

## 翻译表（ATV remove 名 → AviumUI 真实仓库名）
| ATV 原料名字 | path | AviumUI 实际名 |
|---|---|---|
| platform/external/drm_hwcomposer | external/drm_hwcomposer | platform/external/drm_hwcomposer |
| platform/external/gmmlib | external/gmmlib | platform/external/gmmlib |
| platform/external/libdrm | external/libdrm | platform/external/libdrm |
| platform/external/libva | external/libva | platform/external/libva |
| platform/external/libva-utils | external/libva-utils | platform/external/libva-utils |
| platform/external/mesa3d | external/mesa3d | platform/external/mesa3d |
| platform/external/minigbm | external/minigbm | platform/external/minigbm |
| platform/external/rust/android-crates-io | external/rust/android-crates-io | platform/external/rust/android-crates-io |
| platform/external/rust/ninja-to-soong | external/rust/ninja-to-soong | platform/external/rust/ninja-to-soong |
| LineageOS/android_frameworks_av | frameworks/av | **android_frameworks_av**（avium fork） |
| LineageOS/android_frameworks_base | frameworks/base | **android_frameworks_base**（avium fork） |
| LineageOS/android_frameworks_native | frameworks/native | **android_frameworks_native**（avium fork） |
| LineageOS/android_hardware_interfaces | hardware/interfaces | LineageOS/android_hardware_interfaces |
| LineageOS/android_system_core | system/core | **android_system_core**（avium fork） |
| LineageOS/android_system_vold | system/vold | LineageOS/android_system_vold |
| LineageOS/android_packages_apps_Settings | packages/apps/Settings | **android_packages_apps_Settings**（avium fork） |
| LineageOS/android_packages_apps_TvSettings | packages/apps/TvSettings | LineageOS/android_packages_apps_TvSettings |

17/17 全部命中；02-waydroid 的 37 个仓库路径与 AviumUI 1138 路径**零额外撞车**（无需补充移除项）。

## 方法（可复现）
1. `repo init -u https://github.com/AviumUI/android_manifests -b avium-16.2 --depth=1 --git-lfs`（在 ~/projects/waydroid-build）
2. `repo manifest -o merged-avium.xml` → 得 AviumUI 合并清单（1197 项目）的 path→name 映射
3. LOS 官方 default.xml 做 name→path 桥接，把 ATV removes 名字翻译成 AviumUI 名
4. 校验 02-waydroid 路径交集 → 无额外冲突
5. 写入 `.repo/local_manifests/{00-remotes,01-removes,02-waydroid}.xml`；`repo manifest -o merged-final.xml` 复核

## 结果指纹
- merged-final.xml：1197 项目；8 核心仓库指向 `WayDroid-ATV/android_*`（ghub remote）
- 默认 revision = `refs/heads/lineage-23.2`（与 WayDroid-ATV fork 分支名一致 → 无 revision 条目解析安全）
- 实测：device/waydroid/waydroid、packages/apps/WaydroidUpdater sync OK
