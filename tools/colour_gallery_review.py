"""Capture the eight actual Colour halls through the isolated museum runner."""
from pathlib import Path
import json, shutil, subprocess, sys

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-06-colour-rooms-from-the-plates'
MAPS=json.loads((ROOT/'commons/maps/sequences/color.json').read_text())['sequences']['color']['maps']
phase=sys.argv[1]
for room in (sys.argv[2:] or MAPS):
    result=subprocess.run([sys.executable,'-X','utf8','tools/run_encounter_probe.py',room,'--sequence','color','--render','--probe','tools/probes/colour_gallery.gd'],cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8')
    source=ROOT/'ada_run/encounter_pilot'/room
    dest=OUT/phase/room;dest.mkdir(parents=True,exist_ok=True)
    for name in ['room.png','report.json','source_manifest.json','stdout.log']:
        if (source/name).exists():shutil.copy2(source/name,dest/name)
    print(room,phase,'exit',result.returncode,flush=True)
    if result.returncode:print(result.stdout,flush=True);raise SystemExit(result.returncode)
