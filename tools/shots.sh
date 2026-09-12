#!/usr/bin/env bash
# 在模拟器里把 Tend 的每一页拍下来。
#
# 不靠点坐标：启动的时候带一个 route 参数，想拍哪一页就开哪一页。
# 分辨率、密度、字号换一代手机就变，点坐标的脚本活不过一个月，这个能。
#
# 唯一要小心的东西：模拟器刚开机的头一两分钟，SystemUI 自己会卡出一个
# 「System UI isn't responding」的模态弹窗，它会把后面每一张都挡死。
# 所以开机完先等一会儿，每拍之前再清一次系统弹窗。清弹窗要用便宜的调用
# （一条 broadcast），不能用 dumpsys 那种重活——在没加速的模拟器上它自己
# 就能把系统拖到更卡。
set -e

APK="${1:?用法：bash tools/shots.sh <apk>}"
PACKAGE=com.jiaweisi.tend
ACTIVITY="${PACKAGE}/.MainActivity"

mkdir -p shots

echo "等系统开机完成……"
adb wait-for-device
for i in $(seq 1 150); do
  [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && break
  sleep 2
done

# 开机完成 ≠ 系统起来了。SystemUI 还在忙着起各种东西，这时候就开拍必挨弹窗。
sleep 40

adb shell settings put global window_animation_scale 0 >/dev/null 2>&1 || true
adb shell settings put global transition_animation_scale 0 >/dev/null 2>&1 || true
adb shell settings put global animator_duration_scale 0 >/dev/null 2>&1 || true

adb install -r "$APK" > /dev/null

clear_system_dialogs() {
  adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS >/dev/null 2>&1 || true
}

shoot() {
  local name="$1"
  shift
  adb shell am force-stop "$PACKAGE" || true
  clear_system_dialogs
  adb shell am start -n "$ACTIVITY" "$@" > /dev/null
  # 冷启动要连 Compose 一起起。模拟器上 4 秒只够看到启动页。
  sleep 6
  clear_system_dialogs
  sleep 1
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
