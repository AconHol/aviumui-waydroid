#!/bin/sh
# Check that the AviumUI Waydroid image is installed and booted.
set -eu

ATT="sudo lxc-attach -P /var/lib/waydroid/lxc -n waydroid --clear-env -- /system/bin/sh -c"
fail=0

getprop() {
    $ATT "getprop $1" 2>/dev/null | tr -d '\r'
}

check() {
    name=$1 expected=$2 got=$3
    if [ "$got" = "$expected" ]; then
        printf '  ok   %-28s %s\n' "$name" "$got"
    else
        printf '  FAIL %-28s got=%s want=%s\n' "$name" "$got" "$expected"
        fail=$((fail + 1))
    fi
}

echo "== image"
check sys.boot_completed 1 "$(getprop sys.boot_completed)"
check ro.build.version.release 16 "$(getprop ro.build.version.release)"
check ro.build.version.sdk 36 "$(getprop ro.build.version.sdk)"

ver=$(getprop ro.avium.version)
case "$ver" in
    AviumUI-16.2*) printf '  ok   %-28s %s\n' ro.avium.version "$ver" ;;
    *)             printf '  FAIL %-28s got=%s\n' ro.avium.version "$ver"; fail=$((fail + 1)) ;;
esac

echo "== processes"
for p in surfaceflinger system_server; do
    pid=$($ATT "pidof $p" 2>/dev/null | tr -d '\r')
    if [ -n "$pid" ]; then printf '  ok   %-28s pid=%s\n' "$p" "$pid"
    else printf '  FAIL %-28s not running\n' "$p"; fail=$((fail + 1)); fi
done

echo "== host"
printf '  info waydroid session: %s\n' "$(sudo /usr/bin/python3 /usr/sbin/waydroid status 2>&1 | awk '/^Session:/{print $2}')"
printf '  info images_path: %s\n' "$(sed -n 's/^images_path *= *//p' /var/lib/waydroid/waydroid.cfg)"

if [ "$fail" -ne 0 ]; then
    echo
    echo "$fail check(s) failed"
    exit 1
fi
echo
echo "all checks passed"
