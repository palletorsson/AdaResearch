"""One-time editorial change; verify.py must reconstruct only the printed edits."""
from pathlib import Path
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PRIOR = ROOT / 'doc/book/iterations/2026-10-16-translation-carried-body'
HALL = 'Trans_Rotation'
CANONICAL = ROOT / 'commons/maps' / HALL / 'tutorial.md'

def put(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(path.name + '.rotation-tmp')
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
    previous = json.loads((PRIOR/'verification.json').read_text(encoding='utf-8'))
    assert previous['passed']
    for path, digest in previous['inputs'].items():
        assert sha(ROOT/path) == digest, 'Stale predecessor: '+path
    paths = [CANONICAL, ROOT/'commons/maps/Trans_Rotation/final.md', ROOT/'commons/maps/Trans_Translation/tutorial.md', ROOT/'doc/book/course/hall-cards/lineage-opening.json', ROOT/'doc/book/course/hall-cards/state.json', ROOT/'doc/book/course/execution-plan/plan.json']
    before = {}
    for path in paths:
        relative = path.relative_to(ROOT)
        before[relative.as_posix()] = sha(path)
        put(HERE/'before'/relative, path.read_text(encoding='utf-8'))
    put(HERE/'before.json', json.dumps(before, indent=2)+'\n')
    for name in ['lesson.gd', 'box_body.gd', 'study.tscn']:
        put(HERE/'incoming'/name, (PRIOR/'complete'/name).read_text(encoding='utf-8'))
    origin = (HERE/'incoming/lesson.gd').read_text(encoding='utf-8')
    helper = (HERE/'incoming/box_body.gd').read_text(encoding='utf-8')
    source = origin
    operations = []
    def edit(id, instruction, old, new, mode='replace'):
        nonlocal source
        assert source.count(old) == 1, id
        operations.append(dict(id=id, file='lesson.gd', instruction=instruction, old=old, mode=mode, expected_sha256=hashlib.sha256(new.encode()).hexdigest()))
        source = source.replace(old,new+old if mode=='before' else new)
        return instruction+'\n\n<!-- student-edit:'+id+' -->\n```gdscript\n'+new+'```\n'

    text = '''# Give the carried body a centre

## Learning elements

- Axis, angle and pivot
- Degrees converted to radians
- A fixed local offset under a rotating parent
- A face mark that makes orientation visible

Follow the end of a blade in the Rotation hall. Its middle stays put while its end crosses the gap. Then follow the mark on the small turning cube: an outline can return before the mark does.

## Bring the body and its clock

Start with a copy of Translation's completed `lesson.gd` and `box_body.gd`, edition 2026-10-16. Keep `BoxBody`, `var travel`, `var elapsed`, the whole `box(size, at)` function and the whole `_process(delta)` function. The box keeps its dimensions: 1.2 metres by 0.2 by 0.8. The new relation is a rotating parent.

Carried unchanged from [Translation](../Trans_Translation/tutorial.md): `box_body.gd`, the class that constructs the visual.

Use the same empty, floor-level `TransformStudy` in the prepared museum, with zero rotation and unit scale. The museum supplies the light and viewer. These are visual bodies; the installed rides supply collision and rider support. Keep your Translation folder so its journeys remain available.

## 1. Give the body a pivot

'''
    old = origin[origin.index('var start'):origin.index('var elapsed')]
    text += edit('pivot-values', 'In `lesson.gd`, replace the declarations from `var start` through `var via_corner` with:', old, '''var pivot := Node3D.new()
var axis := Vector3.UP
var offset := Vector3.ZERO
var duration := 8.0
''')
    text += '''
`pivot` is a new coordinate frame. Its Y axis will be the axis of the turn. `offset` will place the body relative to that frame. `duration` now means seconds per full turn, replacing Translation's time to reach one destination.

'''
    text += edit('parent-the-body', 'Replace `_ready()` with this complete function. Keep `box()` unchanged:', function(origin,'_ready'), '''func _ready() -> void:
    assert(duration > 0.0 and axis.length() > 0.0)
    add_child(pivot)
    pivot.position = Vector3(0, 1.2, 0)
    travel = box(Vector3(1.2, 0.2, 0.8), offset)
    travel.reparent(pivot, false)
    apply_pose(0.0)
''')
    text += '''
`box()` still creates a visual as a child of the study. `reparent(pivot, false)` moves that child beneath the pivot while retaining its **local** transform. The `false` matters: the default keeps the world transform instead. Here we want the supplied `offset` to be interpreted in the new parent's frame. With zero offset, the body's centre is at the pivot, 1.2 metres above the study's origin.

The hierarchy is now `TransformStudy → pivot → travel`. Both nodes exist before `apply_pose()` uses them.

## 2. Turn the frame

Keep `_process(delta)` exactly as Translation left it. It already adds `delta` to `elapsed` and passes `elapsed / duration` to `apply_pose()`.

'''
    text += edit('turn-the-frame', 'Replace the complete `apply_pose(value)` function, including its clamp and route branches, with:', function(origin,'apply_pose'), '''func apply_pose(value: float) -> void:
    var angle := deg_to_rad(360.0 * value)
    pivot.basis = Basis(axis.normalized(), angle)
''')
    turn = source
    text += '''
Run this checkpoint. At two seconds, `value` is 0.25: a quarter of the eight-second turn, or 90 degrees. Godot's `Basis(axis, angle)` expects radians. `deg_to_rad()` converts 90 degrees to π/2; `axis.normalized()` gives the axis a length of one. Assigning the basis sets the pivot's orientation from that angle.

We removed the clamp because this turn continues. At eight seconds the body returns to its initial pose. At ten it has completed another quarter-turn. The clock supplies an absolute angle; we set that orientation rather than add the whole accumulated angle on every frame.

The centre stays still. The corners move. A rotation changes their direction from the centre while preserving their distances from it and from each other.

## 3. Keep sight of one face

'''
    text += edit('attach-the-mark', 'In `_ready()`, insert these lines immediately before `apply_pose(0.0)`. Keep that existing call:', '    apply_pose(0.0)\n', '''    var mark := box(Vector3(0.3, 0.02, 0.18), Vector3(0.35, 0.11, 0.2))
    mark.reparent(travel, false)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.06, 0.06, 0.06)
    mark.material_override = ink
''', mode='before')
    text += '''
The mark is another small `BoxBody`, placed just above the top face. It becomes a child of `travel`, so its coordinates belong to that body. The material makes it dark enough to follow; material design is a later lesson. Only the pivot needs an orientation update. The body and mark inherit it.

Run again. Our rectangular body has the same outline after a half-turn, at four seconds. The off-centre mark is on the other side. At eight seconds both return. The hall's cube has more rotational symmetry: its outline can return after a quarter-turn. What counts as a return depends on what you follow.

## Move the centre through space

Change the existing `offset` declaration to `var offset := Vector3(2, 0, 0)`. Predict the body's position after two seconds, then run. Its local position stays `(2, 0, 0)` throughout. Its parent turns that direction in the study, so its centre now travels in a circle of radius two.

After the quarter-turn about positive Y, the body's centre is at `(0, 1.2, -2)` in the study's frame. Its top still faces up, but its long edge has turned. The face mark stays attached. Moving the study elsewhere in the museum changes world coordinates without changing this local relation.

Keep the two-metre offset and change `axis` to `Vector3.FORWARD`, Godot's negative Z direction. Predict the quarter-turn. The centre now reaches `(0, -0.8, 0)`: below the study's origin. Raise the study two metres to see the entire vertical circle above the floor. The installed platforms use an additional rule to keep riders upright; this body turns with its parent.

Finally change `duration` to `16.0`. Where will the body be after four seconds? Explain which values change the orbit's size, its plane and its timing. The complete versions of these three experiments are linked below.

Carry the pivot, body and mark onward. Scale will reuse the fact that changing a parent reaches its children, and that the origin determines what stays in place. Combining rotations around different axes remains another encounter in the hall; this lesson gives one turn a clear centre first.

'''
    prefix = '../../../doc/book/iterations/2026-10-16-rotation-carried-body'
    text += f'[Complete files, edition 2026-10-16]({prefix}/files.html#complete) · [lesson.gd]({prefix}/complete/lesson.gd) · [unchanged box_body.gd]({prefix}/complete/box_body.gd) · [Download files and variants]({prefix}/rotation-studies.zip)\n'
    text += '\n<details class="full-program">\n<summary>Complete lesson.gd — online reference</summary>\n\n<!-- student-code:lesson.gd -->\n```gdscript\n'+source+'```\n\n</details>\n'
    for state, script in [('turn',turn),('complete',source)]:
        put(HERE/state/'lesson.gd',script)
        put(HERE/state/'box_body.gd',helper)
    put(CANONICAL,text)
    put(HERE/'tutorial.md',text)
    put(HERE/'final.md',(ROOT/'commons/maps/Trans_Rotation/final.md').read_text(encoding='utf-8'))
    put(HERE/'edits.json',json.dumps(dict(edition='2026-10-16',predecessor=PRIOR.relative_to(ROOT).as_posix()+'/complete',operations=operations),indent=2)+'\n')
    print('Prepared four edits from tested Translation: unchanged BoxBody, box(), _process().')

if __name__=='__main__': main()
