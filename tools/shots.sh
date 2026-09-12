#!/usr/bin/env bash
# 在模拟器里把 Tend 的每一页拍下来。
#
# 不靠点坐标：启动的时候带一个 route 参数，想拍哪一页就开哪一页。
# 分辨率、密度、字号换一代手机就变，点坐标的脚本活不过一个月，这个能。
#
# 这个环境里一定会遇到的几件事，脚本里都处理了：
#   1. 刚开机的头一两分钟，SystemUI 自己会卡出一个模态弹窗，把后面每张都挡死。
#      → 开机完先等一会儿，每拍之前清一次系统弹窗（一条 broadcast，不是 dumpsys）。
#   2. 拍到全黑的帧（屏幕自己睡了 / Compose 还没画完）。
#      → 拍之前先量屏幕，拍完再量一次；两次都得是内容页才算数。
#   3. 冷启动会先显示启动页（白底一个小 T），它比黑屏更骗人——亮度是满的。
#      → 顺手量一下页头那一条有多黑：有标题说明已经是内容页，全白就是还在启动页。
#
# 上一版栽在「量不到就当正常」：探针一失败就返回 255，于是黑帧被当成好图收下。
# 这一版反过来——拿不准就重拍，宁可贵一点，不留坏图。
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

adb shell svc power stayon true >/dev/null 2>&1 || true
adb shell settings put system screen_off_timeout 2147483647 >/dev/null 2>&1 || true
adb shell settings put global window_animation_scale 0 >/dev/null 2>&1 || true
adb shell settings put global transition_animation_scale 0 >/dev/null 2>&1 || true
adb shell settings put global animator_duration_scale 0 >/dev/null 2>&1 || true

adb install -r "$APK" > /dev/null

keep_awake() {
  adb shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true
  adb shell svc power stayon true >/dev/null 2>&1 || true
}

clear_system_dialogs() {
  adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS >/dev/null 2>&1 || true
}

# 量两样东西：整屏平均亮度（黑帧 ≈ 0，白底 ≈ 240+），
# 以及页头那一条里「深色像素」占多少（内容页有标题，启动页是一片白）。
#
# 自己解原始帧。原始帧的头不固定：有的版本 12 字节，有的 16 字节（多一个色彩空间），
# 所以不猜——用「总长度 - 高度 x 行宽」反推头有多长，反推不出来就当量不到。
# 探针的正文写成独立脚本：python 的缩进和 shell 的引号放一起太容易出错。

cat > /tmp/probe.py <<'PY'
import sys

data = open('/tmp/probe.raw', 'rb').read()
if len(data) < 64:
    print("0 0")
    sys.exit()

width = int.from_bytes(data[0:4], 'little')
height = int.from_bytes(data[4:8], 'little')
stride = width * 4
if width <= 0 or height <= 0 or stride * height > len(data):
    print("0 0")
    sys.exit()

header = len(data) - height * stride
if header < 0 or header > 4096:
    print("0 0")
    sys.exit()
body = data[header:]

total = 0
count = 0
for y in range(0, height, max(1, height // 60)):
    row = body[y * stride:(y + 1) * stride]
    if len(row) < stride:
        continue
    for x in range(0, width, max(1, width // 40)):
        i = x * 4
        total += (row[i] * 299 + row[i + 1] * 587 + row[i + 2] * 114) // 1000
        count += 1
luma = total // count if count else 0

dark = 0
head = 0
for y in range(height * 10 // 100, height * 24 // 100, max(1, height // 200)):
    row = body[y * stride:(y + 1) * stride]
    if len(row) < stride:
        continue
    for x in range(0, width, max(1, width // 60)):
        i = x * 4
        value = (row[i] * 299 + row[i + 1] * 587 + row[i + 2] * 114) // 1000
        head += 1
        if value < 170:
            dark += 1
print(str(luma) + " " + str(dark / head if head else 0))
PY

screen_probe() {
  adb exec-out screencap > /tmp/probe.raw 2>/dev/null || { echo "0 0"; return; }
  python3 /tmp/probe.py
}

# 量到内容页了吗。拿不准一律当「没到」，宁可多等一轮。
looks_like_content() {
  local luma="$1"
  local head="$2"
  [ "$luma" -gt 25 ] || return 1
  awk "BEGIN{exit !($head > 0.004)}" || return 1
  return 0
}

shoot() {
  local name="$1"
  shift
  adb shell am force-stop "$PACKAGE" || true
  keep_awake
  clear_system_dialogs
  adb shell am start -n "$ACTIVITY" "$@" > /dev/null

  local luma=0
  local head=0
  local settled=0
  for attempt in 1 2 3 4; do
    # 冷启动要连 Compose 一起起。模拟器上四秒只够看到启动页，第一次多等一点。
    if [ "$attempt" = "1" ]; then sleep 9; else sleep 5; fi
    keep_awake
    clear_system_dialogs
    sleep 1
    read -r luma head <<< "$(screen_probe)"
    if looks_like_content "$luma" "$head"; then settled=1; break; fi
    echo "  ${name}：还没到内容页（亮度 ${luma}，页头深色占比 ${head}），再等一轮"
  done

  # 拍完再量一次。这一张要交出去，所以它自己也得过一遍同一道关。
  for attempt in 1 2 3; do
    adb exec-out screencap -p > "shots/${name}.png"
    read -r luma head <<< "$(screen_probe)"
    if looks_like_content "$luma" "$head"; then
      echo "拍好了 ${name}（亮度 ${luma}，页头深色占比 ${head}）"
      return 0
    fi
    echo "  ${name}：这一张不像内容页，重拍"
    keep_awake
    sleep 3
  done

  echo "  ${name}：三次都没拿到像样的帧，先留着这一张"
  return 0
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

# 崩没崩，日志说了算。截图归截图，这一条是给「装上去能用吗」留的凭据。
echo "—— 崩溃日志 ——"
adb logcat -d -b crash > /tmp/crash.log 2>/dev/null || true
if grep -q "$PACKAGE" /tmp/crash.log; then
  echo "有崩溃记录："
  grep -A 12 "$PACKAGE" /tmp/crash.log | head -60
  exit 1
fi
echo "没有崩溃记录。"

echo "—— 应用自己的异常 ——"
adb logcat -d 2>/dev/null | grep -c "FATAL EXCEPTION" || true
