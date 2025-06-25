#!/system/bin/sh

MODPATH="/data/adb/modules/UniversalHider"
DENYLIST="$MODPATH/denylist.txt"
PROPSFILE="$MODPATH/props.txt"
LOGFILE="$MODPATH/hide.log"
DATE() { date '+%Y-%m-%d %H:%M:%S'; }

log() {
  echo "[$(DATE)] $1" >> "$LOGFILE"
}

log "[INFO] UniversalHider service started"

# Потенциально конфликтующие модули
CONFLICT_MODULES="SafetyNetFix Shamiko MagiskHide riru"
for mod in $CONFLICT_MODULES; do
  if [ -d "/data/adb/modules/$mod" ]; then
    log "[WARN] Potential conflict detected: $mod"

    # При желании, можно автоматически деактивировать модуль
    if [ "$mod" = "Shamiko" ]; then
      log "[ERROR] Shamiko detected! Disabling UniversalHider to avoid issues."
      # touch "$MODPATH/disable" Автовыключение модуля при найденых конфликтующих модулях
      exit 1
    fi
  fi
done

# Определяем среду: KernelSU или Magisk
if command -v ksu >/dev/null 2>&1; then
  MODE="KernelSU"
elif [ -d /sbin/.magisk ] || command -v magisk >/dev/null 2>&1; then
  MODE="Magisk"
else
  log "[ERROR] Neither Magisk nor KernelSU detected. Exiting."
  exit 1
fi

log "[INFO] Running in $MODE mode"

# Загружаем список пакетов
PACKAGES=$(grep -vE '^\s*(#|$)' "$DENYLIST")

# Применение пропсов
apply_props() {
  pkg="$1"
  log "[INFO] Applying props for: $pkg"

  resetprop --package "$pkg" ro.debuggable 0
  resetprop --package "$pkg" ro.secure 1
  resetprop --package "$pkg" ro.boot.slot_suffix ""
  resetprop --package "$pkg" ro.build.tags release-keys
  resetprop --package "$pkg" ro.build.type user
  resetprop --package "$pkg" ro.kernel.qemu 0

  if [ -f "$PROPSFILE" ]; then
    grep -vE '^\s*(#|$)' "$PROPSFILE" | while read -r line; do
      p_pkg=$(echo "$line" | cut -d' ' -f1)
      p_key=$(echo "$line" | cut -d' ' -f2)
      p_val=$(echo "$line" | cut -d' ' -f3-)
      if [ "$p_pkg" = "$pkg" ]; then
        resetprop --package "$pkg" "$p_key" "$p_val"
        log "[INFO] Custom prop set: $p_key = $p_val"
      fi
    done
  fi
}

# Основной цикл обработки пакетов
for pkg in $PACKAGES; do
  log "[INFO] Processing package: $pkg"
  if [ "$MODE" = "KernelSU" ]; then
    ksu --hide "$pkg" >> "$LOGFILE" 2>&1
    log "[INFO] ksu --hide applied to $pkg"
  fi
  apply_props "$pkg"
done

log "[✓] UniversalHider completed successfully"
