from pathlib import Path
import hashlib,json
root=Path.cwd();out=root/'doc/book/iterations/2026-09-24-forces-relations'
base=json.loads((out/'baseline.json').read_text(encoding='utf-8'))
changes={}
def read(rel):
 p=root/rel
 assert hashlib.sha256(p.read_bytes()).hexdigest()==base[rel], 'Concurrent companion edit: '+rel
 return p.read_text(encoding='utf-8-sig')
m='Vectors_Act1_WhatAVectorIs'
p=root/f'commons/maps/{m}/final.md'
s=p.read_text(encoding='utf-8').replace('At the next diagram, an input arrow has a companion whose tip stays at the unit sphere.', 'At the next diagram, a sphere gives the companion arrow a reference for unit length.').replace('Both approach the same condition—one unit of length—with their different directions intact.', 'Both have one unit of length, with their different directions intact.').replace('Near zero, the companion disappears.', 'Near zero, the companion has no length to draw.')
p.write_text(s,encoding='utf-8')
changes[f'commons/maps/{m}/intent.md']='''# A relation can move

Begin with the two pins shifting together while their wall projections stay fixed. Let the visitor meet displacement as a reusable relation between addresses, then distinguish it from direction at unit length. Retain the zero-vector convention, the world frame and the question of where a force is applied. The next hall adds two displacements and gives their sum to a moving carriage.
'''
read(f'commons/maps/{m}/intent.md')
rel=f'commons/maps/{m}/tutorial.md'
s=read(rel).replace('SHORT selects magnitude 0.25 m and LONG selects 1 m, retaining direction when nonzero. Their fallback at zero is normalised (1,1,1).', 'SHORT selects magnitude 0.25 m and LONG selects 1 m. They retain direction above magnitude 0.0001; at or below that threshold they supply normalised (1,1,1). This preset threshold differs from the normalisation companion\'s 0.001 threshold.').replace('Its unit-vector numeric readout now uses the computed unit.length(), so zero returns 0.000 instead of the previous hard-coded 1.000.', 'Its numeric readout uses the computed unit.length(), including 0.000 for the zero result.')
changes[rel]=s
m='VFM_02_Operations';rel=f'commons/maps/{m}/tutorial.md'
s=read(rel)
s+='''
## From the floor plan into the scene

The carriage's coordinate conversion is:

```gdscript
return Vector3(v.x, height, -v.y)
```

The second plan component becomes local negative Z; height is supplied separately. The wall's upward diagram axis denotes forward movement on the stage, not a climb. Starting values A=(1,0), B=(0,1) give route length 2 m and direct length sqrt(2) m. The travelled counter starts again after GO's instantaneous homing; it does not include the reset movement.
'''
changes[rel]=s
m='Vectors_Act2_VectorArithmetic'
rel=f'commons/maps/{m}/intent.md';s=read(rel).replace('including the generated rpm label', 'including the crank\'s sin(theta) readout and static wheel pose')
s+='''
The reading pass follows reversal, threshold naming and a remainder that changes role with its rail. Keep the FRIEND label as a specific critical encounter, and the possibility of another use for the pink remainder. Do not reduce all five instruments to the same lesson about omitted information.
'''
changes[rel]=s
rel=f'commons/maps/{m}/tutorial.md';s=read(rel).replace('Its rpm is generated, not observed.', 'Its readout reports sin(theta), the chosen angle and a static wheel pose. The unit-direction cross product sets that pose; it does not integrate angular velocity or report rpm.')
s+='''
The remaining dot console uses normalized directions and FRIEND at dot >= 0.985. Its ordinary slider spans a limited range; the full signed range of a dot product is mathematical context, not a claim that this control reaches every angle. The crank computes r_dir.cross(f_dir) from unit directions. Actual torque would include arm length and force magnitude; the displayed angular factor alone is not physical torque. Projection recombination and perpendicularity hold to ordinary floating-point precision.
'''
changes[rel]=s
rel=f'commons/maps/{m}/critical.md';s=read(rel).replace('The retained torque console prints rpm from a normalized angular factor without measuring revolutions.', 'The retained torque console now names its normalized angular factor, sin(theta), and the wheel\'s static pose. It makes the geometry available without simulating angular acceleration.')
changes[rel]=s
for m in ['Vectors_Act1_WhatAVectorIs','VFM_02_Operations','Vectors_Act2_VectorArithmetic']:
 rel=f'commons/maps/{m}/tutorial.md'
 changes[rel]+='\n## Reading and retained detail\n\nThe canonical [chapter](final.md) follows the encounter. Exact scales, control steps, timing and implementation qualifications remain here. The complete [pre-pass chapter](../../../doc/book/iterations/2026-09-24-forces-relations/before/commons/maps/'+m+'/final.md) is retained for comparison.\n'
for rel,s in changes.items():(root/rel).write_text(s,encoding='utf-8')
changed=[f'commons/maps/{m}/final.md' for m in ['Vectors_Act1_WhatAVectorIs','VFM_02_Operations','Vectors_Act2_VectorArithmetic']]+list(changes)
(out/'changed-files.json').write_text(json.dumps(changed,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'changed_canonical_files':changed},indent=2))
