import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
def read(p): return json.loads((ROOT/p).read_text(encoding='utf-8'))
def write(p,v): (ROOT/p).write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p='commons/maps/Random_Walk/map_data.json'
m=read(p)
assert m['layers']['interactables'][8][6] in ('', ' ', '0', 0, None), m['layers']['interactables'][8][6]
m['layers']['interactables'][8][6]='random_draw_dot:0'
write(p,m)
p='commons/artifacts/registry/randomness.json'; r=read(p)
r['artifacts']['random_draw_dot']={'lookup_name':'random_draw_dot','name':'Hand + chance','scene':'res://commons/artifacts/randomness_space/random_draw_dot.tscn','category':'procedural','sequence':'randomness','map_sequences':['randomness'],'map_ready':True,'include_in_map_data':True,'description':'The original drawing grip with a visible tip accumulating bounded random steps around the moving hand.'}
write(p,r)
p='commons/data/artifact_roles.json'; r=read(p)
r['roles']['Random_Walk']['random_draw_dot']='primary'
if 'random_draw_dot' not in r['order']['Random_Walk']['primary']: r['order']['Random_Walk']['primary'].append('random_draw_dot')
write(p,r)
p=ROOT/'commons/maps/Random_Walk/final.md'
s=p.read_text(encoding='utf-8')
s+='''

<!-- @random_draw_dot -->

## A hand with company

Pick up the drawing dot. Move your hand slowly across the space, then hold it still. The small green tip keeps wandering. What part of this line belongs to your movement?

This is the grip from Trace with one addition. Thirty times per second, while you hold it, a random direction adds a small step to an offset. The next step starts from the offset already reached:

```gdscript
walk_offset = (walk_offset + direction * STEP_SIZE).limit_length(RADIUS)
tip.global_position = _grab_point.global_position + walk_offset
```

Your hand carries the origin; the tip walks around it. Each proposed step is 1.2 centimetres, and the offset cannot exceed 25 centimetres. At that boundary, the program shortens an outward proposal. Its freedom has a radius.

Press HAND / RANDOM to clear the line and draw with the hand alone. Switch back and try the same gesture. The point-count display still counts retained samples, as it did in Trace. The random clock proposes thirty steps a second, but the visible trail is sampled by the drawing process; a stalled frame can miss intermediate positions.

CLEAR / REPLAY restores the random seed and clears the trail. The random steps can repeat. Your hand need not. Let go and the wandering stops: this encounter gives chance movement only while someone holds it.
'''
p.write_text(s,encoding='utf-8')
import sys
sys.path.insert(0,str(ROOT/'tools'))
from em_map_halls import derive_row
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
    plan=read(p)
    for i,row in enumerate(plan['plans']):
        if row['map']=='Random_Walk': plan['plans'][i]=derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],'randomness')
    write(p,plan)
