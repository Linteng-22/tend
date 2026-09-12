#!/usr/bin/env bash
# 在模拟器里把 Tend 的每一页拍下来。
#
# 不靠点坐标：启动的时候带一个 route 参数，想拍哪一页就开哪一页。
# 分辨率、密度、字号换一代手机就变，点坐标的脚本活不过一个月，这个能。
#
# 模拟器（尤其没 KVM 加速的）开机头几分钟 SystemUI 会自己弹
# 「System UI isn't responding」，那个弹窗是模态的，会把后面每一张都挡死。
# 所以这里拍之前先清系统弹窗，再确认前台真的是 Tend，否则重试。
set -e

APK="${1:?用法：bash tools/shots.sh <apk>}"
PACKAGE=com.jiaweisi.tend
ACTIVITY="${PACKAGE}/.MainActivity"

mkdir -p shots

echo "等系统开机完成……"
adb wait-for-device
for i in $(seq 1 180); do
  [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && break
  sleep 2
done
# 开机完成后 SystemUI 还在忙着起各种东西，这时候拍必挨弹窗。
sleep 25

adb shell settings put global window_animation_scale 0 >/dev/null 2>&1 || true
adb shell settings put global transition_animation_scale 0 >/dev/null 2>&1 || true
adb shell settings put global animator_duration_scale 0 >/dev/null 2>&1 || true
adb shell settings put secure immersive_mode_confirmations confirmed >/dev/null 2>&1 || true

adb install -r "$APK" > /dev/null

focused() {
  adb shell dumpsys window 2>/dev/null | grep -m1 -E 'mCurrentFocus' || true
}

# 只有当前台不是我们自己的时候才动手，免得把 App 自己按回去。
dismiss_system_dialogs() {
  local f
  f="$(focused)"
  case "$f" in
    *"$PACKAGE"*) return 0 ;;
  esac
  adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS >/dev/null 2>&1 || true
  adb shell input keyevent KEYCODE_BACK >/dev/null 2>&1 || true
  adb shell input keyevent KEYCODE_HOME  >/dev/null 2>&1 || true
  sleep 2
}

wait_for_tend() {
  local i f
  for i in $(seq 1 30); do
    f="$(focused)"
    case "$f" in
      *"$PACKAGE"*) return 0 ;;
    esac
    echo "  前台还是 $f，清一下弹窗"
    dismiss_system_dialogs
    sleep 2
  done
  return 1
}

shoot() {
  local name="$1"
  shift
  adb shell am force-stop "$PACKAGE" || true
  dismiss_system_dialogs
  adb shell am start -n "$ACTIVITY" "$@" > /dev/null
  # 冷启动要连 Compose 一起起，模拟器上 4 秒只够看到启动页。
  sleep 7
  wait_for_tend || echo "警告：${name} 没等到 Tend 在前台，照拍，回头人工看一眼"
  sleep 2
  dismiss_system_dialogs
  adb exec-out screencap -p > "shots/${name}.png"
  echo "拍好了 ${name}"
}

shoot 01-chat
shoot 02-drawer --ez drawer true
shoot 03-conversations --es route conversations
shoot 04-settings --es route settings
shoot 05-channels --es route channels
shoot 06-persona --es route persona
shoot 07-voice --es route voice
shoot 08-capability --es route capability
shoot 09-library --es route library
shoot 10-memory --es route memory
shoot 11-skills --es route skills
shoot 12-account --es route account
shoot 13-backup --es route backup
shoot 14-security --es route security
shoot 15-about --es route about

ls -l shots
