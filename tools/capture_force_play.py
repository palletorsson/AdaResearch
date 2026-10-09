"""Capture each changed production Forces hall, retaining its evidence separately."""
from pathlib import Path
import json,sys
from review_force_halls import run
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-07-forces-extravaganza'
plan=json.loads((ROOT/'commons/artifacts/force_halls/curation.json').read_text(encoding='utf8'))
maps=sys.argv[1:] or [r['map'] for r in plan['halls'] if r['map'] not in ['Vectors_Act1_WhatAVectorIs','Change_Choreography']]
results=[]
for m in maps:
    print('CAPTURING '+m,flush=True)
    results.append(run(m,'tools/probes/force_play_museum.gd',OUT/'after'/m,True))
    (OUT/'capture-status.json').write_text(json.dumps(results,indent=2),encoding='utf8')
print(json.dumps(results,indent=2))
raise SystemExit(0 if all(r['passed'] for r in results) else 1)
