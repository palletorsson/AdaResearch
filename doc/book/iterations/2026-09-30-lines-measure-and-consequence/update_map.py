from pathlib import Path
import json, re
ROOT = Path(__file__).resolve().parents[4]
p = ROOT / 'commons/maps/Point_Lines/map_data.json'
d = json.loads(p.read_text(encoding='utf-8'))
cells = d['layers']['interactables']
for z in (29, 31, 33):
    cells[z][12] = 'anamorphic_cross:0:0#plinth:0#pin:1#passage:1#bar_len_m:2.5#cross_height_m:1.2#damage_per_tick:14#tick_interval:0.6#reactive:break#rebuild:8'
for z in (30, 32, 34):
    cells[z][12] = 'health_cross:0:0#plinth:0#pin:1#passage:1#arm_m:0.8#hover_m:1.2#boost:21#take_below:1#respawn:8#color:bdebdc'
d['map_info']['metadata']['n_artifacts'] = sum(bool(c.strip()) for row in cells for c in row)
d['documentation']['summary'] = 'Measure a segment, connect two points to open a barrier, walk a straight instruction, rearrange lines, then pass through harm and recovery.'
d['documentation']['layout'] = 'Keep the authored 27 by 37 plan: black box at (2,2), connect-the-dots at (8,2), barrier at (11,2), basin stripe at (9,7), open four-view gallery at (13,17). The exit corridor occupies x=11..13, z=28..35. Six stations at x=12, z=29..34 alternate X damage and + recovery; exit (12,36).'
d['documentation']['encounters'] = ['black box: vary a segment and read its length', 'connect the dots: connection opens the barrier', 'walk this line: compare stripe and player trace', 'four views: plus/X, parallels, verticals and grid/depth', 'held laser: measure, dwell, break, wait for return', 'follow this line into the wall', 'exit: X hurts, + heals, three pairs']
d['subtitles']['opening'] = 'Take one end of the line. What changes when its length stays the same?'
text = json.dumps(d, ensure_ascii=False, indent='\t') + '\n'
text = re.sub(r'\[\n\s*"(?:[^"\\]|\\.)*"(?:,\n\s*"(?:[^"\\]|\\.)*")*\n\s*\]', lambda m: json.dumps(json.loads(m[0]),ensure_ascii=False), text)
p.write_text(text,encoding='utf-8')
