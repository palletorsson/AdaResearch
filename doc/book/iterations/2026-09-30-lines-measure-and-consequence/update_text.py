from pathlib import Path
import json, os
def atomic_text(path, text, encoding='utf-8'):
    temporary = path.with_name(path.name+'.ada-tmp')
    temporary.write_text(text,encoding=encoding)
    os.replace(temporary,path)
ROOT = Path(__file__).resolve().parents[4]
MAP = ROOT / 'commons/maps/Point_Lines'
p = MAP / 'final.md'
s = (Path(__file__).parent/'before/commons/maps/Point_Lines/final.md').read_text(encoding='utf-8')
s = s.replace('Through the side passage, another line has acquired an instruction.', '''Can you find a span of one metre? Keep one end still and move the other around it. The segment turns while its length stays steady. We can describe that relation with two small operations:

```gdscript
var displacement := b - a
var distance := displacement.length()
```

The first keeps a direction as well as a distance. The second gives us the length alone. Reverse the subtraction and the direction reverses; the length stays the same. Your hand may keep moving while the rounded number on the wall appears still. A display has its own smallest difference.

Through the side passage: **CAN YOU CONNECT THE DOTS?**''')
s = s.replace('Two black points wait beside a barrier: **DO NOT CROSS.** Bring one close to the other, then let go.', 'Two black points wait beside a barrier: **DO NOT CROSS.** Bring one close to the other, then let go.')
s = s.replace("On the first connection, the demonstration calls the nearby barrier's `trigger_explosion()`. Someone joined those events in code.", "Connecting the points sends another instruction to the barrier. Someone joined those events in code.")
start = s.index('<!-- @line -->')
end = s.index('<!-- @walk_this_line_marking -->', start)
s = s[:start] + '''<!-- @redline -->

A red line marks another division. A colour can lend urgency to the same thin form. What, here, gives it the right to stop you?

Ahead, the instruction moves from a barrier to the floor.

''' + s[end:]
s = s.replace('## A body for the line\n', '## A body for the line\n\nAfter the crossing, the hall opens into four views: pairs, crosses, uprights and a grid. A familiar mark begins to acquire other uses.[^point-lines-ingold]\n')
s = s.replace('The hammer can break a rod; the pink gun leaves it coloured for a while.', '''Take the measuring laser. Its number ends at the body the beam meets. Keep it on a rod and the rod breaks; the reading reaches whatever lies behind it. The instrument that measured a distance has removed one of its limits.

The hammer can break these studies too; the pink gun leaves them coloured for a while.''')
s = s.replace('<!-- @ -->\n\nLook back', '''<!-- @anamorphic_cross -->

At the exit the passage narrows: **× + × + × +**. Cross the first X and your health falls.

<!-- @health_cross -->

The plus gives some back, opening into a brief scatter of light and a rising sound. Hurt, recovery, hurt, recovery. Two crossed lines can read as a refusal or an offer of care; here those associations have been given access to your body.

<!-- @ -->

Look back''')
atomic_text(p,s,encoding='utf-8')

atomic_text(MAP/'summary.md','''# Point Lines — measure, permission, passage

Fourth hall in Primitives, after Point_Coordinates and before Point_Trace. The first encounter is the 4 m black box: two held endpoints, a changing segment and a distance readout. Next, connecting the dots opens DO NOT CROSS. Walk the black stripe over the basin and compare its straightness with the player's recorded route.

The open gallery develops plus/X, parallel, vertical and grid relations through grabbable lines, perspective and ceiling-edge alignment. The held measuring laser and hammer can break the studies; they rebuild after eight seconds. The exit corridor alternates three damage Xs and three healing pluses, with a visible and audible recovery response.

The making companion introduces only displacement, distance and a segment that follows two known positions. Its complete portable study borrows the renderer. Arrays, adjacency lists and a new XR controller implementation are deferred. The main text follows what a line makes possible, asks who attached those consequences, and brings the missing journey forward into Trace.
''',encoding='utf-8')
atomic_text(MAP/'intent.md','''# Point Lines — current agreement, 30 September 2026

**Arrival:** Coordinates has supplied positions in a shared frame and a working hold. **New construction:** a segment between two positions; subtract endpoints, measure displacement length, update the visible relation. **Departure:** two endpoints do not remember the path; Trace will keep intermediate positions.

## Three related selections

- Reading: black-box measure → connect the dots / barrier → red division → walk and recorded trace → four views → laser's consequence → wall's limit → ×/+ passage.
- Hall: keep the authored 27 × 37 layout and its secondary comparisons. The primary route is not a quota of one artifact. Measuring instruments and recovery gates remain available; breakable studies restore after a short delay.
- Making: the small executable `doc/book/studies/point-lines` study uses two markers in one frame. New operations are subtraction and length. The cylinder renderer is supplied, named and available to inspect. The museum’s pickup, snapping, laser, damage and reset code is reference material, not an entrance exam for the learner.

The critical question grows from each operation: a connection opens a prohibition; a straight instruction meets a crooked walk; a tool removes what it measures; two crossed strokes acquire the power to harm or care. Preserve the pleasure of arranging lines in space. Do not turn every encounter into an implementation exercise.

Earlier intent and curation decisions remain in the dated review history. Current placement authority is map_data.json; final.md and tutorial.md are separate reading and making companions.
''',encoding='utf-8')
atomic_text(MAP/'technical.md','''# Point Lines — implementation reference

The beginner exercise is [tutorial.md](tutorial.md). This file records the hall’s working attachments.

## Segment and connection

`commons/artifacts/line_black_box/line_black_box.gd` builds the entrance, two held endpoints, a live readout and a reset. It uses `commons/primitives/line/line.gd` to draw their segment. `LineStudy` is the breakable target; the box, approach and reset remain outside that target.

`commons/primitives/snappoint/demos/line_demo.gd` listens to `SnapConnectionManager.connection_created`, recognises its own two points, and finds the nearest unbroken `DoNotCrossBarrier` in the same hall. The callback is deferred out of the physics flush. Disconnecting rearms the demonstration, so a rebuilt barrier can be opened again.

The barrier's visible body and collision boundary are suspended together by the shared reaction component. Restoration checks player occupancy before restoring physical collision. Its old permanent-destruction fallback remains for placements without a reaction component.

## A tool that reaches the study

Explicit `#reactive:break#rebuild:8` placements use `commons/interactables/artifact_reactions/router.gd` and `reaction.gd`. Tool-only surface proxies occupy physics layer 24; the original pickup and player shapes remain. The gallery exposes separate rods and fixed mesh studies. A strike does not erase all four views.

`laser_measure` raycasts bodies, reports the first hit, and accumulates 1.2 seconds of dwell on one target. An opt-in reaction requires a held laser. Desktop carry uses `desktop_hook_target` and grab/drop callbacks; XR uses the existing `is_picked_up()` state. Looking away or dropping cancels accumulated dwell. A placed instrument continues measuring.

The hammer takes three accepted strikes; the pink gun and catalyst tint. Breaks disable visibility, processing and collision, then restore the same instance after eight seconds. Architecture, reset controls and health services are kept usable.

## The exit corridor

Map cells x=12, z=29..34 hold × + × + × +. Their trigger depths are 0.42 m, separated by one-metre centres, so a body encounters them in order. `#passage:1` opts into corridor behavior without changing ordinary pickups elsewhere.

X composes DangerZone and accepts both the museum Walker and XR bodies. It takes 7 health on entry, then 14 every 0.6 seconds while occupied. This uses GameManager's direct damage operation: the generic museum route converts damage into a shared 33-point creature bite and can suppress the next gate with its cooldown. The passage keeps its own timing and uses the existing damage flash and health beep.

+ offers up to 21 health whenever the visitor is below full. It remains if no recovery can be delivered. A taken plus emits a generated spatial chime and twelve expanding strokes, and returns after eight seconds. No imported sound file or new audio service is needed.

## Portable construction

`doc/book/studies/point-lines/line.gd` places two markers once and reads them each frame. `segment.gd` owns cylinder length, midpoint and local-Y alignment; coincident endpoints hide the cylinder. Every node used by the lesson is supplied in `line.tscn` or the Day Zero base. It includes no XR rig.
''',encoding='utf-8')
d=json.loads((MAP/'map_data.json').read_text(encoding='utf-8'))
rows=['# Point Lines — current artifact inventory','', 'Primary reading: black-box measure → connection / barrier → stripe / trace → four views and laser → ×/+ exit.', '', 'Coordinates are source-map cells (x, z). Repeated instances remain individually listed; secondary placement does not require a passage in final.md.', '', '| Cell | Artifact |', '|---|---|']
for z,row in enumerate(d['layers']['interactables']):
    for x,c in enumerate(row):
        if c.strip(): rows.append(f'| {x}, {z} | `{c}` |')
atomic_text(MAP/'artifacts.md','\n'.join(rows)+'\n',encoding='utf-8')
old=(MAP/'encounter-reference.md').read_text(encoding='utf-8')
atomic_text(MAP/'encounter-reference.md','''# Current reference — 30 September 2026

Use [intent.md](intent.md), [technical.md](technical.md), [artifacts.md](artifacts.md) and map_data.json for the current path, implementation and placement. The black-box measure now comes first; the open gallery ends in three ×/+ pairs. The shared break system restores studies. The earlier reference below records prior arrangements and questions for return, not the current required path.

---

'''+old,encoding='utf-8')
