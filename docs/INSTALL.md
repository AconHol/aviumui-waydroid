# 安装

## 前置

- 已安装并初始化过 Waydroid（`waydroid init` 至少跑过一次），`waydroid-container` 服务可用
- 磁盘剩余 ≥ 6 GiB（镜像 2.9 GiB + 解压/换镜像时的余量）
- 宿主为 x86_64 Linux

## 一键

```sh
./scripts/install.sh ./images
```

参数是包含 `system.img` 与 `vendor.img` 的目录。脚本做四件事：

1. 用 `SHA256SUMS` 校验镜像
2. 复制到 `/etc/waydroid-extra/images/`
3. `waydroid init -i /etc/waydroid-extra/images -f`
4. 重启 `waydroid-container`，等 `sys.boot_completed=1`

## 手动

```sh
sudo mkdir -p /etc/waydroid-extra/images
sudo cp system.img vendor.img /etc/waydroid-extra/images/
sudo waydroid init -i /etc/waydroid-extra/images -f
sudo systemctl restart waydroid-container
waydroid show-full-ui
```

`waydroid init` 会把 `images_path` 写进 `/var/lib/waydroid/waydroid.cfg`。

## 验收

```sh
./scripts/verify.sh
```

检查项：`sys.boot_completed=1`、`ro.build.version.release=16`、
`ro.avium.version` 非空、`surfaceflinger` 存活、默认桌面能解析到 Avium 的 HOME。

也可以手工看：

```sh
sudo lxc-attach -P /var/lib/waydroid/lxc -n waydroid --clear-env -- \
    /system/bin/sh -c 'getprop sys.boot_completed; getprop ro.avium.version'
```

## 换回官方镜像

```sh
sudo waydroid init -f          # 重新从 OTA 拉官方 lineage-20 镜像
```

## 注意

- 换镜像会清空 userdata 层：已装应用、Magisk 模块、应用数据都会丢。
- `images_path` 一旦改到 `/etc/waydroid-extra/images`，之后 `waydroid init -f` 会继续用这个路径；
  要回官方镜像记得同时把 `images_path` 改回 `/var/lib/waydroid/images`。
- 如果启动卡住，先看 `sudo journalctl -u waydroid-container -n 100` 与容器内
  `logcat -b crash`（HWC / SurfaceFlinger 崩了通常在这里）。
