"""Opt in the Point Lines studies; never replace the author's layout."""
from pathlib import Path
import json, shutil

OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
path=ROOT/'commons/maps/Point_Lines/map_data.json'
for rel in ['commons/maps/Point_Lines/map_data.json','commons/maps/Point_Lines/final.md']:
    dest=OUT/'before'/rel
    dest.parent.mkdir(parents=True,exist_ok=True)
    if not dest.exists(): shutil.copy2(ROOT/rel,dest)
text=path.read_text(encoding='utf-8-sig')
data=json.loads(text)
protected={
    'player_trace':'Records the visitor; no separate body to break.',
    'laser_measure':'Retains its native measuring/burning tool behaviour.',
    'line_sledgehammer':'Retains its native swinging tool behaviour.',
    'wall_health_station':'Recovery infrastructure stays usable.',
    'health_cross':'Retains its native health/impact behaviour.',
}
coloured={'walk_this_line_marking','street_talker'}
coverage=[]
for z,row in enumerate(data['layers']['interactables']):
    old='\t\t\t'+json.dumps(row,ensure_ascii=False)
    changed=False
    for x,token in enumerate(row):
        name=token.split(':')[0].split('#')[0].strip()
        if not name: continue
        if name in protected:
            coverage.append({'artifact':name,'cell':[x,z],'policy':'native/protected','reason':protected[name]})
            continue
        policy='colour' if name in coloured else 'break'
        if '#reactive:' not in token:
            row[x]=token+f'#reactive:{policy}#rebuild:8'
            if name=='line_black_box': row[x]+='#reaction_target:LineStudy'
            changed=True
        coverage.append({'artifact':name,'cell':[x,z],'policy':policy,'seconds':8})
    if changed:
        assert text.count(old)==1
        text=text.replace(old,'\t\t\t'+json.dumps(row,ensure_ascii=False))
path.write_text(text,encoding='utf-8')
(OUT/'coverage.json').write_text(json.dumps(coverage,indent=2)+'\n',encoding='utf-8')
print('Configured',sum(c['policy']!='native/protected' for c in coverage),'study placements; retained',sum(c['policy']=='native/protected' for c in coverage),'native tools/services. Layout unchanged.')
