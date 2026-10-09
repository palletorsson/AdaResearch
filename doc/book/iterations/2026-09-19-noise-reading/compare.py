"""Present the four proposed interventions alongside the actual current passages."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];BASE=HERE.relative_to(ROOT).as_posix()
changes=json.loads((HERE/'proposals.json').read_text(encoding='utf-8'));notes=json.loads((HERE/'notes.json').read_text(encoding='utf-8'))
applied=(HERE/'applied.json').exists()
items=[dict(title='Keep the code that makes a discovery possible',description='The point keeps losing its depth because a line keeps writing zero. REMAP lets a dark patch return without changing its sampled value. Those details belong in the encounter. The proposed changes below make room around such moments; five chapters and the blob-culture passage are preserved.',report=BASE+'/READING.md',report_label='Reading decisions for all nine halls')]
for p in changes:
 items.append(dict(title=p['map'].replace('_',' ')+' · '+p['title'],description=p['reason'],before=p['before'],after=p['after'],text_kind='book passage',after_label='Proposed',report=BASE+'/proposed/'+p['map']+'.md',report_label='Read the complete proposed chapter, including notes'))
 if applied:
  items[-1].update(after_label='Applied',report='commons/maps/'+p['map']+'/final.md',report_label='Read the current chapter, including notes')
items.append(dict(title='The details remain available',description='Seed-stream limitations, exact voxel counts, screen-record code and the terrain recipe/measurements move into optional notes. The relevant historical measurements were already recorded on 13 September; no new runtime experiment was needed for these editorial decisions.',report=BASE+'/NOTES.md',report_label='Read the proposed notes and evidence links'))
record=dict(status='four editorial proposals · live chapters unchanged',summary='Read the encounter first, let a short piece of code reveal its operation, and leave room for what the reader wants to try next. These are proposed passages for reading together, not applied manuscript or museum changes.',items=items)
if applied:
 record.update(status='four editorial revisions applied · five chapters preserved',summary='The four reading proposals have been applied to final.md. Core code and the blob-culture passage remain; optional notes carry the exact measurements. Original passages and the accepted versions are paired below. No artifact or room changes accompany this editorial pass.')
(ROOT/'doc/book/iterations/2026-09-19-review-comparison/noise.json').write_text(json.dumps(record,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
out=['# Noise — proposed optional notes','', 'These accompany the proposed chapters. They preserve technical qualifications outside the main reading rhythm.','']
if applied:out=['# Noise — optional notes','', 'These notes now accompany the four revised chapters. They preserve technical qualifications outside the main reading rhythm.','']
for name,entries in notes.items():
 out+=['## '+name.replace('_',' '),'']
 for key,value in entries:out+=['**'+key+'** — '+value,'']
out+=['[Dated evidence and reading decisions](READING.md)','']
(HERE/'NOTES.md').write_text('\n'.join(out),encoding='utf-8')
print('Comparison prepared with explicit '+('Applied' if applied else 'Proposed')+' labels and separate optional notes.')
