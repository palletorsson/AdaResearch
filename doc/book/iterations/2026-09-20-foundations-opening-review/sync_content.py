from pathlib import Path
import hashlib, json
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
def read(p): return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def write(p,d): (ROOT/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

p='commons/artifacts/registry/alternative_geometries.json';d=read(p);a=d['artifacts']['triangle_curvature_workbench']
a['description']='A reachable HOST slider selects three example triangles: segments on a plane, great-circle edges on a sphere, or geodesics in a Poincare disk. Corner angles are measured between analytic geodesic tangents; the readout shows their sum and excess or deficit relative to 180 degrees. Three model choices, not seven curvature magnitudes. No independent curvature integral or theorem proof is computed.'
a['capacity']='Compare measured triangle angles across three host geometries'
if 'foundationscrisis' not in a['map_sequences']: a['map_sequences'].append('foundationscrisis')
write(p,d)
p='commons/artifacts/registry/foundations.json';d=read(p);a=d['artifacts']['euclid_postulates_plaque']
a['interactions']=['NEXT cycles postulates and GOLD toggles emphasis when lesson_controls is enabled','Legacy desktop mouse cycling when lesson_controls is disabled']
a['parameters']['lesson_controls']='Opt-in physical NEXT and GOLD buttons; enabled in Euclid_Parallel'
write(p,d)

p='commons/data/artifact_roles.json';d=read(p);d['roles']['Euclid_Parallel']['angle_sum_triangle']='primary';write(p,d)
p='commons/data/museum_core_encounters.json';d=read(p)
for room in ['Euclid_Parallel','NonEuclidean_Spaces']:
 r=d['rooms'][room]
 if room=='Euclid_Parallel':
  r['primary_tokens']=['euclid_postulates_plaque','parallel_lines','angle_sum_triangle']
  r['reason']='Restore the colonnade and physical plaque controls; the printed triangle supplies the comparison with measured angles in the next hall.'
 else:
  r['reason']='Keep all six exhibits; make the three host models measurable and distinguish the disk boundary from the Riemann sphere point at infinity.'
 r['status']='encounter_and_text_revised'
 r['learner_verified']=False
 r['review_evidence']='doc/book/iterations/2026-09-20-foundations-opening-review/SUMMARY.md'
 for key,file in [('text_sha256','final.md'),('map_sha256','map_data.json')]:r[key]=hashlib.sha256((ROOT/'commons/maps'/room/file).read_bytes()).hexdigest()
write(p,d)

p='commons/data/book/foundationscrisis.json';d=read(p)
speech={
 'Euclid_Parallel':('euclid_postulates_plaque',{
  'euclid_postulates_plaque':'Press NEXT. Which sentence needs the gold? Press GOLD and read it again.',
  'parallel_lines':'Unequal gaps between three parallel lines do not break their parallelism.',
  'angle_sum_triangle':'The sum is 180 degrees. Did the labels measure these corners?',
 }),
 'NonEuclidean_Spaces':('triangle_curvature_workbench',{
  'triangle_curvature_workbench':'Choose PLANE, DISK or SPHERE. Predict the angle sum before moving HOST.',
  'curvature_slider':'This slider bends its own sketch. It does not control the other exhibits.',
  'elliptic_surface':'A dome-like picture invites a question about measurement; its silhouette is not the metric.',
  'poincare_disk':'The drawing has a rim. In the hyperbolic metric, that boundary is infinitely far away.',
  'hyperbolic_surface':'A saddle changes how straightness looks. What path would stay straight within it?',
  'riemann_sphere':'The complex plane gains one point at infinity. Walking around this model is another journey.',
 })}
for pearl in d['pearls']:
 if pearl['map'] not in speech: continue
 hero,lines=speech[pearl['map']];pearl['hero']=hero
 for ln in pearl['lines']:
  if ln.get('token') in lines:
   ln.update(text=lines[ln['token']],by='hand')
   ln.pop('note',None);ln.pop('note_src',None)
 for token,text in lines.items():
  if not any(ln.get('token')==token for ln in pearl['lines']):pearl['lines'].insert(0,dict(token=token,text=text,by='hand'))
write(p,d)
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 d=read(p);node=next(n for n in d['trunk'] if n['node']=='foundationscrisis')
 for pearl in node['pearls']:
  if pearl.get('map') in speech:
   hero,lines=speech[pearl['map']];pearl.update(hero=hero,says=lines,says_by={t:'hand' for t in lines})
 # Hand overrides must agree, without replacing token or routing edits.
 for pearl in d.get('hand_pearls',{}).get('foundationscrisis',[]):
  if pearl.get('map') in speech:
   hero,lines=speech[pearl['map']];pearl.update(hero=hero,says=lines,says_by={t:'hand' for t in lines})
 write(p,d)
