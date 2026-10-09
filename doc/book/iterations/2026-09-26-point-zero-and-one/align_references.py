from pathlib import Path
import copy, hashlib, json
r=Path.cwd();o=Path(__file__).resolve().parent
def read(p):return json.loads((r/p).read_text(encoding='utf-8-sig'))
def write(p,s):(r/p).write_bytes(s.encode('utf-8'))
def js(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def H(p):return hashlib.sha256((r/p).read_bytes()).hexdigest()

p='commons/maps/Point_Zero/final.md'
write(p,(r/p).read_text(encoding='utf-8').replace('This room has to be made again while you are in it.','The view of this room has to be drawn again while you are in it.'))

technical=(o/'before/commons/maps/Point_One/technical.md').read_text(encoding='utf-8')
zero_tech=(r/'commons/maps/Point_Zero/technical.md').read_text(encoding='utf-8')
zero_tech+='\n'+technical[technical.index('## A number before our beginning'):technical.index('## Choose a reference;')]
zero_tech+='''\n## A spatial zero

The origin marker now owns the label “Point zero”, configured through its existing beam label. `Vector3.ZERO` specifies a coordinate-system origin; it does not reset the process counter. The existing removable “you” is retained beside that encounter.
'''
write('commons/maps/Point_Zero/technical.md',zero_tech)
one_tech=(r/'commons/maps/Point_One/technical.md').read_text(encoding='utf-8')
detail=technical[technical.index('## Carry one body between two addresses'):technical.index('## Secondary point and the shared entrance')]
detail=detail.replace('Pick up `interactive_point_origin_force`.','Pick up `point_held`, which contains the production `interactive_point_origin` pickable.')
detail=detail.replace('The changing surface and responses belong to the artifact built around a position.','The black surface stays black while its pickup responses belong to the artifact built around a position.')
detail=detail.replace('`(2,9)` and `(2,11)`','`(2,17)` and `(2,19)`')
one_tech+='\n'+detail+'''\n## Retained alternatives

The invisible-point case and the non-executing code screen remain at (13,13) and (15,15). Their source example `FOCUS = Vector3(0, 1.25, 0)` remains local to the case. The force point is a secondary comparison at (13,14), identified as `point_one_force_return`, so it cannot take over the named coordinate feed. Fontana remains at (12,19), with its own embedded point. The target can accept any eligible point; the cards select only the corridor point.

The pickup label cycles plain coordinates, named X/Y/Z components, a `Vector3(...)` spelling, and no label. The executable match in `interactive_point_origin.gd` is the evidence; its older source-header format descriptions are inaccurate.
'''
write('commons/maps/Point_One/technical.md',one_tech)

for m in ['Point_Zero','Point_One']:
 d=read(f'commons/maps/{m}/map_data.json')
 rows=[]
 for z,row in enumerate(d['layers']['interactables']):
  for x,t in enumerate(row):
   if t.strip():rows.append(f'| `{t.split(":")[0].split("#")[0]}` | ({x}, {z}) | `{t}` |')
 s=f'# {m.replace("_"," ")} — current encounters\n\n26 September 2026. Canonical placement comes from map_data.json. Source cells are not runtime world coordinates.\n\n'
 s+='The opening is now Point_Zero → Point_One → Point_Lines. The first two are separate manuscripts and consecutive museum halls.\n\n'
 s+='| Artifact | Source cell (x,z) | Configuration |\n|---|---|---|\n'+'\n'.join(rows)+'\n'
 if m=='Point_Zero':s+='\nFolding Past is the configured lobby-window view, not a duplicate interactable in the grid. The open shaft surrounds the existing four-metre arrival drop. Point zero is the origin artifact’s label.\n'
 else:s+='\nThe first four conditions are primary comparisons, followed by the coordinate frame and its two readouts, the target, and the 1.3 m diameter pedestal sphere. The case, code screen, force point, Fontana, snap sphere, floating field, radio and street talker remain secondary. The comment box is decoration.\n'
 write(f'commons/maps/{m}/artifacts.md',s)
write('commons/maps/Point_One/encounter-reference.md','''# Point One — encounter reference

The opening text and encounters were split on 26 September 2026. Counter → folding → origin now belongs to [Point Zero](../Point_Zero/final.md). The inherited-work paragraph is preserved there.

Point One follows absence → white surface → white solid → black held sphere → WORLD/LOCAL → target → 1.3 m sphere on a pedestal. The three small spheres have equal 0.14 m radii. A point's name is repeated; the three stations do not share a coordinate.

The held wrapper instantiates the existing XRTools pickable point. Its `coordinate_id` is `point_one_main`. The frame and two cards follow this identity; the secondary force variant has a separate ID. Formatting rounds the report, not the stored position. The target accepts any member of the coordinate-point group within its 0.45 m radius and rearms after departure.

The mathematical point, visible mesh, collision shape and pickup behavior remain different constructions. The final sphere has radius 0.65 m and stands exactly on a 0.75 m pedestal. See [technical.md](technical.md), [artifacts.md](artifacts.md) and the [native review](../../../doc/book/iterations/2026-09-26-point-zero-and-one/index.html) for implementation and evidence.
''')
# Keep the older critical material explicitly as research, with a current entry note.
p='commons/maps/Point_One/critical.md';s=(r/p).read_text(encoding='utf-8')
s=s.replace('## Reading status — 21 September 2026','## Reading status — 26 September 2026',1)
s=s.replace('For this hall, begin the critical inquiry in what can be encountered: inheriting a running system; choosing which code to leave unread; locating an undrawn position; giving it a body; naming the frame behind an address; and making different arrivals count as the same event.', 'The running-system and inherited-work inquiry now opens Point_Zero. Here, begin with absence, a visible surface that permits passage, an identical surface that resists, and a black body that can be held. Then name the frame behind an address and ask how different arrivals count as the same event.')
write(p,s)

p='commons/data/book/primitives.json';d=read(p);one=next(x for x in d['pearls'] if x.get('map')=='Point_One')
closing=next(x for x in one['lines'] if x.get('token')=='point_pedestal')
one['lines'].remove(closing);one['lines'].append(closing);js(p,d)

p='commons/data/museum_core_encounters.json';d=read(p)
for m,tokens,reason in [
 ('Point_Zero',['arrival_shaft','frame_counter_display','folding_past','origin'],'Fall into a running room; folding, inherited work and chosen origin carry the first chapter. The removable you is retained.'),
 ('Point_One',['point_absent','point_visible','point_solid','point_held','coordinate_readout','CoordinateSystem3M','drag_point_target','point_pedestal'],'Separate visibility, collision and pickup before naming coordinates; return to the same name on a 1.3 m diameter sphere. Secondary comparisons remain.')]:
  record=d['rooms'].setdefault(m,{})
  record.update(primary_tokens=tokens,reason=reason,status='revised_native_desktop_checked',sequence='primitives',
   text_path=f'commons/maps/{m}/final.md',text_sha256=H(f'commons/maps/{m}/final.md'),map_sha256=H(f'commons/maps/{m}/map_data.json'),
   learner_verified=False,local_review='doc/book/iterations/2026-09-26-point-zero-and-one/index.html')
js(p,d)

# Refresh only the two new source-derived rows after any local server regeneration.
import sys
sys.path.insert(0,str(r/'tools'));from em_map_halls import derive_row,normalize_row
p='ada_run/em_plan.json';d=read(p);decl=read('commons/data/map_authored.json')['primitives'];old=next(x for x in d['plans'] if x.get('map')=='Point_One')
rows=[]
for i,m in enumerate(['Point_Zero','Point_One']):
 row=derive_row('point zero' if i==0 else old['pearl'],m,old['museum'],i,len(decl),'primitives');normalize_row(row,False,True);rows.append(row)
at=min(i for i,x in enumerate(d['plans']) if x.get('map') in ['Point_Zero','Point_One'])
d['plans']=[x for x in d['plans'] if x.get('map') not in ['Point_Zero','Point_One']]
d['plans'][at:at]=rows
for row in d['plans']:
 if row.get('sequence')=='primitives':row['pearl_index']=decl.index(row['map']);row['pearls_total']=len(decl)
js(p,d)
print('References, core records and opening plan aligned.')
