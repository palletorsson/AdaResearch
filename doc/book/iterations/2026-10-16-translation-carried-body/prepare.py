"""One-time Translation edit; verify.py reconstructs its printed continuation."""
from pathlib import Path
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PRIOR = ROOT / 'doc/book/iterations/2026-10-16-transformation-handoff'
HALL = 'Trans_Translation'
CANONICAL = ROOT / 'commons/maps' / HALL / 'tutorial.md'

def put(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + '.translation-tmp')
    temporary.write_text(value, encoding='utf-8', newline='\n')
    temporary.replace(path)

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
    assert not (HERE / 'edits.json').exists(), 'Already prepared. Retest with verify.py; do not replay the editorial change.'
    paths = [CANONICAL, ROOT / 'commons/maps/Trans_Translation/final.md', ROOT / 'commons/maps/Trans_Introduction/tutorial.md', ROOT / 'commons/maps/Trans_Introduction/final.md', ROOT / 'doc/book/course/hall-cards/lineage-opening.json', ROOT / 'doc/book/course/hall-cards/state.json', ROOT / 'doc/book/course/execution-plan/plan.json']
    before = {}
    for path in paths:
        before[path.relative_to(ROOT).as_posix()] = sha(path)
        put(HERE / 'before' / path.relative_to(ROOT), path.read_text(encoding='utf-8'))
    put(HERE / 'before.json', json.dumps(before, indent=2) + '\n')
    for name in ['lesson.gd', 'box_body.gd']:
        put(HERE / 'incoming' / name, (PRIOR / 'Trans_Introduction' / name).read_text(encoding='utf-8'))
    origin = (HERE / 'incoming/lesson.gd').read_text(encoding='utf-8')
    assert origin == block((ROOT / 'commons/maps/Trans_Introduction/tutorial.md').read_text(encoding='utf-8'))
    source = origin
    operations = []
    def edit(id, instruction, old, new):
        nonlocal source
        assert source.count(old) == 1, id
        operations.append(dict(id=id, file='lesson.gd', instruction=instruction, old=old, expected_sha256=hashlib.sha256(new.encode()).hexdigest()))
        source = source.replace(old, new)
        return instruction + '\n\n<!-- student-edit:' + id + ' -->\n```gdscript\n' + new + '```\n'

    text = '''# A level body on a sloping journey

## Learning elements

- Displacement in a named coordinate frame
- Vector interpolation between positions
- A one-way journey that stops at its destination
- A condition choosing between two route segments

Watch the installed carrier whose route slopes while its top stays level. Translation changes where a body is without making it turn. At the exit, the guided handle's bend and the freer handle's diagonal give the same destination different journeys.

## Bring the travelling body

Start with a copy of Introduction's completed `lesson.gd` and `box_body.gd`, edition 2026-10-16. Keep `box_body.gd` and the entire `box(size, at)` function unchanged. They already construct and place the visual. Keep the name `travel` for the body we continue.

Carried unchanged from [Introduction](../Trans_Introduction/tutorial.md): `box_body.gd`.

Use the same empty `TransformStudy` host in the prepared museum: floor-level origin, zero rotation and unit scale. The positions below are metres in that host's local frame. This visual study has no rider physics; the museum's installed carriers supply the ride. Work on the copy so your three-way comparison remains available.

## 1. Give it a destination

'''
    old = origin[origin.index('var grow:'):origin.index('var elapsed')]
    text += edit('route-values', 'In `lesson.gd`, keep the `BoxBody` preload, `var travel` and `var elapsed`. Replace the declarations from `var grow` through `var period` with:', old, '''var start := Vector3(-2, 1, 0)
var finish := Vector3(2, 3, 0)
var duration := 4.0
var via_corner := false
''')
    text += '''
Introduction's `period` described a complete out-and-back cycle. Here `duration` is the time to reach the destination once. Four seconds will take the body from `start` to `finish`; it will then stay there.

'''
    text += edit('one-body', 'Replace `_ready()` with this complete function. Keep `box()` exactly as it is:', function(origin, '_ready'), '''func _ready() -> void:
    assert(duration > 0.0)
    travel = box(Vector3(1.2, 0.2, 0.8), start)
    apply_pose(0.0)
''')
    text += '''
Only the travelling body is constructed now. Its dimensions are unchanged from Introduction. The banks, growing cube and turning plank are no longer created. `_ready()` still creates the visual before asking `apply_pose()` to position it.

## 2. Use the clock once

'''
    text += edit('one-way-clock', 'In `_process(delta)`, keep the header and `elapsed += delta`. Replace the remaining lines of that function with:', function(origin, '_process').split('    elapsed += delta\n',1)[1], '    apply_pose(elapsed / duration)\n')
    text += '''
Dividing elapsed seconds by the journey's duration gives its fraction: after two of four seconds, 0.5. We keep the clamp already inside `apply_pose()`. Once the fraction exceeds one, the pose stays at one instead of returning.

'''
    text += edit('direct-route', 'In `apply_pose(value)`, keep the header and `var t := clampf(value, 0.0, 1.0)`. Replace the three transform assignments below it with:', function(origin, 'apply_pose').split('    var t := clampf(value, 0.0, 1.0)\n',1)[1], '    travel.position = start.lerp(finish, t)\n')
    direct = source
    text += '''
Run this direct version. `start.lerp(finish, t)` interpolates the three coordinates together. This extends the single-number interpolation in Introduction to a `Vector3`. At `t = 0.5`, the body is at `(0, 2, 0)`, halfway along the diagonal. At four seconds it reaches `(2, 3, 0)` and stops.

`finish - start` is the displacement `(4, 2, 0)`: four metres along X and two upward. Its components describe a combined change, not an instruction to finish X before beginning Y. Neither rotation nor scale changes during the journey, so the sloping route leaves the surface level.

## 3. Give the same displacement another route

'''
    text += edit('corner-route', 'In `apply_pose(value)`, replace only `travel.position = start.lerp(finish, t)` with this conditional. Keep the clamp above it:', '    travel.position = start.lerp(finish, t)\n', '''    if via_corner:
        var corner := Vector3(start.x, finish.y, start.z)
        if t < 0.5:
            travel.position = start.lerp(corner, t * 2.0)
        else:
            travel.position = corner.lerp(finish, (t - 0.5) * 2.0)
    else:
        travel.position = start.lerp(finish, t)
''')
    text += '''
Set `via_corner` to `true`. The corner is directly above the start, at the destination's height. The first half of the time takes the body upward; the second takes it across. The condition chooses a segment. Each segment needs its own zero-to-one fraction: `t * 2.0` gives it to the first half, and `(t - 0.5) * 2.0` gives it to the second.

At two seconds, the direct version reaches `(0, 2, 0)`; the corner version reaches `(-2, 3, 0)`. At four seconds they meet at the same destination. Each leg gets two seconds, but their lengths differ: two metres up, four across. The second leg therefore moves twice as fast. A constant-speed route would require another timing rule.

## Predict another journey

Keep `via_corner = true` and change `finish` to `Vector3(2, 3, 2)`. Predict the halfway and final positions before running. The corner stays above the start; the second leg now changes X and Z together. Explain why the body still does not turn to face its travel.

Then change `duration` to `8.0`. Both legs should take twice as long, with the same endpoints. The unchanged `BoxBody` creates the shape; the route and time now determine where it goes.

Trace kept positions after a movement. Here positions prescribe a movement. A longer route could store them in an array; these two branches are enough to understand the choice first. Carry the body, placement function, clock and separate pose function onward. Rotation next gives turning its own axis and centre.

'''
    prefix = '../../../doc/book/iterations/2026-10-16-translation-carried-body'
    text += f'[Complete files, edition 2026-10-16]({prefix}/files.html#complete) · [lesson.gd]({prefix}/complete/lesson.gd) · [unchanged box_body.gd]({prefix}/complete/box_body.gd) · [Download files and variants]({prefix}/translation-studies.zip)\n'
    text += '\n<details class="full-program">\n<summary>Complete lesson.gd — online reference</summary>\n\n<!-- student-code:lesson.gd -->\n```gdscript\n' + source + '```\n\n</details>\n'
    for state, script in [('direct', direct), ('complete', source)]:
        put(HERE / state / 'lesson.gd', script)
        put(HERE / state / 'box_body.gd', (HERE / 'incoming/box_body.gd').read_text(encoding='utf-8'))
    put(CANONICAL, text)
    put(HERE / 'tutorial.md', text)
    put(HERE / 'final.md', (ROOT / 'commons/maps/Trans_Translation/final.md').read_text(encoding='utf-8'))
    put(HERE / 'edits.json', json.dumps(dict(edition='2026-10-16', predecessor='doc/book/iterations/2026-10-16-transformation-handoff/Trans_Introduction', operations=operations), indent=2) + '\n')
    print('Prepared Translation: five printed edits; unchanged BoxBody and box(); two runnable checkpoints.')

if __name__ == '__main__': main()
