#!/system/bin/sh

MODPATH="/data/adb/modules/UniversalHider"
DENYLIST="$MODPATH/denylist.txt"
PROPSFILE="$MODPATH/props.txt"
LOGFILE="$MODPATH/hide.log"

[ -f "$DENYLIST" ] && grep -vE '^\s*(#|$)' "$DENYLIST" | while read -r pkg; do
    resetprop --package "$pkg" ro.debuggable 1
    resetprop --package "$pkg" ro.secure 0
    resetprop --package "$pkg" ro.build.tags test-keys
    resetprop --package "$pkg" ro.build.type userdebug
    resetprop --package "$pkg" ro.kernel.qemu 1
done

rm -f "$LOGFILE"
echo "[*] UniversalHider: настройки сброшены."
