#!/bin/bash
# Run ONE Waves/Chance/Noise probe under the watchdog, rendered, with the window parked
# off-screen (automated windows stay hidden), and only after inspecting the active-process
# condition (the user:// lock; never two live instances).
#
#   bash tools/run_wcn_probe.sh <intro|random|noise|pendulum|sine> [live]
#
#   (default)  the SceneTree probe:  --script res://commons/testing/probe_wcn_<x>.gd
#   live       project startup:      res://commons/testing/probe_live.tscn -- --probe=<x>
#              (autoloads present, XR Tools pickables compile; outputs carry a _live suffix)
#
# THE PROCESS CONDITION (2026-09-10, after Astra's runtime review): every Godot process
# is inventoried by PID, command line, working set and age. A process is LIVE, and stops
# the launch, unless ALL of these hold: it was started headless with --script, it has no
# window, its working set is under 50 MB and it is older than 30 minutes — the signature
# of a hung probe, which holds no lock (measured: the headless reload probe completed
# beside PID 2780). A failed or empty inventory query stops the launch. Nothing is ever
# terminated here. Every launch writes the inventory it saw to the log.
set -u
cd "$(dirname "$0")/.." || exit 3
GODOT="C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"
MODE="${2:-script}"
case "${1:-}" in
  intro)    MAP=WaveFunctions_Intro;      EXPECT=probe_intro;             SCRIPT=probe_wcn_intro ;;
  random)   MAP=Random_Definition;        EXPECT=probe_random_definition; SCRIPT=probe_wcn_random_definition ;;
  noise)    MAP=Noise_Perlin_Simplex;     EXPECT=probe_noise_pair;        SCRIPT=probe_wcn_noise_pair ;;
  pendulum) MAP=WaveFunctions_Pendulum;   EXPECT=probe_pendulum;          SCRIPT=probe_wcn_pendulum ;;
  sine)     MAP=WaveFunctions_Sine_Space; EXPECT=probe_sine_space;        SCRIPT=probe_wcn_sine_space ;;
  effect)   MAP=WaveFunctions_Effect_Sound; EXPECT=probe_effect_sound;    SCRIPT=probe_wcn_effect_sound ;;
  air)      MAP=WaveFunctions_AirMusic;   EXPECT=probe_air_music;       SCRIPT=probe_wcn_air_music ;;
  synth)    MAP=WaveFunctions_Synthesis_Lab; EXPECT=probe_synthesis_lab; SCRIPT=probe_wcn_synthesis_lab ;;
  entropy)  MAP=Random_Entropy;              EXPECT=probe_entropy;       SCRIPT=probe_wcn_entropy ;;
  entropy_once) MAP=Random_Entropy;          EXPECT=probe_entropy_buildonce; SCRIPT=probe_wcn_entropy_buildonce ;;
  remove)   MAP=Random_Remove;               EXPECT=probe_remove;        SCRIPT=probe_wcn_remove ;;
  walk)     MAP=Random_Walk;                 EXPECT=probe_walk;          SCRIPT=probe_wcn_walk ;;
  gauss)    MAP=Random_Gaussian;             EXPECT=probe_gaussian;      SCRIPT=probe_wcn_gaussian ;;
  mush)     MAP=Random_Mushrooms;            EXPECT=probe_mushrooms;     SCRIPT=probe_wcn_mushrooms ;;
  game)     MAP=Random_Game;                  EXPECT=probe_game;          SCRIPT=probe_wcn_game ;;
  points)   MAP=Random_Noise_Types;          EXPECT=probe_points;        SCRIPT=probe_wcn_points ;;
  columns)  MAP=Noise_Columns;               EXPECT=probe_columns;       SCRIPT=probe_wcn_columns ;;
  torus)    MAP=Noise_One;                   EXPECT=probe_torus;         SCRIPT=probe_wcn_torus ;;
  voxel)    MAP=Noise_Voxel;                 EXPECT=probe_voxel;         SCRIPT=probe_wcn_voxel ;;
  wall)     MAP=Noise_6_Wall;                EXPECT=probe_wall;          SCRIPT=probe_wcn_wall ;;
  *) echo "usage: $0 intro|random|noise|pendulum|sine|effect|air|synth|entropy|entropy_once|remove|walk|gauss|mush|game|points|columns|torus|voxel|wall [live]"; exit 3 ;;
esac
OUT="ada_run/waves_chance_noise/$MAP"
SUFFIX=""; [ "$MODE" = "live" ] && SUFFIX="_live"
LOG="$OUT/${EXPECT}${SUFFIX}.log"
ENGINE_LOG="$OUT/${EXPECT}${SUFFIX}_engine.log"
mkdir -p "$OUT"

# ── inventory: PID, working set (KB), creation date, command line ──────────────────────
INV=$(wmic process where "name like 'Godot%'" get processid,workingsetsize,creationdate,commandline /format:csv 2>/dev/null | tr -d '\r' | grep -i "godot")
if [ $? -ne 0 ] && tasklist 2>/dev/null | grep -qi godot; then
  echo "[$1] REFUSED: the process inventory failed while tasklist shows a Godot process"; exit 2
fi
NOW=$(date +%s)
LIVE=0
echo "[$1] process inventory at $(date +%H:%M:%S):" | tee "$LOG"
while IFS= read -r row; do
  [ -z "$row" ] && continue
  # csv: Node,CommandLine,CreationDate,ProcessId,WorkingSetSize — read the last three from
  # the RIGHT: a command line can carry a comma (the editor launches its play instance with
  # --position X,Y), which shifted the columns on 2026-09-10 (fail-safe: still LIVE, wrong pid)
  cmd=$(echo "$row" | awk -F, '{s=""; for(i=2;i<=NF-3;i++) s=s (i>2?",":"") $i; print s}')
  created=$(echo "$row" | awk -F, '{print $(NF-2)}' | cut -c1-14)
  pid=$(echo "$row" | awk -F, '{print $(NF-1)}')
  ws=$(echo "$row" | awk -F, '{print $NF}')
  age_min=$(( (NOW - $(date -d "${created:0:8} ${created:8:2}:${created:10:2}:${created:12:2}" +%s 2>/dev/null || echo $NOW)) / 60 ))
  ws_mb=$(( ${ws:-0} / 1048576 ))
  # STRICT (2026-09-11, Astra: low memory and process age do not establish that a process
  # holds no lock): every Godot process blocks a launch. The inventory is printed so a
  # human can decide what a leftover is; nothing is terminated here.
  verdict="LIVE (blocks the launch)"
  LIVE=1
  echo "  pid $pid  ${ws_mb} MB  ${age_min} min  $verdict  :: $(echo "$cmd" | cut -c1-120)" | tee -a "$LOG"
done <<< "$INV"
if [ "$LIVE" = "1" ]; then
  echo "[$1] REFUSED: a live Godot instance is running; not starting a second one" | tee -a "$LOG"; exit 2
fi

rm -f "$OUT/${EXPECT}${SUFFIX}.json"
echo "[$1] start $(date +%H:%M:%S) ($MODE) -> $LOG" | tee -a "$LOG"
if [ "$MODE" = "live" ]; then
  python tools/godot_watchdog.py --expect="$OUT/${EXPECT}${SUFFIX}.json" --grace=180 --stall=30 -- \
    "$GODOT" --rendering-method gl_compatibility --position 4000,4000 --resolution 1280x720 \
    --path . --xr-mode off --log-file "$ENGINE_LOG" res://commons/testing/probe_live.tscn -- --probe="${SCRIPT#probe_wcn_}" --capture >> "$LOG" 2>&1
else
  python tools/godot_watchdog.py --expect="$OUT/${EXPECT}${SUFFIX}.json" --grace=180 --stall=30 -- \
    "$GODOT" --rendering-method gl_compatibility --position 4000,4000 --resolution 1280x720 \
    --path . --xr-mode off --log-file "$ENGINE_LOG" --script "res://commons/testing/${SCRIPT}.gd" -- --capture >> "$LOG" 2>&1
fi
RC=$?
echo "[$1] exit $RC at $(date +%H:%M:%S)" | tee -a "$LOG"
grep -c "SCRIPT ERROR" "$ENGINE_LOG" 2>/dev/null | sed 's/^/  script errors in engine log: /'
ls -la "$OUT" | grep -E "${EXPECT}${SUFFIX}.*\.(json|png)" | head
exit $RC
