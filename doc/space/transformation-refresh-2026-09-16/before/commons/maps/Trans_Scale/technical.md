# A bounded tenfold change

The source token is `scale_me:0:0:1#encounter:drink_me#plinth:0`. `algorithms/primitives/scaleme/scale_me.gd` detects that configuration before binding the legacy target and builds `drink_me_room.gd`. Unconfigured scale_me instances retain their legacy behavior.

`Room` owns the architecture and the two seeded dream figures. It begins six metres wide and deep, with a 3.2-metre ceiling. Its floor sits 4 cm above the museum deck to avoid coincident surfaces. Its far-side door is a genuine gap between colliders, 0.18 by 0.24 metres. The entrance is 1.4 by 2.4 metres.

The food tower uses spread=blooming and service=tower; the crystal suit uses crust=spire and panels=leaning. Sculpture meshes are combined into one static concave collision shape per sculpture. Thirteen visible porcelain serving plates have matching cylinder colliders. Their tops descend from 1.76 m in 0.135 m increments, becoming drops of 1.35 m after scaling.

`drink_me_bottle.gd` extends XRToolsPickable. VR picked_up resolves the grabbing controller's player body. Desktop uses the shared pointer's optional on_desktop_grab callback and resolves its owning CharacterBody3D. Both defer consumption, release the hand, hide/disable the bottle, and call the same encounter operation. Mere proximity does not trigger it.

```gdscript
room.scale = Vector3.ONE * FACTOR
var feet := table.to_global(landings[0]) + Vector3.UP*0.08
```

FACTOR is 10. After the physics frame updates, XRToolsPlayerBody.teleport moves the VR body and origin together; desktop moves the character transform. Velocity is cleared. The body, museum, locomotion and gravity remain unchanged. There is no timed reversal; the encounter resets when the hall is freshly loaded.

The museum reserves a 65-by-69-cell hall for the expanded footprint. This is a gallery, without an embedded grid basin. An optional em_visibility_bounds metadata AABB tells museum distance culling to measure from the expanded room boundary instead of its now-distant placement anchor.

Verification: commons/testing/probe_drink_me_room.gd loads the actual museum hall, takes the bottle through the desktop pointer, checks both door sizes against a body capsule, scale boundaries, arrival clearance, landing collision, descent and visibility near the exit. Headset comfort and learner discovery remain to be walked by a person.
