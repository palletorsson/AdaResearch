"""One-time editorial change; verify.py must reconstruct only the printed edits."""
from pathlib import Path
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PRIOR = ROOT / 'doc/book/iterations/2026-10-16-rotation-carried-body'
HALL = 'Trans_Scale'
CANONICAL = ROOT / 'commons/maps' / HALL / 'tutorial.md'

def put(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(path.name + '.scale-tmp')
    temp.write_text(value, encoding='utf-8', newline='\n')
    temp.replace(path)

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def block(text, name='lesson.gd'):
    found = re.findall(r'<!-- student-code:' + re.escape(name) + r' -->\s*```gdscript\n(.*?)^```', text, re.M | re.S)
    assert len(found) == 1, name
    return found[0]

def function(source, name):
    found = re.findall(r'^func ' + re.escape(name) + r'\(.*?(?=^func |\Z)', source, re.M | re.S)
    assert len(found) == 1
    return found[0].rstrip() + '\n'

def main():
    assert not (HERE/'edits.json').exists(), 'Already prepared; run verify.py to retest.'
    previous=json.loads((PRIOR/'verification.json').read_text(encoding='utf-8'))
    assert previous['passed']
    for path,digest in previous['inputs'].items():
        assert sha(ROOT/path)==digest,'Stale predecessor: '+path
    paths=[CANONICAL,ROOT/'commons/maps/Trans_Scale/final.md',ROOT/'commons/maps/Trans_Rotation/tutorial.md',ROOT/'doc/book/course/hall-cards/lineage-opening.json',ROOT/'doc/book/course/hall-cards/state.json',ROOT/'doc/book/course/execution-plan/plan.json']
    before={}
    for path in paths:
        relative=path.relative_to(ROOT)
        before[relative.as_posix()]=sha(path)
        put(HERE/'before'/relative,path.read_text(encoding='utf-8'))
    put(HERE/'before.json',json.dumps(before,indent=2)+'\n')
    for name in ['lesson.gd','box_body.gd','study.tscn']:
        put(HERE/'incoming'/name,(PRIOR/'complete'/name).read_text(encoding='utf-8'))
    origin=(HERE/'incoming/lesson.gd').read_text(encoding='utf-8')
    helper=(HERE/'incoming/box_body.gd').read_text(encoding='utf-8')
    source=origin
    operations=[]
    def edit(id,instruction,old,new='',mode='replace'):
        nonlocal source
        assert source.count(old)==1,id
        operations.append(dict(id=id,file='lesson.gd',instruction=instruction,old=old,mode=mode,expected_sha256=hashlib.sha256(new.encode()).hexdigest()))
        source=source.replace(old,new)
        marker='student-remove:' if mode=='remove' else 'student-edit:'
        return instruction+'\n\n<!-- '+marker+id+' -->\n'+('```gdscript\n'+new+'```\n' if mode!='remove' else '')

    text='''# Enlarge the opening, keep the witness

## Learning elements

- Uniform and unequal scale factors
- Scaling both child dimensions and child spacing
- An origin that keeps the threshold on the floor
- A fixed reference outside the changing parent

The little doorway in this hall becomes a possible passage when the room grows. Your body stays the same size. The bottle also moves you to the table; that relocation is a separate operation. Our study selects the changing opening and a reference that stays outside the change.

## Bring the parent–child relation

Copy Rotation's completed `lesson.gd` and `box_body.gd`, edition 2026-10-16. Keep the `BoxBody` preload, `var pivot := Node3D.new()` and the entire `box(size, at)` function. The parent remains; three boxes now form a doorway beneath it. Its origin will sit at the threshold. A black sphere beside it will keep a fixed size.

Carried unchanged from [Rotation](../Trans_Rotation/tutorial.md): `box_body.gd`, the visual constructor. Keep `box()` unchanged too: it returns a box attached to the study. We use the same `reparent(parent, false)` operation to place that box in the parent's local frame.

Use the same empty, floor-level `TransformStudy` in the prepared museum, with zero rotation and unit scale. The museum supplies the light and viewer. These meshes have no collision or pickup; the installed room supplies the bodily passage. Keep the Rotation folder so its turning study remains available. Apply all five edits below before running.

## 1. Choose a size instead of a time

'''
    text+=edit('remove-travel','In `lesson.gd`, delete the declaration `var travel: MeshInstance3D`. Keep the `pivot` declaration immediately below it.','var travel: MeshInstance3D\n',mode='remove')
    text+=edit('scale-values','Replace the declarations from `var axis` through `var elapsed` with:',origin[origin.index('var axis'):origin.index('\nfunc _ready')],'''var point := MeshInstance3D.new()
var factors := Vector3.ONE
''')
    text+='''
`Vector3.ONE` means one on X, Y and Z: the original size. The three components will let us enlarge every dimension together or change only one. The sphere is a simple visual reference, not the grabbable point from Coordinates.

'''
    text+=edit('remove-clock','Delete the complete `_process(delta)` function, including `elapsed += delta` and its call to `apply_pose()`. This comparison stays at the chosen scale.',function(origin,'_process'),mode='remove')
    text+='''
## 2. Put the opening under the parent

'''
    text+=edit('build-opening','Replace `_ready()` with this complete function. Keep `box()` unchanged:',function(origin,'_ready'),'''func _ready() -> void:
    add_child(pivot)
    for at in [Vector3(-0.285, 0.3, 0), Vector3(0.285, 0.3, 0)]:
        var post := box(Vector3(0.12, 0.6, 0.2), at)
        post.reparent(pivot, false)
    var lintel := box(Vector3(0.69, 0.12, 0.2), Vector3(0, 0.66, 0))
    lintel.reparent(pivot, false)
    var sphere := SphereMesh.new()
    sphere.radius = 0.325
    sphere.height = 0.65
    point.mesh = sphere
    add_child(point)
    point.position = Vector3(1.8, 0.325, 0)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.06, 0.06, 0.06)
    point.material_override = ink
    apply_pose(factors)
''')
    text+='''
The familiar loop makes two posts from two positions. Each post is centred halfway up its height, so its bottom is at zero. The lintel's lower edge is at 0.60 metres. The inner edges of the posts are 0.45 metres apart. These measurements describe the clear opening, not the outside of the frame.

Rotation placed the parent 1.2 metres above the floor. This `_ready()` leaves `pivot` at its default zero position and identity orientation. Its origin is now the centre of the threshold. The doorway parts belong to it; their local positions describe the assembly.

The sphere construction is shown because this continued file has no sphere yet. Its radius and height make a diameter of 0.65 metres. `add_child(point)` attaches it to the study, alongside `pivot`. It does not become a child of the doorway. The hierarchy decides which bodies will change together.

## 3. Change the parent

'''
    text+=edit('scale-the-frame','Replace the complete `apply_pose(value)` function with:',function(origin,'apply_pose'),'''func apply_pose(value: Vector3) -> void:
    assert(value.x > 0.0 and value.y > 0.0 and value.z > 0.0)
    pivot.scale = value
''')
    text+='''
The argument has changed type: Rotation passed a single time fraction; Scale passes three factors in a `Vector3`. `_ready()` now supplies `factors`, and the removed clock no longer sends a float. This lesson uses positive factors; zero would collapse a dimension and negative values introduce reflection.

Run the study. The 0.45-by-0.60-metre opening is narrower and shorter than the sphere's diameter. Change the existing declaration to `var factors := Vector3(4, 4, 4)` and run again. The opening is now 1.80 metres wide and 2.40 metres high. The sphere is still 0.65 metres across.

`pivot.scale` reaches both the children's dimensions and their spacing. Each post keeps its stored position and mesh size, while the parent changes where its surfaces appear in the world. The posts stay on the floor because their bottom edges lie at the scaling origin's height. Setting only each box's scale would enlarge the parts without spreading their centres apart.

## Change width without changing height

Replace the `factors` declaration with `var factors := Vector3(4, 1, 1)`. Predict the opening before running: 1.80 metres wide, still 0.60 metres high. The sphere remains too tall. Unlike uniform enlargement, this changes proportions.

Try `var factors := Vector3(2, 2, 1)`. The opening becomes 0.90 by 1.20 metres; the frame's depth stays 0.20 metres. Explain why the sphere keeps its position and diameter in all three versions, and why the posts' bottoms stay put. These are geometric comparisons: our meshes do not test collision or whether a person can comfortably pass.

The next hall will choose a factor from your approach. Carry the unchanged `BoxBody` constructor, the placement function, and the distinction between a changing group and a fixed reference. A parent can turn its children or resize their arrangement; its origin and membership determine the result.

'''
    prefix='../../../doc/book/iterations/2026-10-16-scale-carried-frame'
    text+=f'[Complete files, edition 2026-10-16]({prefix}/files.html#complete) · [lesson.gd]({prefix}/complete/lesson.gd) · [unchanged box_body.gd]({prefix}/complete/box_body.gd) · [Download files and variants]({prefix}/scale-studies.zip)\n'
    text+='\n<details class="full-program">\n<summary>Complete lesson.gd — online reference</summary>\n\n<!-- student-code:lesson.gd -->\n```gdscript\n'+source+'```\n\n</details>\n'
    put(HERE/'complete/lesson.gd',source)
    put(HERE/'complete/box_body.gd',helper)
    put(CANONICAL,text)
    put(HERE/'tutorial.md',text)
    put(HERE/'final.md',(ROOT/'commons/maps/Trans_Scale/final.md').read_text(encoding='utf-8'))
    put(HERE/'edits.json',json.dumps(dict(edition='2026-10-16',predecessor=PRIOR.relative_to(ROOT).as_posix()+'/complete',operations=operations),indent=2)+'\n')
    print('Prepared Scale: five edits, including two removals; BoxBody, box() and pivot declaration retained.')

if __name__=='__main__': main()

