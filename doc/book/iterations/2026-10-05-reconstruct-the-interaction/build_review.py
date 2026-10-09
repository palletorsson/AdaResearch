"""Build the single-interaction writing pilot and its compact source contract."""
from pathlib import Path
from hashlib import sha256
from html import escape
import json
import shutil
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PREFIX = HERE.relative_to(ROOT).as_posix()
BRIEF = dict(
    make="Black sphere; grab, carry, release in place.",
    bring="_ready; variables; mesh/node; collider; local position.",
    given="Museum; configured XR hand; XRToolsPickable; collision settings; black material settings.",
    build="Body; matching mesh/shape; direct refs; frozen release.",
    check="Hold moves both; release stays; disabled refuses; new radius matches.",
    later="Grip pose; trigger action; labels; coordinate readouts.")


def main():
    code = (HERE/'point.gd').read_text(encoding='utf-8').strip()
    brief = '\n'.join(k.upper()+': '+v for k,v in BRIEF.items())+'\n'
    (HERE/'brief.txt').write_text(brief,encoding='utf-8')
    lesson = '''# Make a point the hand can carry

**Learning elements**

- Pickable body
- Shared mesh and collision dimensions
- Frozen release

Take the black point. Move your hand. Release it.
The point stays where you left it.
Reconstruct that interaction with one small body.

Point One gave you a mesh and a collider.
Here they become children of a pickable body.
The prepared XR hand supplies tracking and grabbing.
Your code supplies the object it can hold.

Use an empty `Node3D` as your station in a working copy of the prepared museum.
Place it at the exercise position, with scale `(1, 1, 1)`.
Attach `point.gd` below. It creates the point 1.12 metres above that station.
No sphere, collider or point scene needs to be added by hand.

The museum supplies the lit room and configured XR Tools player.
Use the collision and material settings shown here.
Their detailed configuration belongs to later lessons.

## Build the whole small object

```gdscript
''' + code + '''
```

`point` keeps a reference to the body your code creates.
`XRToolsPickable` adds the toolkit's grab behaviour to a physics body.
It does not create the sphere's surface or shape for you.

`surface.mesh = sphere` gives the visible node its geometry.
`collider.shape = shape` gives the collision node its boundary.
Both use `RADIUS`. Both belong to `point`, so both move with it.

`freeze` keeps the waiting point in place.
`ReleaseMode.FROZEN` also keeps it in place after release.
`RangedMethod.NONE` asks the hand to come close before grabbing.
The museum point restores its original frozen setting; this smaller version declares frozen release directly.

The layer values connect this body to the prepared collision setup.
`4` selects the pickable layer; `196615` is the museum's existing collision mask.
Keep those supplied values for this exercise.

The final `add_child(point)` puts the completed body into the scene tree.
Its inherited setup then remembers the configured collision settings.
The hand's existing pickup function can find and move it.
You do not need to write another tracking loop.

## Predict, try, explain

Run your working copy. Bring the hand close, grab, move, release.
The surface and boundary move together. The released body stays.

Choose another `RADIUS` and run again.
Predict the new visible radius and collision radius before grabbing.
Explain why one value changes both.

Then add `point.enabled = false` before `add_child(point)`.
Predict the difference. The sphere still exists, but refuses pickup.
Remove that line when finished.

Rebuild the object once from the short brief, without the full listing.
Name what your code creates and what the toolkit supplies.
Record where you needed help; those gaps guide the next explanation.

This construction ends at pickup and release.
The next part of Coordinates must connect this point to a named frame and readout.
Its current museum wall cards are not automatically connected to this new body.
'''
    (HERE/'tutorial.md').write_text(lesson,encoding='utf-8')
    sources = [
        'commons/primitives/point/point_condition.gd',
        'commons/primitives/point/interactive_point_origin.tscn',
        'addons/godot-xr-tools/objects/pickable.gd',
        'addons/godot-xr-tools/objects/pickable.tscn',
        'addons/godot-xr-tools/functions/function_pickup.gd',
    ]
    contract = dict(map='Point_Coordinates', focus='Pickup/release reconstruction; first part only',
                    brief=BRIEF,
                    host='Empty unit-scale Node3D station in a working copy of the lit Endless Museum with its configured XR Tools hand. Native proof uses a private test world, not a museum placement.',
                    lesson=PREFIX+'/tutorial.md', example=PREFIX+'/point.gd', native_report=PREFIX+'/report-runtime.json',
                    sources=[dict(path=s,sha256=sha256((ROOT/s).read_bytes()).hexdigest()) for s in sources],
                    checks=[
                        dict(id='constructed',kind='native',action='Run the printed script.',expect='A pickable body owns matching sphere mesh and collision shape.'),
                        dict(id='eligible',kind='native',action='Bring the real library detector near; then disable the point.',expect='Overlap allows selection; disabled point refuses it.'),
                        dict(id='carry-release',kind='native',action='Pick up, move synthetic controller, drop and move controller again.',expect='Body follows while held; release restores configured layers and stays frozen.'),
                        dict(id='new-radius',kind='native',action='Run code with a different RADIUS.',expect='Visible mesh and physical shape have the new matching radius.'),
                        dict(id='reconstruct',kind='learner',action='Rebuild from brief; record help used.',expect='Learner can assemble required parts and name supplied support.'),
                        dict(id='explain',kind='learner',action='Predict changing radius versus disabling pickup.',expect='Explain shared dimensions separately from interaction eligibility.'),
                        dict(id='placed',kind='museum',action='Place the exercise station beside the encounter in a working museum copy.',expect='Reachable and visible; no accidental dependence on the original point or wall readouts.'),
                        dict(id='hand',kind='headset',action='Use physical hand/controller to grab, move and release.',expect='The selected behaviour works with the prepared player and is comfortable to perform.')])
    (HERE/'contract.json').write_text(json.dumps(contract,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    shutil.copy2(ROOT/'doc/book/iterations/2026-10-03-coordinates-existing-point/held-point.png',HERE/'museum-point.png')
    runtime=json.loads((HERE/'report-runtime.json').read_text(encoding='utf-8'))
    report='''# A tutorial should leave a capability

5 October 2026. One writing pilot, using the grabbable point.

The current Coordinates lesson explains the existing object and offers small edits. It does not supply the complete construction of its pickable sphere. We were testing source fidelity and parameter changes while asking the lesson to build a more substantial capability.

The new pilot makes that capability explicit: **construct a sphere the prepared hand can grab, carry and release in place.** It prints the complete 34-line construction and declares its support. The XR toolkit remains supplied; creating the body, mesh, collider and their relation is the learner's work.

## Compact instruction for a future writer

```text
''' + brief + '''```

This is the first part of Coordinates, not a removal of its local/world teaching. The frame and readout need their own explicit construction or declared connection when that part is revised. No full lesson replacement is promoted by this pilot.

## What the tests say

- Native code: 30 checks passed using the real XR Tools library and a synthetic controller in an isolated Godot project.
- Tested: construction, dimensions at two radii, near-grab detection, disabled rejection, pickup, held movement, release and collision-setting restoration.
- Not yet tested: placement of this exercise in the museum, physical headset input, beginner reconstruction or explanation.
- The photographed point is the existing museum artifact, captured 3 October. It is not a render of this prototype.

The six structural negative controls cover missing support, stale support, incomplete printed code and stale native evidence. These checks prevent a false green result in those cases; they do not score the quality of prose.

A separate source review found and corrected the current tutorial's Z-arm claim: the drawn black arm points toward negative Z. Museum code and reflective text were not changed.

## What guides the next draft

Keep a sentence when it helps the student build, observe, explain or transfer the selected operation. State the supplied boundary. More code is warranted when it closes a missing construction step. Extra code that implements another interaction can wait.

Use [the framework](../../course/functional_text/RECONSTRUCTION.md), then [read the pilot lesson](tutorial.md). The full example is [point.gd](point.gd). [Native evidence](report-runtime.json) and [contract check](check-report.json) keep their claim scopes separate.
'''
    (HERE/'REPORT.md').write_text(report,encoding='utf-8')
    css='''*{box-sizing:border-box}body{margin:0;background:#f3efe7;color:#272d2f;font:16px/1.65 system-ui,sans-serif}main{max-width:1180px;margin:auto;padding:48px 28px}h1,h2,h3{font-family:Georgia,serif;font-weight:400;line-height:1.15}h1{font-size:52px;max-width:18ch}h2{font-size:33px;margin-top:36px}p{max-width:76ch}a{color:inherit;text-underline-offset:4px}nav{display:flex;flex-wrap:wrap;gap:22px;border-block:1px solid #c8c1b8;padding:15px 0;margin-bottom:35px;font-size:13px}pre{padding:22px;background:#253035;color:#f5eee7;overflow:auto;font:14px/1.65 Consolas,monospace}code{font-family:Consolas,monospace;font-size:.88em}img{width:100%;display:block}figure{margin:32px 0}figcaption,.small{font-size:12px;color:#706b66}.brief{background:#e9dfd4;padding:24px}.brief pre{margin:0}.reading{max-width:82ch;margin:40px auto;background:#fffdf8;padding:32px 42px;border:1px solid #ddd4c8}.reading p{font:18px/1.7 Georgia,serif}.reading h1{font-size:36px}.reading h2{font-size:27px}.reading pre{margin-inline:-18px}.reading code{overflow-wrap:anywhere}.reading pre code{overflow-wrap:normal}.status{padding:20px 25px;border-left:4px solid #a35e7e;background:#eee3e7}.status p{margin:6px 0}.evidence{font-size:13px}a:focus-visible{outline:3px solid #a35e7e;outline-offset:4px}section{scroll-margin-top:20px}@media(max-width:700px){main{padding:24px 16px}h1{font-size:39px}.reading{padding:22px}.reading pre{margin-inline:0;font-size:12px}.brief{padding:12px}}@media print{nav{display:none}main{padding:0}.reading{border:0;padding:0;break-before:page}pre{white-space:pre-wrap}figure{break-inside:avoid}}'''
    html=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Ada · Can the student make it?</title><style>{css}</style></head><body><main>
<p class="small">ADA / RECONSTRUCTION PILOT / 5 OCTOBER 2026</p><h1>Can the student make the interaction?</h1>
<nav><a href="#brief">Short brief</a><a href="#reading">Read the trial lesson</a><a href="#evidence">What passed</a><a href="../../course/functional_text/RECONSTRUCTION.md">Writing framework</a></nav>
<p>The lesson's object is a capability. This pilot asks for one: build a sphere that the prepared hand can grab, carry and release in place.</p>
<figure><img src="museum-point.png" alt="The existing black point held beside the basin coordinate frame in the museum"><figcaption>Existing museum encounter · 3 October 2026. This photograph shows the reference artifact, not the new code example.</figcaption></figure>
<section id="brief"><h2>Six lines hold the focus.</h2><div class="brief"><pre>{escape(brief)}</pre></div><p>The complete code below unfolds BUILD. The explanation tells the learner how its parts cause the selected behaviour. Coordinates' local/world teaching remains the next part.</p></section>
<section id="reading" class="reading">{markdown.markdown(lesson,extensions=['fenced_code'])}</section>
<section id="evidence"><h2>Test the construction. Then test the teaching.</h2><div class="status"><p><b>{len(runtime['checks'])} native checks passed.</b> Real pickup library, synthetic controller, isolated Godot project.</p><p>Museum placement, physical headset input and beginner learning are not yet tested.</p></div><div class="evidence">{markdown.markdown(report.split('## What guides the next draft',1)[1],extensions=['fenced_code'])}<p><a href="REPORT.md">Full assessment</a> · <a href="contract.json">Declared contract</a> · <a href="brief.txt">Compact brief</a> · <a href="tutorial.md">Tutorial draft</a></p><p>Only this sub-lesson is piloted. The existing museum is unchanged; the canonical tutorial received the separate Z-direction correction.</p></div></section></main></body></html>'''
    (HERE/'index.html').write_text(html,encoding='utf-8')
    print('Built compact brief, one complete tutorial pilot, contract and review page.')


if __name__=='__main__':
    main()
