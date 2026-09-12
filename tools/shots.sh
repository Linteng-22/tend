#!/usr/bin/env bash
# 在模拟器里把 Tend 的每一页拍下来。
#
# 不靠点坐标：启动的时候带一个 route 参数，想拍哪一页就开哪一页。
# 分辨率、密度、字号换一代手机就变，点坐标的脚本活不过一个月，这个能。
#
# 这个环境里一定会遇到的几件事，脚本里都处理了：
#   1. 刚开机的头一两分钟，SystemUI 自己会卡出一个模态弹窗，把后面每张都挡死。
#      → 开机完先等一会儿，每拍之前清一次系统弹窗（一条 broadcast，不是 dumpsys）。
#   2. 偶尔拍到全黑的帧（Compose 还没画完 / 屏幕刚醒）。
#      → 拍之前先量屏幕亮度，太黑就再等一轮，最多三次。
#   3. 冷启动会先显示启动页（白底一个小 T），它比黑屏更骗人——亮度是满的。
#      → 顺手量一下页头那一条有多黑：有标题说明已经是内容页，全白就是还在启动页。
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
adb shell settings put global window_animation_scale 0 >/dev/null 2>&1 || true
adb shell settings put global transition_animation_scale 0 >/dev/null 2>&1 || true
adb shell settings put global animator_duration_scale 0 >/dev/null 2>&1 || true

adb install -r "$APK" > /dev/null

clear_system_dialogs() {
  adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS >/dev/null 2>&1 || true
}

# 量两样东西：整屏平均亮度（黑帧 ≈ 0，白底 ≈ 240+），
# 以及页头那一条里「深色像素」占多少（内容页有标题，启动页是一片白）。
# 自己解原始帧，不引第三方工具——runner 上有什么不该由脚本猜。
screen_probe() {
  adb exec-out screencap > /tmp/probe.raw 2>/dev/null || { echo "255 1"; return; }
  python3 - <<'PY'
d = open('/tmp/probe.raw', 'rb').read()
if len(d) < 64:
    print("255 1")
else:
    w = int.from_bytes(d[0:4], 'little')
    h = int.from_bytes(d[4:8], 'little')
    body = d[12:]
    stride = w * 4

    total = 0
    count = 0
    for y in range(0, h, max(1, h // 60)):
        row = body[y * stride:(y + 1) * stride]
        if len(row) < stride:
            continue
        for x in range(0, w, max(1, w // 40)):
            i = x * 4
            total += (row[i] * 299 + row[i + 1] * 587 + row[i + 2] * 114) // 1000
            count += 1
    luma = total // count if count else 255

    dark = 0
    head = 0
    for y in range(h * 10 // 100, h * 24 // 100, max(1, h // 200)):
        row = body[y * stride:(y + 1) * stride]
        if len(row) < stride:
            continue
        for x in range(0, w, max(1, w // 60)):
            i = x * 4
            value = (row[i] * 299 + row[i + 1] * 587 + row[i + 2] * 114) // 1000
            head += 1
            if value < 170:
                dark += 1
    print(str(luma) + " " + str(dark / head if head else 0))
PY
}

shoot() {
  local name="$1"
  shift
  adb shell am force-stop "$PACKAGE" || true
  clear_system_dialogs
  adb shell am start -n "$ACTIVITY" "$@" > /dev/null

  local luma=0
  local head=0
  for attempt in 1 2 3; do
    # 冷启动要连 Compose 一起起。模拟器上四秒只够看到启动页，第一次多等一点。
    if [ "$attempt" = "1" ]; then sleep 9; else sleep 5; fi
    clear_system_dialogs
    sleep 1
    read -r luma head <<< "$(screen_probe)"
    if [ "$luma" -gt 20 ] && awk "BEGIN{exit !($head > 0.004)}"; then break; fi
    echo "  ${name}：还没到内容页（亮度 ${luma}，页头深色占比 ${head}），再等一轮"
    adb shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true
  done

  adb exec-out screencap -p > "shots/${name}.png"
  echo "拍好了 ${name}（亮度 ${luma}，页头深色占比 ${head}）"
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
