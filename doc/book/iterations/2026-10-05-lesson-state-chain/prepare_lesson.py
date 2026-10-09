"""Prepare a continuation pilot; never repair its code after applying the edits."""
from pathlib import Path
from hashlib import sha256
from textwrap import dedent
import json
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PREFIX = HERE.relative_to(ROOT).as_posix()
sys.path.insert(0, str(ROOT/'doc/book/course/functional_text'))
from reconstruction import compose

BRIEF = dict(
    make='Existing point: grab, carry, release in place.',
    bring='Point One state: sphere surface + matching static boundary.',
    given='Museum XR hand; pickup library; collision settings.',
    build='Swap body class; configure pickup; parent existing surface.',
    check='Same shape/place; surface and boundary follow; release stays.',
    later='Grip alignment; actions; coordinate readouts.')
OPERATIONS = [
    dict(id='body-class', kind='replace', before='\tvar solid := StaticBody3D.new()\n',
         after='\tvar solid := XRToolsPickable.new()\n'),
    dict(id='pickup-settings', kind='insert_after', anchor='\tsolid.position = centre\n', text=(
        '\tsolid.freeze = true\n'
        '\tsolid.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC\n'
        '\tsolid.release_mode = XRToolsPickable.ReleaseMode.FROZEN\n'
        '\tsolid.ranged_grab_method = XRToolsPickable.RangedMethod.NONE\n'
        '\tsolid.collision_layer = 4\n'
        '\tsolid.collision_mask = 196615\n')),
    dict(id='carry-visible-surface', kind='insert_after', anchor='\tadd_child(solid)\n',
         text='\tbody.reparent(solid)\n'),
]


def block(code):
    return '```gdscript\n'+dedent(code).strip()+'\n```'


def main():
    brief = '\n'.join(k.upper()+': '+v for k,v in BRIEF.items())+'\n'
    (HERE/'brief.txt').write_text(brief, encoding='utf-8')
    lesson = '''# Continue with the point

**Learning elements**

- Pickable body
- Parent and child movement
- Pickup and release

Continue with the solid point from Point One. Its surface and collision shape already exist. Keep their size, material and position. We will change what your hand can do with this point.

The prepared museum supplies the XR hand and its pickup function. Your code makes the point available to that hand.

For this pilot, edit [incoming.gd](incoming.gd), attached to a `Node3D` station in a working copy with the museum's configured XR player. It collects Point One's small solid-point construction into one file. `body` refers to its visible mesh; `solid` refers to its physics body. Both are local variables inside `_ready()`. Keep these changes in that function.

## Give the existing boundary pickup behaviour

Replace this line:

'''+block(OPERATIONS[0]['before'])+'''

with:

'''+block(OPERATIONS[0]['after'])+'''

`XRToolsPickable` is the toolkit's physics body with pickup behaviour. The existing collision shape still belongs to `solid`. You do not make another sphere or write a hand-tracking loop.

Immediately after its position assignment, add the settings below:

'''+block(OPERATIONS[1]['anchor']+OPERATIONS[1]['text'])+'''

The first three added lines keep the point still while waiting and after release. Kinematic freezing lets the grab driver move it. `RangedMethod.NONE` requires the hand to come close. The last two lines use the museum's supplied collision settings: layer 3 for pickable objects, with the existing mask for their collisions.

These assignments must run before `add_child(solid)`. When the body enters the scene tree, XR Tools remembers its collision settings for release.

## Make the surface travel with the boundary

At the end of the construction, add one line after the existing `add_child(solid)`:

'''+block(OPERATIONS[2]['anchor']+OPERATIONS[2]['text'])+'''

Point One placed the surface and physics body separately. `reparent` moves the existing surface under `solid` in the scene tree. Both nodes are already in the tree, so this call keeps the surface's world position. It does not jump or make a copy. When the hand moves `solid`, its surface and collider move together.

Run the working copy. Bring your hand close, grab, move and release. The sphere follows your hand and stays where you leave it.

## Check what changed

Predict what would happen without the `reparent` line. Try it, then restore it. Which part moves, and which part stays?

Choose a different value for `RADIUS`, using what Point One taught. Predict what will change. Check that the surface and boundary still agree while held. No second sphere-construction example is needed here: you are extending the same one.

Carry this changed code forward. The next part of Coordinates can use the same moving point to examine local and world positions. This pilot ends at pickup and release; it has not connected the museum's coordinate readouts to this fixture.
'''
    (HERE/'tutorial.md').write_text(lesson, encoding='utf-8')
    inputs = [PREFIX+'/'+name for name in (
        'incoming.gd','expected.gd','assembled.gd','tutorial.md','contract.json','verify.gd','run_checks.py')]
    inputs += ['doc/book/course/functional_text/reconstruction.py']
    source_paths = ['commons/maps/Point_One/tutorial.md', 'commons/primitives/point/point_condition.gd',
                    'addons/godot-xr-tools/objects/pickable.gd',
                    'addons/godot-xr-tools/functions/function_pickup.gd']
    outcomes = [
        ('incoming/not_pickable','Try the incoming point','No pickup method on the static body.'),
        ('outgoing/no_duplicate_point','Apply the printed edits','One surface and one collider remain.'),
        ('outgoing/pose_preserved','Run under a translated, rotated station','Surface and collider retain their incoming world pose.'),
        ('outgoing/appearance_and_geometry_preserved','Compare before and after','The existing material, mesh and collision dimensions remain.'),
        ('outgoing/settings_before_ready','Enter the tree','The configured collision layers were cached.'),
        ('outgoing/near_eligible','Bring the controller close','Real overlap makes the point available for pickup.'),
        ('outgoing/disabled_not_eligible','Disable pickup','The point cannot be selected.'),
        ('outgoing/held','Grab','The library holds the point.'),
        ('outgoing/held_mesh_follows','Move the controller','The visible surface follows.'),
        ('outgoing/held_collider_follows','Move the controller','The physical boundary follows.'),
        ('outgoing/same_instances','Hold and move','The original surface and collider instances remain.'),
        ('outgoing/released','Release','The library clears the grab.'),
        ('outgoing/release_restores','Release','Frozen state and configured collision layers return.'),
        ('outgoing/release_stays','Move the empty hand','The released point stays.'),
    ]
    contract = dict(
        version=2, mode='continuation', brief=BRIEF,
        lesson=PREFIX+'/tutorial.md', example=PREFIX+'/assembled.gd',
        host='Node3D station in prepared museum working copy; native test uses an isolated XR Tools copy and synthetic controller.',
        incoming=dict(path=PREFIX+'/incoming.gd', sha256=sha256((HERE/'incoming.gd').read_bytes()).hexdigest(),
            provenance='Explicit assumed reconstruction from Point One excerpts and its small solid-point source. Current Point One lesson edits an existing museum script; it does not yet yield this standalone file. Names, material helper and subdivisions are retained source settings, not evidence of taught mastery.'),
        operations=OPERATIONS,
        sources=[dict(path=p, sha256=sha256((ROOT/p).read_bytes()).hexdigest()) for p in source_paths],
        checks=[dict(id=radius+'/'+suffix, action=action, expect=expect, kind='native')
                for radius in ('radius_014','radius_030') for suffix,action,expect in outcomes]
            + [dict(id='explain-ownership',action='Predict, remove and restore reparent',expect='Learner explains separate visual and physical movement.',kind='learner'),
               dict(id='transfer-radius',action='Choose a new radius without the complete listing',expect='Learner preserves matching dimensions and working pickup.',kind='learner')],
        evidence_inputs=inputs, native_report=PREFIX+'/report-runtime.json')
    (HERE/'contract.json').write_text(json.dumps(contract,indent=2)+'\n',encoding='utf-8')
    incoming = (HERE/'incoming.gd').read_text(encoding='utf-8')
    (HERE/'assembled.gd').write_text(compose(incoming,OPERATIONS),encoding='utf-8')
    print('Prepared tutorial, brief, contract and mechanically assembled.gd. Runtime evidence requires run_checks.py.')


if __name__ == '__main__':
    main()
