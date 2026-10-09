# A bounded fourfold change

The source token is `scale_me:0:0:1#encounter:drink_me#plinth:0`. `algorithms/primitives/scaleme/scale_me.gd` detects that configuration before binding the legacy target and builds `drink_me_room.gd`. Unconfigured scale_me instances retain their legacy behavior.

`Room` owns the architecture and the two seeded dream figures. It begins four metres wide and deep, with a 3.2-metre ceiling. Its floor sits 4 cm above the museum deck to avoid coincident surfaces. Its far-side door is a genuine gap between colliders, 0.45 by 0.60 metres. The entrance is 1.4 by 2.4 metres.

The food tower uses spread=blooming and service=tower; the crystal suit uses crust=spire and panels=leaning. Sculpture meshes are combined into one static concave collision shape per sculpture. Thirteen visible porcelain serving plates have matching cylinder colliders. Their tops descend from 1.76 m in 0.135 m increments, becoming drops of 0.54 m after scaling.

`drink_me_bottle.gd` extends XRToolsPickable. VR picked_up resolves the grabbing controller's player body. Desktop uses the shared pointer's optional on_desktop_grab callback and resolves its owning CharacterBody3D. Both defer consumption, release the hand, hide/disable the bottle, and call the same encounter operation. Mere proximity does not trigger it.

```gdscript
room.scale = Vector3.ONE * FACTOR
var feet := table.to_global(landings[0]) + Vector3.UP*0.08
```

FACTOR is 4. The scale assignment is instantaneous; there is no interpolation through intermediate sizes. After the physics frame updates, XRToolsPlayerBody.teleport moves the VR body and origin together; desktop moves the character transform. Velocity is cleared. The body, museum, locomotion and gravity remain unchanged. There is no timed reversal; the encounter resets when the hall is freshly loaded.

The source map reserves a 21-by-22-cell hall for the 16-by-16-metre expanded room. Its fixed structure-4 wall spans row 2 except cells 9–11, where the small room's own entrance remains accessible. The wall joins that room to the hall sides, preventing a forward bypass around its exterior. It intersects the room front only, leaving the expanded interior and far exit clear. This wall is outside the scaled hierarchy. The standalone spawn is `s` at (10,0), with `utility_definitions.s.properties.player_rotation = 180`; `sp` would create a score point, not a spawn. Its continuous museum floor remains underneath, 4 cm below the room floor, and supports entry and exit at both states. This is a gallery, without an embedded grid basin. An optional em_visibility_bounds metadata AABB tells museum distance culling to measure from the expanded room boundary instead of its now-distant placement anchor.

A separate `UnscaledDoorway` is a sibling of `Room`, never a descendant. Its 1.8-by-2.4-metre opening lines up just beyond the expanded exit. Both admit the same body after the change, but only the room doorway has been multiplied. This fixed comparison makes the transform hierarchy visible.

Verification: commons/testing/probe_drink_me_room.gd loads the actual museum hall, takes the bottle through the desktop pointer, checks both door sizes against a body capsule, scale boundaries, arrival clearance, landing collision, descent and visibility near the exit. Headset comfort and learner discovery remain to be walked by a person.


## Shared book illustration — 23 September

The chapter's paired door image comes from the actual museum encounter before and after taking the bottle through the desktop pointer. Both cameras sit 1.65 m above the room floor and 2.5 m in front of the opening, look toward a point 1.2 m above its centre, and use the same 70-degree field of view. Camera position follows the doorway when the room grows; camera height, viewing distance and pitch do not scale. The second gold frame visible beyond the enlarged door retains its original world transform.

`tools/probes/scale_book_illustrations.gd` records those views and checks a 0.44 m wide, 1.6 m high capsule before and after the change. A hypothetical fourfold body is only a probe comparison, not a new visitor control. No room, sculpture, map or runtime behavior changed. The earlier full serving-plate descent remains historical evidence; this illustration pass does not rewalk it.

[Full reading, paired image and scope](../../../doc/book/iterations/2026-09-23-scale-door-and-body/index.html).


<!-- study-spine:reference_passage -->

## Installed application: Who fits through?

`reference_passage` occupies a new adjoining bay, after the existing encounters. Cell [10, 30], rotation 180°, museum adapter `res://commons/artifacts/spine_studies/passage.tscn`. Original response to Mirosław Bałka; no claim of exact reconstruction.

Change opening width while keeping the body and opening height. Reuses coordinates, transform; adds no prerequisite node. The display and main-player controls are supplied.
