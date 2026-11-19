#!/usr/bin/env bash
# PvP side-swap demo: heroes on the RIGHT facing LEFT (universal facing).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${BASH_DEMO_OUT:-/opt/cursor/artifacts/pvp_side_swap}"
mkdir -p "$OUT"
export BASH_SWAP_SIDES=1
export BASH_DEMO_QUIT=1
export BASH_DEMO_SECONDS="${BASH_DEMO_SECONDS:-18}"
export BASH_SCREENSHOT_PATH="$OUT/pvp_swap_battle.png"
cd "$ROOT"
godot --headless --path . --rendering-driver opengl3 \
  "res://scenes/battle/BattlePrototype.tscn" 2>&1 | tee "$OUT/pvp_swap_log.txt" | tail -40
echo "[PVP-SWAP] screenshot → $BASH_SCREENSHOT_PATH"
