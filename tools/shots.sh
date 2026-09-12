#!/usr/bin/env bash
# 在模拟器里把 Tend 的每一页拍下来。
#
# 不靠点坐标：启动的时候带一个 route 参数，想拍哪一页就开哪一页。
# 分辨率、密度、字号换一代手机就变，点坐标的脚本活不过一个月，这个能。
set -e

APK="${1:?用法：bash tools/shots.sh <apk>}"
PACKAGE=com.jiaweisi.tend
ACTIVITY="${PACKAGE}/.MainActivity"

mkdir -p shots
adb install -r "$APK" > /dev/null

shoot() {
  local name="$1"
  shift
  adb shell am force-stop "$PACKAGE" || true
  adb shell am start -n "$ACTIVITY" "$@" > /dev/null
  sleep 4
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
