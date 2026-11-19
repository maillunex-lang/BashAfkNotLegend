#!/usr/bin/env bash
# Record dual-archer ice shot demo to MP4 via Xvfb + ffmpeg.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARTIFACT_DIR="${ARTIFACT_DIR:-/opt/cursor/artifacts}"
mkdir -p "$ARTIFACT_DIR"
OUT_MP4="${1:-$ARTIFACT_DIR/anime_dual_archer_ice_bear.mp4}"
OUT_PNG="${ARTIFACT_DIR}/anime_dual_archer_ice.png"
DISPLAY_NUM="${DISPLAY_NUM:-98}"
export DISPLAY=":${DISPLAY_NUM}"
SECONDS_DEMO="${ARPG_DEMO_SECONDS:-16}"

# Ensure Xvfb
if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
  Xvfb "$DISPLAY" -screen 0 1280x720x24 -ac +extension GLX +render -noreset &
  sleep 0.8
fi

cd "$ROOT"
# Import assets (first run)
godot --headless --editor --quit-after 3 2>/tmp/godot_import.log || true
# Wait a bit more for .import if needed
if [[ ! -f assets/models/archer_with_bow.glb.import ]]; then
  godot --headless --import 2>>/tmp/godot_import.log || true
fi

export ARPG_DEMO_QUIT=1
export ARPG_DEMO_SECONDS="$SECONDS_DEMO"
export ARPG_SCREENSHOT_PATH="$OUT_PNG"

# Start recording slightly before godot window is up
FFMPEG_LOG=/tmp/ffmpeg_ice_demo.log
rm -f /tmp/godot_ice_demo.log
ffmpeg -y -f x11grab -video_size 1280x720 -framerate 30 -i "${DISPLAY}.0" \
  -c:v libx264 -pix_fmt yuv420p -preset veryfast -crf 20 \
  "$OUT_MP4" >"$FFMPEG_LOG" 2>&1 &
FFMPEG_PID=$!
sleep 0.6

godot --path "$ROOT" --resolution 1280x720 --windowed \
  2>/tmp/godot_ice_demo.log &
GODOT_PID=$!

# Wait for godot to quit (demo timer) or timeout
WAIT=$((SECONDS_DEMO + 25))
for i in $(seq 1 "$WAIT"); do
  if ! kill -0 "$GODOT_PID" 2>/dev/null; then
    break
  fi
  sleep 1
done
if kill -0 "$GODOT_PID" 2>/dev/null; then
  kill "$GODOT_PID" 2>/dev/null || true
fi
wait "$GODOT_PID" 2>/dev/null || true
sleep 0.4
kill -INT "$FFMPEG_PID" 2>/dev/null || true
wait "$FFMPEG_PID" 2>/dev/null || true

ls -lh "$OUT_MP4" "$OUT_PNG" 2>/dev/null || true
echo "DONE video=$OUT_MP4"
tail -30 /tmp/godot_ice_demo.log || true
