"""Seat only the newly restored objects, using native Godot bounds, for curation."""
import json, math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; V=ROOT/'commons/void'
stage=Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
bounds=json.loads((stage/'inventory-bounds.json').read_text())
boxes={(v['floor'],v['id']):v['bounds'] for v in bounds}
p=V/'rooms.json'; before=p.read_bytes(); rooms=json.loads(before)
frame=json.loads((V/'layout.json').read_text())
report=[]
def overlap(a,b): return max(0,min(a[2],b[2])-max(a[0],b[0]))*max(0,min(a[3],b[3])-max(a[1],b[1]))
def rect(x,z,w,d): return [x-w/2,z-d/2,x+w/2,z+d/2]
for i,floor in enumerate(rooms['floors']):
    forbidden=[rect(s['x'],0,frame['shaft_width']+.7,frame['shaft_depth']+.7) for s in frame['shafts']]
    forbidden += [rect(x,z,1.65,1.65) for x in frame['column_x'] for z in frame['column_z']]
    forbidden += [rect(-6,4.5,2.0,2.0)]
    occupied=[rect(*a.get('position',[0,0]),2.2,2.2) for a in floor['artifacts']+floor.get('copies',[]) if not a['id'].startswith('museum-')]
    occupied += [rect(*a['position'],2.0,2.0) for a in floor.get('props',[])]
    new=[a for a in floor['artifacts'] if a['id'].startswith('museum-')]
    for a in sorted(new,key=lambda a:max(boxes[i,a['id']][3:]),reverse=True):
        b=boxes[i,a['id']]; factor=min(1,4.4/max(b[3],.01),4.4/max(b[5],.01),4.8/max(b[4],.01))
        # Bounds include the current scale. Save the same geometry at a usable size.
        old=a['scale']; a['scale']=round(max(.05,old*factor),5); ratio=a['scale']/old
        x,y,z,w,h,d=[v*ratio for v in b]
        a['height']=round(max(0,min(2.5,-y+.035)),4)
        # Raise centred, compact objects to a comfortable grasp height.
        if h<.7 and a['artifact'] not in ['do_not_cross_barrier','concrete_barrier','walk_this_line_marking','redline','player_trace']:
            a['height']=round(max(a['height'],.85-y),4)
        w=max(w,.65)+.3;d=max(d,.65)+.3
        candidates=[]
        for cx in [n*.5 for n in range(-40,41)]:
            for cz in [n*.5 for n in range(-16,17)]:
                box=rect(cx,cz,w,d)
                if box[0]<-20.7 or box[2]>20.7 or box[1]<-8.7 or box[3]>8.7: continue
                if any(overlap(box,q)>0 for q in forbidden): continue
                score=sum(overlap(box,q) for q in occupied)*100 + (0 if abs(cx)>13 else 2) + abs(cx-a['position'][0])*.01+abs(cz-a['position'][1])*.01
                candidates.append((score,cx,cz,box))
        if not candidates: raise RuntimeError('Cannot safely place '+a['id'])
        score,cx,cz,box=min(candidates)
        # The mesh need not be centred on its scene origin.
        a['position']=[round(cx-(x+b[3]*ratio/2),4),round(cz-(z+b[5]*ratio/2),4)]
        a['station']=('N' if cz<0 else 'S')+('W' if cx<0 else 'E')
        occupied.append(box)
        report.append({'floor':i,'id':a['id'],'artifact':a['artifact'],'scale':a['scale'],'position':a['position'],'height':a['height'],'placement_overlap':score>=100})
if p.read_bytes()!=before: raise RuntimeError('Layout changed while fitting; rerun.')
p.write_text(json.dumps(rooms,indent=2)+'\n')
out=ROOT/'doc/book/iterations/2026-10-19-museum-objects-and-landings'
(out/'fitted-objects.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'fitted':len(report),'reduced':sum(a['scale']<1 for a in report),'curation_overlap':sum(a['placement_overlap'] for a in report)}))
