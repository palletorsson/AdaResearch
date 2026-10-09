"""Author a bounded class extraction; preserve previous lesson evidence."""
from pathlib import Path
import hashlib
import json
import re
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OLD_LINES = ROOT / 'doc/book/iterations/2026-10-05-lines-from-the-carried-point/student'
OLD_TRACE = ROOT / 'doc/book/iterations/2026-10-05-trace-the-carried-point/student'

def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8', newline='\n')

def change(text, before, after):
    assert text.count(before) == 1, before
    return text.replace(before, after, 1)

def main():
    assert not (HERE / 'before').exists(), 'Preserve the first snapshot; do not rerun authoring.'
    for name in ('Point_Lines', 'Point_Trace'):
        p = ROOT / f'commons/maps/{name}/tutorial.md'
        write(HERE / 'before' / f'{name}.md', p.read_text(encoding='utf-8-sig'))
    protected = [ROOT / f'commons/maps/{name}/{file}' for name in ('Point_One', 'Point_Coordinates', 'Point_Lines', 'Point_Trace') for file in ('final.md', 'map_data.json')]
    protected += [ROOT / f'commons/maps/{name}/tutorial.md' for name in ('Point_One', 'Point_Coordinates')]
    for folder in (OLD_LINES.parent, OLD_TRACE.parent):
        protected += [p for p in folder.rglob('*') if p.is_file() and '__pycache__' not in p.parts]
    hashes = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in protected if p.exists()}
    write(HERE / 'protected-before.json', json.dumps(hashes, indent=2) + '\n')
    for rel in ('doc/book/course/hall-cards/lineage-opening.json', 'doc/book/course/storyboards/opening.json', 'doc/book/course/storyboards/CONTEXT.md'):
        p = ROOT / rel
        write(HERE / 'before' / p.name, p.read_text(encoding='utf-8-sig'))

    original = (OLD_LINES / 'line.gd').read_text(encoding='utf-8-sig')
    construction = original[original.index('    point.freeze = true\n'):original.index('    add_child(point)\n')]
    body = 'extends XRToolsPickable\n\nconst RADIUS := 0.14\n\nfunc _init() -> void:\n' + construction.replace('point.', '').rstrip() + '\n'
    extraction = [
        {'id': 'move-radius-into-point-class', 'kind': 'replace', 'before': 'const RADIUS := 0.14\n', 'after': ''},
        {'id': 'load-point-class', 'kind': 'insert_after', 'anchor': 'const CENTRE := Vector3(0, 1.12, 0)\n', 'text': '\nconst PointBody = preload("point_body.gd")\n'},
        {'id': 'construct-class-instance', 'kind': 'replace', 'before': '    point = XRToolsPickable.new()\n', 'after': '    point = PointBody.new()\n'},
        {'id': 'move-construction-into-point-class', 'kind': 'replace', 'before': construction, 'after': ''},
    ]
    write(HERE / 'extraction.json', json.dumps(extraction, indent=2) + '\n')
    class_intro = '''## Give the familiar point a class — point_body.gd

We have already built a sphere with a matching boundary and made it pickable. Move those instructions into `point_body.gd`. A class gives us a repeatable construction: each call to `PointBody.new()` makes a separate point.

<!-- student-code:point_body.gd -->
```gdscript
''' + body + '''```

`extends XRToolsPickable` keeps the pickup behaviour supplied by XR Tools. Our class adds the sphere, its collider and the settings chosen in Coordinates. Inside this file, `add_child(surface)` attaches the surface to this point; there is no outer `point.` prefix.

`_init()` runs when we call `.new()`. It builds the point before the lesson adds it to the scene. We leave XR Tools' `_ready()` in place. The lesson has its own `_ready()` for placing the points and creating the readout.

Each instance gets its own mesh and collision shape. They begin with the same dimensions, but they are separate objects. The class contains no endpoint relation or trace: those belong to the lesson using it.

'''
    for hall, filename, evidence in (('Point_Lines', 'line.gd', 'lines'), ('Point_Trace', 'trace.gd', 'trace')):
        path = ROOT / f'commons/maps/{hall}/tutorial.md'
        text = path.read_text(encoding='utf-8-sig')
        # Apply the extraction only to the complete lesson block.
        pattern = r'(<!-- student-code:' + re.escape(filename) + r' -->\s*```gdscript\n)(.*?)(^```)'
        match = re.search(pattern, text, re.M | re.S)
        code = match.group(2)
        for op in extraction:
            code = change(code, op.get('before', op.get('anchor')), op['after'] if op['kind'] == 'replace' else op['anchor'] + op['text'])
        if hall == 'Point_Lines':
            code = change(code, '    point_b = point.duplicate() as XRToolsPickable\n', '    point_b = PointBody.new()\n')
        text = text[:match.start(2)] + code + text[match.end(2):]
        if hall == 'Point_Lines':
            text = text.replace('- Reusing an object', '- A class and its instances')
            text = change(text, 'We will copy the point once and draw the relation between the two bodies.', 'We will put its familiar construction in a class, make two instances, and draw the relation between them.')
            text = change(text, 'Save the continued script below as `line.gd` beside the supplied `line_skin.gd`, also printed below.', 'Save `point_body.gd`, `line.gd` and `line_skin.gd` together. All three files are printed below; only the drawing helper is supplied.')
            text = change(text, '## The complete continuation — line.gd', class_intro + '## The complete continuation — line.gd')
            text = change(text, "The new parts are `LineSkin`, `point_b`, `line` and `distance`; the second body's construction; and the relation read each frame. Everything that built the first point in Coordinates stays in place.", 'The point construction now lives in `point_body.gd`. This smaller lesson places two instances and reads their relation each frame. The coordinate readout stays here.')
            text = change(text, '## A copy, then a relation', '## One class, two instances')
            text = change(text, '`point.duplicate()` copies our existing body and its children. `as XRToolsPickable` tells Godot which type of copy we expect. B has its own position and can be held independently. Its mesh and shape resources are shared with the original; we are moving bodies, not editing those resources.', '`preload("point_body.gd")` loads our script class and gives it the local name `PointBody`. Calling `.new()` twice makes two instances. They share the construction and inherited pickup behaviour; each has its own position, surface and collider. Carry A, then B. Moving one must leave the other where you put it.')
            text = text.replace('defined in the second file', 'printed below')
            text = change(text, 'Coordinates already produced `local_position`', 'The class holds what makes this a pickable point. The station holds what makes these two points a line. We can later extend point behaviour in one file without moving distance calculations or a position history into it.\n\nCoordinates already produced `local_position`')
            text += '\nClass reference: [GDScript classes and constructors](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#class-constructor).\n'
        else:
            text = text.replace('- Arrays of positions', '- Reusing the point class\n- Arrays of positions', 1)
            text = change(text, 'Keep the original point, its mesh, collider, pickup settings and coordinate readout.', 'Keep the `PointBody` class from Lines, with its mesh, collider and pickup settings, and keep the coordinate readout.')
            text = change(text, 'as `trace.gd` beside the same `line_skin.gd`.', 'as `trace.gd` beside the unchanged `point_body.gd` and `line_skin.gd`.')
            text = change(text, '## An array keeps an order', '`PointBody.new()` makes the familiar point. Its class needs no change for this lesson: the recorder reads its position. The array belongs to this study, so later we can keep the record or change its drawing without changing the point.\n\n## An array keeps an order')
            section = '## The carried point — point_body.gd\n\nKeep this file unchanged from Lines. It is repeated here so the complete example is visible; it creates the same body and inherits the same pickup behaviour.\n\n<!-- student-code:point_body.gd -->\n```gdscript\n' + body + '```\n\n'
            text = change(text, '## The drawing helper — line_skin.gd', section + '## The drawing helper — line_skin.gd')
            text = text.replace('these two files are sufficient', 'these three files are sufficient')
        text = re.sub(r'\[Download ' + filename + r'\].*?\[Complete experiments and tests\]\([^\n]+\)', '[Download ' + filename + '](../../../doc/book/iterations/2026-10-05-point-a-reusable-class/' + evidence + '/' + filename + ') · [Download point_body.gd](../../../doc/book/iterations/2026-10-05-point-a-reusable-class/' + evidence + '/point_body.gd) · [Download line_skin.gd](../../../doc/book/iterations/2026-10-05-point-a-reusable-class/' + evidence + '/line_skin.gd) · [Complete experiments and tests](../../../doc/book/iterations/2026-10-05-point-a-reusable-class/index.html)', text)
        write(path, text)
        for name in ('run_checks.py', 'verify.gd'):
            write(HERE / evidence / name, ((OLD_LINES if evidence == 'lines' else OLD_TRACE) / name).read_text(encoding='utf-8-sig'))
    print('Two tutorials revised; earlier evidence snapshotted and untouched.')

if __name__ == '__main__':
    main()
