# A body for a position — implementation

The opening comparison is point_condition.gd: absent, visible, solid and held share the Point one label; visible, solid and held have radius 0.14 m. Only solid has a fixed SphereShape3D. Held reuses interactive_point_origin.tscn, with a matching sphere collider, black material and coordinate_id point_one_main. Existing WORLD/LOCAL readouts and CoordinateSystem3M adopt that exact ID. The force variant remains a secondary comparison with a different ID. The closing pedestal variant has radius 0.65 m, centre height 1.40 m and pedestal top 0.75 m: the surfaces meet. Native desktop checks do not establish headset comfort or user understanding.

## Encounter text and making passage

final.md keeps one position line and the continuous bodily encounter. tutorial.md now follows the same corridor order: absent, visible, solid, held, coordinate room, target and pedestal.

The portable project's main scene is again study.tscn. Its unchanged position.gd, visible.gd and solid.gd let the reader inspect and vary the first three conditions. The tutorial uses actual source lines for the local centre, visible position, visible radius and collision radius. It supplies the surrounding mesh/physics construction, rather than returning to a full constructor lesson at each stop.

The held point remains an interaction in the museum. The download contains no walking or pickup system. coordinates.tscn and points.gd are unchanged and used only when the tutorial reaches the coordinate room; their two markers prepare the Line handover. The target's acceptance and the pedestal are observed encounters, not additional implementation assignments.

The source study still inherits the unchanged Day Zero base. Existing native evidence covers the two studies; this pass reruns the three-condition comparison because it becomes the default starting scene again. No headset or learner claim follows from that check.

## Carry one body between two addresses

Pick up `point_held`, which contains the production `interactive_point_origin` pickable. The inherited pickup code cycles its coordinate-label format, including a hidden-label state. The black surface stays black while its pickup responses belong to the artifact built around a position. Their complete implementation need not be learned before carrying it.

The same point feeds both wall cards and the coloured frame. The current configuration links:

- The held point: `coordinate_id:point_one_main`.
- The frame: `adopt_external_point:1`, `external_point_id:point_one_main`, `floating_point:0`.
- Frame and cards: `readout_channel:point_one_main`.
- One card: `space:world`; the other: `space:local`.

The frame creates no second floating point. Its identity filter prevents Fontana's embedded point from taking over this comparison.

The following is a reduced example of the two readings, rather than a copy of the complete update function:

```gdscript
var world_p := point.global_position
var local_p := frame.to_local(world_p)
```

`world_p` uses the scene's world reference. `local_p` expresses that same position relative to the frame, including its position, orientation and scale. Moving the point changes both reports. The frame is fixed in this encounter; a visitor control for moving the frame is not currently part of the room.

The card formats each component with `%.2f`. It rounds the displayed text without rounding the body's stored position. Small movements may therefore share a printed address. The coloured guides still follow the point beyond the ends of the drawn axes; those finite lines are not movement limits.

The two cards are at source cells `(2,17)` and `(2,19)`, facing +X at 1.4 m. Both use token scale 1 and display scale 2.4. Each is 1.728 × 1.44 m. Their two-metre separation leaves 0.272 m between their edges. These are authored dimensions, not a claim about comfortable headset reading distance.

Sources: [pickup base](../../primitives/point/interactive_point_origin.gd), [changing point](../../primitives/point/interactive_point_origin_force.gd), [reference frame](../../../algorithms/vectors/00_coordinates/CoordinateSystem3M.gd), [cards](../../primitives/point/coordinate_readout.gd).

## Arrive, leave, return

Carry the point towards `drag_point_target`. The target checks members of `ada_coordinate_point`; unlike the cards, it does not filter to the named main point. A second eligible point could also trigger it. The book's single-position example isolates the distance comparison:

```gdscript
var centre := global_position + Vector3(0.0, catch_height, 0.0)
var accepted := point.global_position.distance_to(centre) <= catch_radius
```

Here `catch_height` is 1.20 m and `catch_radius` is 0.45 m. Entering the region drops seven white balls. Staying inside does not fire on every frame; departure and re-entry can fire again because `rearm` is true. Releasing the held point is not required. Its intention and the route used to arrive are not inputs to this test.

This makes a repeatable experiment already available in the hall: arrive carefully, then pass through, then leave and return. The rule can treat different gestures as the same event. Their difference can still matter to the person making them.

Source: [arrival target](../../artifacts/drag_point_target/drag_point_target.gd).

## What continues

The hall has encountered a position, a representation, references and a test for proximity. The first making passage teaches two positions in one reference; it does not teach all of that apparatus. Point Lines can connect the two positions. Subtracting one position from another will give a displacement; drawing between them will give a segment. Remember the changing point: its coordinates alone have not kept the path your hand took. That question will return in Trace.

[Encounter reference](encounter-reference.md) records the first-walk order and additional implementation distinctions. [Current inventory](artifacts.md) distinguishes primary encounters from retained secondary works. Desktop/source evidence exists for the paired cards; physical reach, headset legibility and an unassisted beginner's walk remain observations to make.


## Retained alternatives

The invisible-point case and the non-executing code screen remain at (13,13) and (15,15). Their source example `FOCUS = Vector3(0, 1.25, 0)` remains local to the case. The force point is a secondary comparison at (13,14), identified as `point_one_force_return`, so it cannot take over the named coordinate feed. Fontana remains at (12,19), with its own embedded point. The target can accept any eligible point; the cards select only the corridor point.

The pickup label cycles plain coordinates, named X/Y/Z components, a `Vector3(...)` spelling, and no label. The executable match in `interactive_point_origin.gd` is the evidence; its older source-header format descriptions are inaccurate.

The coordinate frame’s optional origin sign is blank in this placement (`origin_sign_text`), so “Point zero” belongs to the origin in the previous chapter. The wider room has a continuous floor and a clear approach to the closing sculpture.

## Coordinate basin — revised 26 September 2026

An L-shaped glass-covered basin follows the horizontal axes: map cells x=4, z=15..20 and z=20, x=4..9. The 11 pool cells are one metre deep. The coordinate origin is at floor level, with a +1.0 m placement offset above the museum’s automatic basin seat. The glass supports a level crossing. WORLD and LOCAL still follow the same carried point. The uncut quadrant stays ordinary floor; no damage volume is enabled.
