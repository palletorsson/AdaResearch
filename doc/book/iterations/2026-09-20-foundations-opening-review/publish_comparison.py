from pathlib import Path
import json
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
PAGE=HERE.parent/'2026-09-19-review-comparison'
PREFIX=HERE.relative_to(ROOT).as_posix()
def para(room,start,old=False):
 p=(HERE/'before' if old else ROOT)/'commons/maps'/room/'final.md'
 return next(s for s in p.read_text(encoding='utf-8').split('\n\n') if s.startswith(start))
review={
 'status':'opening two halls revised; six chapters await their focused pass',
 'summary':'What did 180 degrees depend on? Euclid returns to the museum route, with physical controls for reading and removing the gold emphasis. The next hall compares measured angles on a plane, a sphere and a Poincare disk. Its former seven-value curvature dial concealed only three geometries; the revised encounter names those three models and measures their corners correctly. All existing artifact families remain.',
 'items':[
  {'title':'A statement becomes something we can ask again',
   'description':'The plaque now offers NEXT and GOLD at 1.05 m. Its colonnade and supporting artifacts return, repositioned around the central walk. The printed-angle triangle becomes a primary comparison: the next hall measures what this one labels. No secondary artifact is removed.',
   'images':[PREFIX+'/euclid-colonnade.png',PREFIX+'/euclid-fifth.png'],
   'captions':['The restored Euclid hall, looking along its central approach.','The fifth postulate, with NEXT and GOLD below the plaque.'],
   'image_note':'Current Godot museum captures, not before/after versions. Selected collision-body approaches pass. The test walker is hidden for photographs; museum artifacts remain visible. Tracked hands and headset reading are untested.',
   'text_kind':'book — Euclid',
   'before':para('Euclid_Parallel','So let\'s break the branch.',True),
   'after':para('Euclid_Parallel','Now press GOLD.'),
   'report':PREFIX+'/final.diff','report_label':'Exact changes to both manuscripts'},
  {'title':'Three hosts; three measurements',
   'description':'HOST selects plane, sphere or disk. The surface sits behind the console and tilts towards the visitor so the controls do not cover its triangle. The displayed angles come from analytic edge tangents. Independent spherical and hyperbolic formulas agree with these example sums: 180.0, 202.1 and 103.1 degrees. The bench illustrates a relation; it does not independently verify a curvature integral or prove Gauss–Bonnet.',
   'images':[PREFIX+'/curvature-plane.png',PREFIX+'/curvature-sphere.png',PREFIX+'/curvature-disk.png'],
   'captions':['PLANE · straight segments, 180.0 degrees.','SPHERE · great-circle edges, 202.1 degrees.','DISK · hyperbolic geodesics, 103.1 degrees.'],
   'image_note':'Three states of the revised workbench in the actual museum, from the same camera at 1.70 m. These are separate example triangles, not an unchanged triangle transported between spaces. The collision-test walker is hidden for photographs.',
   'text_kind':'book — Non-Euclidean Spaces',
   'before':para('NonEuclidean_Spaces','The previous room',True),
   'after':'\n\n'.join(para('NonEuclidean_Spaces',p) for p in ['Start with PLANE','Move to SPHERE','Now try DISK']),
   'report':PREFIX+'/model-checks.json','report_label':'Control signals and independent angle checks'},
  {'title':'Keep the invitation; distinguish what each artifact can establish',
   'description':'Bowing a line in a flat plane is separated from changing its host geometry. Unequal gaps between three parallels are separated from failure of parallelism. The Riemann sphere remains primary, and all six non-Euclidean exhibits remain available. The revised chapter distinguishes a visible disk boundary, metric distance and the point added at infinity.',
   'text_kind':'book — Non-Euclidean Spaces',
   'before':para('NonEuclidean_Spaces','Geometry was chosen',True),
   'after':'\n\n'.join(para('NonEuclidean_Spaces',p) for p in ['Mathematics lets us','Here the question is','For now, return']),
   'report':PREFIX+'/SUMMARY.md','report_label':'Decisions, remaining six halls and verification limits'},
  {'title':'The sequence is still in progress',
   'description':'Seven of eight declared halls now occur in the authored route; Florensky is still missing and explicitly remains a restoration task. Russell, Gödel, Escher, Brouwer, Florensky and Synthesis keep their manuscripts and maps byte for byte. Next: Russell, with Gödel as the adjacent check on what a logical limit actually says.',
   'report':PREFIX+'/content-checks.json','report_label':'Preservation and integration checks'}
 ]}
(PAGE/'foundationscrisis.json').write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=PAGE/'build.py';s=p.read_text(encoding='utf-8')
s=s.replace("('graphtheory', 'What an early choice makes possible')]:","('graphtheory', 'What an early choice makes possible'), ('foundationscrisis', 'What did the measurement depend on?')]:")
s=s.replace("'machinelearning', 'graphtheory'] if","'machinelearning', 'graphtheory', 'foundationscrisis'] if")
p.write_text(s,encoding='utf-8')
