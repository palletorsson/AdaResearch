"""Append the trial court, preserving the existing field encounter and passage."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
path = ROOT / 'commons/maps/Vectors_Act5_ForceAsPlace/map_data.json'
data = json.loads(path.read_text(encoding='utf-8'))
assert data['map_info']['dimensions']['depth'] == 24, 'Already expanded or source changed'
for kind, rows in data['layers'].items():
    for z in range(24, 50):
        if kind == 'structure':
            row = ['w' if x in (0,15) or (z == 49 and x not in (6,7,8)) else '1' for x in range(16)]
        else:
            row = [''] * 16
        rows.append(row)
data['layers']['utilities'][20][8] = ''
data['layers']['structure'][20][8] = '1'
data['layers']['utilities'][48][8] = 't:Vectors_Act1_WhatAVectorIs'
data['layers']['structure'][48][8] = '1' # museum ignores teleporter utilities; keep the passage walkable
data['layers']['interactables'][37][8] = 'force_capability_lab#pin:1#plinth:0'
data['map_info']['dimensions']['depth'] = 50
data['map_info']['museum']['sculpture_clear_rects'].append([1,24,14,48]) # inclusive end cells, not width/depth
data['map_info']['description'] += ' Beyond the field: a trial court where the familiar point, cube, slope and moving platform meet thrust, launches, a ring mortar, a hinge, springs and drag.'
data['map_info']['metadata']['learning_objectives'].extend([
    'Distinguish trigger-held acceleration from a launch velocity and from retained momentum',
    'Compare intended landing with actual contact; reuse the aftermath',
    'Observe a hinge constraint, restoring force and drag acting on familiar bodies'
])
data['map_info']['metadata']['estimated_time'] = '12-20 minutes'
data['map_info']['version'] = 'vf-field-and-capability-court-2026-10-07'
path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Appended 26 rows; original field retained; exit moved to row 48.')
