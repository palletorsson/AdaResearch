"""One-time editorial change. Tests reconstruct files from the printed edits separately."""
from pathlib import Path
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
HALLS = ['Trans_Pre', 'Trans_Introduction']
PREFIX = '../../../doc/book/iterations/2026-10-16-transformation-handoff'

def put(p, text):
    p.parent.mkdir(parents=True, exist_ok=True)
    temporary = p.with_name(p.name + '.handoff-tmp')
    temporary.write_text(text, encoding='utf-8', newline='\n')
    temporary.replace(p)

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def code(text, name='lesson.gd'):
    matches = re.findall(r'<!-- student-code:' + re.escape(name) + r' -->\s*```gdscript\n(.*?)^```', text, re.M | re.S)
    assert len(matches) == 1, name
    return matches[0]

def function(source, name):
    found = re.findall(r'^func ' + re.escape(name) + r'\(.*?(?=^func |\Z)', source, re.M | re.S)
    assert len(found) == 1, name
    return found[0].rstrip() + '\n'

def block(id, source):
    return '<!-- student-edit:' + id + ' -->\n```gdscript\n' + source.rstrip() + '\n```\n'

def complete(source):
    return '\n<details class="full-program">\n<summary>Complete lesson.gd — online reference</summary>\n\n<!-- student-code:lesson.gd -->\n```gdscript\n' + source + '```\n\n</details>\n'

def main():
    assert not (HERE / "edits.json").exists(), "Edition already prepared. Run verify.py and publish.py; do not replay the editorial change."
    if not (HERE / 'before.json').exists():
        before = {}
        for hall in ['Point_Animatedcube', 'Primitives_Melencolia', *HALLS]:
            for name in ['tutorial.md', 'final.md']:
                p = ROOT / 'commons/maps' / hall / name
                before[p.relative_to(ROOT).as_posix()] = sha(p)
                put(HERE / 'before' / hall / name, p.read_text(encoding='utf-8'))
        for name in ['plan.json']:
            p = ROOT / 'doc/book/course/execution-plan' / name
            put(HERE / 'before' / name, p.read_text(encoding='utf-8'))
        p = ROOT / 'doc/book/course/hall-cards/state.json'
        put(HERE / 'before/cards.json', p.read_text(encoding='utf-8'))
        put(HERE / 'before.json', json.dumps(before, indent=2) + '\n')

    origin = code((HERE / 'before/Primitives_Melencolia/tutorial.md').read_text(encoding='utf-8'))
    put(HERE / 'Primitives_Melencolia/lesson.gd', origin)
    earlier = ROOT / 'doc/book/iterations/2026-10-06-starter-one-course/lessons/Primitives_Melencolia'
    for name in ['cube_body.gd', 'point_body.gd', 'face_body.gd', 'line_skin.gd']:
        put(HERE / 'Primitives_Melencolia' / name, (earlier / name).read_text(encoding='utf-8'))

    helper = '''extends MeshInstance3D

func _init(size: Vector3 = Vector3.ONE) -> void:
    var shape := BoxMesh.new()
    shape.size = size
    mesh = shape
'''
    declarations = '''const BoxBody = preload("box_body.gd")

var cube := BoxBody.new()
var start := Vector3(0, 1.3, 0)
var rise := 0.35
var turn_speed := 45.0
var pulse := 0.2
var period := 4.0
var elapsed := 0.0
'''
    ready = '''func _ready() -> void:
    assert(period > 0.0 and pulse >= 0.0 and pulse < 1.0)
    add_child(cube)
    cube.position = start
'''
    old_pre = code((HERE / 'before/Trans_Pre/tutorial.md').read_text(encoding='utf-8'))
    process = function(old_pre, '_process')
    callback = function(old_pre, '_on_body_entered')
    sensor = function(old_pre, '_ready').split('\n\n', 1)[1]
    movement = 'extends Node3D\n' + declarations + '\n' + ready + '\n' + process
    pre = movement.replace(ready, ready + '\n' + sensor) + '\n' + callback
    intro_old = code((HERE / 'before/Trans_Introduction/tutorial.md').read_text(encoding='utf-8'))
    intro = intro_old.replace('extends Node3D\n', 'extends Node3D\nconst BoxBody = preload("box_body.gd")\n')
    intro = intro.replace('var duration := 4.0', 'var period := 8.0').replace('assert(duration > 0.0', 'assert(period > 0.0')
    intro = intro.replace('var body := MeshInstance3D.new()\n    var mesh := BoxMesh.new()\n    mesh.size = size\n    body.mesh = mesh', 'var body := BoxBody.new(size)')
    intro = intro.replace('pingpong(elapsed / duration, 1.0)', 'pingpong(2.0 * elapsed / period, 1.0)')
    for hall, source in [('Trans_Pre', pre), ('Trans_Introduction', intro)]:
        put(HERE / hall / 'lesson.gd', source)
        put(HERE / hall / 'box_body.gd', helper)
    put(HERE / 'Trans_Pre/movement.gd', movement)

    operations = []
    def op(id, stage, file, instruction, old, new, kind='replace', marker=None):
        operations.append(dict(id=id, stage=stage, file=file, instruction=instruction, kind=kind,
                               old=old, marker=marker or id, expected=new))
        return instruction + '\n\n' + (block(marker or id, new) if new else '')

    pre_text = '''# A cube that moves, turns and grows

## Learning elements

- Reusing a class; construction versus transform
- Translation, rotation and uniform scale
- Elapsed seconds and a returning fraction
- Overlap detection, signals and a player filter

In Trans_Pre, one cube rises. Another rises and turns. A third also changes size. Follow one corner: each example adds an operation to the same kind of body.

## Bring your arrangement

Save your Melencolia arrangement. Work on a copy of its `lesson.gd` in this hall; leave the original intact. The museum already supplies the room, light, camera and player. Use an empty, floor-level `Node3D` named `TransformStudy`, with zero rotation and unit scale, as the host for this copy. We replace its arrangement with one animated pickup.

There is a deliberate change of representation. `CubeBody` exposed vertices and faces. Here `BoxBody` will use Godot's `BoxMesh` to study the whole body's transform. Both describe a one-metre cube, but `CubeBody` starts at its bottom; `BoxMesh` is centred on its origin. Keep the old files with your arrangement. Their face-list construction and pickable point are not dependencies of this branch.

The coordinate frame, instance, parent-child relation and `_ready()` carry forward. Point Zero's `_process(delta)` returns as the clock. This is a new construction of a familiar shape; the museum does not transfer the same running instance between halls.

## 1. Give the visual a small class

'''
    pre_text += op('box-body', 'movement', 'box_body.gd', 'Create `box_body.gd` beside `lesson.gd`. This is its whole file.', '', helper, 'create')
    pre_text += '''
`BoxBody.new()` gives one visible, centred cube. The optional `size` argument gives its dimensions in metres. Each call creates its own mesh. This class adds no collider, player or movement. The next hall will carry this file unchanged.

## 2. Replace the arrangement, keep the host

'''
    old_decl = origin.split('extends Node3D\n',1)[1].split('\nfunc _ready()',1)[0].rstrip()+'\n'
    pre_text += op('pre-values', 'movement', 'lesson.gd', 'In `lesson.gd`, keep `extends Node3D`. Replace the declarations between it and `func _ready()` with:', old_decl, declarations)
    pre_text += '\n'
    pre_text += op('pre-ready', 'movement', 'lesson.gd', 'Replace the complete `_ready()` function with this one. There is still only one `_ready()`:', function(origin, '_ready'), ready)
    pre_text += '\n'
    pre_text += op('pre-clock', 'movement', 'lesson.gd', 'Append `_process()` after `_ready()`:', '', process, 'append')
    pre_text += '''
The cube now rises, turns and pulses. `elapsed += delta` keeps seconds between updates. `pingpong` makes a fraction travel from zero to one and back. `period` is **one complete return cycle**, in seconds. The `0.5` offset starts the cube halfway up, moving upward.

`lerpf(-rise, rise, t)` chooses a height offset. At `t = 0.5`, that offset is zero. Multiplying `Vector3.ONE` by the second interpolation scales all axes equally. The turn uses elapsed seconds directly: 45 degrees per second, independent of `period`.

Each update assigns the pose from the starting values. Repeatedly adding the whole pose would make it drift. The assertion prevents a zero period and a pulse that collapses or inverts the cube.

Set `turn_speed` and `pulse` to `0.0`: only the rise remains. Restore `turn_speed = 45.0`, then `pulse = 0.2`. The same mesh acquires another behaviour at each step. With `period = 4.0`, the height is 1.3 m initially, 1.65 m after one second, 0.95 m after three, and 1.3 m after four. The change reverses immediately at each end; easing would be another timing choice.

## 3. Let an overlap collect it

'''
    pre_text += op('pre-sensor', 'complete', 'lesson.gd', 'Inside `_ready()`, immediately after `cube.position = start`, insert these lines at the same indentation:', '    cube.position = start\n', sensor, 'insert_after')
    pre_text += '\n'
    pre_text += op('pre-collect', 'complete', 'lesson.gd', 'Append this function after `_process()`. It is the receiver connected above:', '', callback, 'append')
    pre_text += '''
An `Area3D` reports overlap; it does not block a body. Its one-metre `BoxShape3D` matches the unscaled visual. As a child of the cube, the area follows its movement, rotation and uniform scale. `body_entered.connect(...)` connects the event to our receiver.

The museum supplies `player_body` on collision layer 20. The prepared desktop preview uses `em_walker` on layer 1. The mask admits those layers; the group condition identifies the player. A prop is ignored. A qualifying overlap prints `Collected`, then `queue_free()` removes this study at the end of the frame. Score and celebration effects remain with the installed exhibit.

## Predict, change, carry

Change only `period` to `8.0`. Rise and pulse should take twice as long; turning should retain its speed. Explain why, then choose another rise without changing the cube's proportions.

Keep a saved copy of this collectible version for Arrays. Introduction branches from it: the visual class and clock continue, while the collection code is removed so the comparison stays visible.

'''
    pre_text += f'[Complete files, edition 2026-10-16]({PREFIX}/files.html#Trans_Pre) · [lesson.gd]({PREFIX}/Trans_Pre/lesson.gd) · [box_body.gd]({PREFIX}/Trans_Pre/box_body.gd) · [Download the studies]({PREFIX}/transformation-handoff.zip)\n'
    pre_text += complete(pre)
    # Keep the established full-source extractor compatible; the new class is printed once above.
    pre_text = pre_text.replace('<!-- student-edit:box-body -->', '<!-- student-edit:box-body -->\n<!-- student-code:box_body.gd -->')

    intro_text = '''# Three ways to make a crossing

## Learning elements

- Reusing the same visual class for independent instances
- A function returning the object it places
- A bounded pose fraction and interpolation
- Separating a pose from the clock that selects it

Try the three installed crossings. One carries you, one grows, one turns into alignment. The far bank gives each change a purpose. An object can reach its programmed pose and still fail to reach the bank.

## Bring the completed Pre study

Copy Pre's `lesson.gd` and `box_body.gd` into your working folder here. Keep the pickup version saved. All edits below apply to that completed copy, not the earlier movement-only checkpoint. Keep the same empty `TransformStudy` host, at floor level, with zero rotation and unit scale, in a clear space about ten metres wide.

Carried unchanged from [Pre](../Trans_Pre/tutorial.md): `box_body.gd`.

These are small visual comparisons beside the existing exhibits. They have no blocking collision. Use the installed crossings for standing and riding; their transport system is supplied by the museum.

## 1. Give the bodies separate names

'''
    pre_vars = pre.split('var cube :=',1)[1].split('var elapsed',1)[0]
    pre_vars = 'var cube :=' + pre_vars
    intro_vars = intro.split('var travel:',1)[1].split('var elapsed',1)[0]
    intro_vars = 'var travel:' + intro_vars
    intro_text += op('intro-values', 'comparison', 'lesson.gd', 'Keep `extends Node3D`, the `BoxBody` preload and `var elapsed := 0.0`. Replace the variables from `var cube` through `var period` with:', pre_vars, intro_vars)
    intro_text += '''
`period` still means a full return cycle. Eight seconds gives four seconds outward and four back. `far_banks` keeps references to the three far banks; `travel`, `grow` and `turn` refer to the three moving models.

## 2. Place what the class can make

'''
    intro_text += op('intro-box', 'comparison', 'lesson.gd', 'In `lesson.gd`, insert this complete `box()` function immediately before `_process()`:', 'func _process(delta: float) -> void:', function(intro, 'box'), 'insert_before')
    intro_text += '''
Construction is still in `box_body.gd`. This small function chooses dimensions and a position, attaches the instance to the study, then returns it. Returning the reference lets us change that particular body later.

'''
    intro_text += op('intro-ready', 'comparison', 'lesson.gd', 'Replace the complete `_ready()` function, including its collection area and signal connection, with:', function(pre, '_ready'), function(intro, '_ready'))
    intro_text += '''
The loop makes a pair of banks in each lane: X = −4, 0 and 4. Their tops are one metre above the study's origin. The remaining calls make the three moving models. The growing cube is centred at origin height, so its lower half extends beneath the floor; this is a model of a changing span.

## 3. Make the pose inspectable

'''
    intro_text += op('intro-pose', 'comparison', 'lesson.gd', 'Replace `_on_body_entered()` with this complete function. No collection callback remains:', callback, function(intro, 'apply_pose'))
    intro_text += '''
`apply_pose(value)` can be called without advancing time. Zero selects the starting pose; one selects the ending pose. `clampf` keeps the fraction within those bounds. `lerpf(a, b, t)` selects a value between two numbers; at 0.5 it gives their average.

'''
    old_tail = process.split('    elapsed += delta\n',1)[1]
    new_tail = function(intro, '_process').split('    elapsed += delta\n',1)[1]
    intro_text += op('intro-clock', 'comparison', 'lesson.gd', 'In `_process(delta)`, keep the function header and `elapsed += delta`. Replace all the lines below that statement with:', old_tail, new_tail)
    intro_text += '''
The same clock now selects a shared pose. The earlier phase offset is gone, so the comparison begins at zero. When `animate` is false, time can pass while the chosen pose remains still.

## Hold, predict, move the bank

Set `animate = false` and try `pose = 0.0`, then `0.5`, then `1.0`. Before each run, predict the travelling surface's Z position, the cube's scale factor and the plank's angle. Halfway gives Z = 0, scale = 0.625 and 45 degrees.

At one, the first surface reaches the far bank unchanged in size. The cube reaches bank height and spans the gap by growing around its centre. The plank turns its long dimension along Z; its centre and dimensions stay fixed.

Keep that final pose and set `far_gap = 0.5`. The far banks move half a metre away. The growing cube and turned plank retain their old poses and leave a gap. Reaching a pose and reaching another object are separate conditions.

Restore `far_gap = 0.0` and `animate = true`. The three models take four seconds out and four back. Carry the unchanged visual class, the returning placement function and the distinction between input and pose toward Translation. That next lesson will need its own continuation edit; this edition repairs the handoff through Introduction.

'''
    intro_text += f'[Complete files, edition 2026-10-16]({PREFIX}/files.html#Trans_Introduction) · [lesson.gd]({PREFIX}/Trans_Introduction/lesson.gd) · [unchanged box_body.gd]({PREFIX}/Trans_Introduction/box_body.gd) · [Download the studies]({PREFIX}/transformation-handoff.zip)\n'
    intro_text += complete(intro)
    for hall, text in [('Trans_Pre', pre_text), ('Trans_Introduction', intro_text)]:
        put(ROOT / 'commons/maps' / hall / 'tutorial.md', text)
        put(HERE / hall / 'tutorial.md', text)
    # Separate printed code from instructions, so verification must read tutorial.md.
    for operation in operations:
        operation['expected_sha256'] = hashlib.sha256(operation.pop('expected').encode()).hexdigest()
    put(HERE / 'edits.json', json.dumps({'edition':'2026-10-16', 'incoming':'Primitives_Melencolia/lesson.gd', 'operations':operations}, indent=2) + '\n')

    patches = {
        'Point_Animatedcube': ('It is the cube we can carry into Transformation and Arrays.', 'Keep this class for constructions where the faces matter. Transformation returns to the cube shape through a small BoxBody class using Godot\'s centred BoxMesh; the change of representation is explained in Trans_Pre. Arrays can later reuse that whole-body version.'),
        'Primitives_Melencolia': ('Carry CubeBody and PointBody into Transformation. A body that you can place is ready to become a body whose position, rotation or scale changes over time.', 'Save this arrangement and its CubeBody and PointBody files. In [Trans_Pre](../Trans_Pre/tutorial.md), work on a copy of lesson.gd: the arrangement gives way to one whole-body cube. A small BoxBody class uses Godot\'s centred BoxMesh instead of the face-list CubeBody. The tutorial names that change, including the different origin, and shows each edit. Placement, construction and the running clock meet as position, orientation and size begin to change.')}
    for hall, (old, new) in patches.items():
        p = ROOT / 'commons/maps' / hall / 'tutorial.md'
        text = p.read_text(encoding='utf-8')
        assert text.count(old) == 1
        put(p, text.replace(old, new))
    print('Prepared two canonical tutorials, two explicit forward links, printed edits and complete files.')

if __name__ == '__main__':
    main()
