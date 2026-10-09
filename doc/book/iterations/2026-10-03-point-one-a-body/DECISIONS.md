# Point One — one lesson in the shared world

3 October 2026. Author review copy; beginner reading has not yet been tested.

The current museum corridor supplies the distinction: a position without a surface, a surface without collision, then a visually identical point with collision. The tutorial constructs those three cases in the Day Zero student room. It reads the construction in `commons/primitives/point/point_condition.gd`; it does not reproduce the artifact's variant selector, decorative material, labels or museum reporting.

## Inherit

Day Zero's room, light and desktop/XR player. Point Zero's node, variable, `.new()`, `_ready()`, assignment and `add_child()`.

## Introduce or deepen

- A variable can hold a position value or a reference to an object. `Vector3` holds the three position components; only height is varied here. Full axes and reference-frame reading follow in Coordinates.
- A `float` holds the radius. Multiplication makes the full height twice that radius.
- A mesh resource and a node displaying that resource have different roles. `SphereMesh` supplies the sphere's geometry; its tessellation is still inherited from Godot.
- A physics body, collision shape node and shape resource construct contact separately from appearance. Matching radii are an authored relation. One variable can keep them matched; separate values can make them disagree.

The signature of the lesson is: supplied view and moving body → named position → visible marker → independently editable collision. Each arrow has an executable construction and a learner action.

## Leave for later

Grabbing, controller bindings and full coordinates belong to Point Coordinates. Distance belongs to Lines. Ordered storage and a loop belong to Trace. Lighting, mesh generation and material programming return where they matter. The museum's switch and final large point can carry the critical text without becoming extra coding tasks here.

## Deliver

`commons/maps/Point_One/tutorial.md` is the canonical revised lesson. The starter includes the matching tutorial and three complete scripts under `studies/point_one/`, with the familiar prepared room instanced by `point_one.tscn`. The printed collision block is explicitly the added tail of `_ready()`; the downloadable `solid.gd` is complete. No teaching script uses a node-path lookup or a toolkit dependency. Each can be attached to a bare Node3D in another prepared scene.

The old fixed-camera Point One study remains as an earlier companion; it is not the current download. `final.md` and the live museum map are unchanged. Existing numeric course sections and their old taxonomy checker are not silently reclassified. The local lesson contract and source/API checks document this pilot's actual scope.

The shared room gains one setup-check option so this lesson can leave out the counter panel, pickup cube and plinth. Day Zero retains them. Its movement and pickup regression checks are rerun because the shared room changed.

Physics contact in the desktop test does not certify physical headset behaviour or haptic resistance. Virtual collision constrains virtual locomotion; it cannot restrain a real hand or tracked head.
