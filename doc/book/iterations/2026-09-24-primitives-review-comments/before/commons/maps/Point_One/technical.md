# Point One — following the encounter into code

This companion follows the current museum room and [book chapter](final.md). Point One begins the Primitives sequence. No programming knowledge is required to start looking; the examples give names to operations the visitor can already meet. [Point Lines](../Point_Lines/final.md) will connect two positions.

The older tutorial is [preserved in the 21 September comparison](../../../doc/book/iterations/2026-09-21-point-one-return/before/commons/maps/Point_One/technical.md). It described a different placement, including a static point, a live script runner and a dark sphere. Those are not the current first walk.

## A number before our beginning

Watch `frame_counter_display`. Its default reading is a count, with the engine's start as its epoch. The installed panel reads `Engine.get_process_frames()`; it does not count seconds and offers no visitor stop button here.

The book first introduces a smaller example:

```gdscript
extends Node3D

var _count := 0

func _process(delta: float) -> void:
    _count += 1
```

Godot supplies the repeated calls. `_count` retains its value between them. `delta` is the interval supplied for this update; this example receives it without adding it. A count and an elapsed duration answer different questions. The panel's engine total also began before this local example would begin.

Through the entrance window, `folding_past` repeats ten frames. Its `frame_count`, `scale_ratio` and animation cycle arrange that recession. It records no visitor history. The museum creates this work through its configured lobby view, so an inventory that reads only the interactable cells will miss it.

Sources: [counter](../../visualaid/frame_counter/frame_counter_display.gd), [folding frames](../../primitives/temporal/animated_folding_past.gd), [museum lobby](../../scenes/endless_museum.gd).

## Choose a reference; locate an empty centre

The origin marker supplies a reference for positions. Its zero is spatial; it does not reset the running number.

In `the_invisible_point`, the source gives the arrows and crossing lines a common reference:

```gdscript
const FOCUS := Vector3(0.0, 1.25, 0.0)
```

These components locate a place relative to the case. No point mesh is created there. The visible construction lets us locate it through relations. Keep this distinction when adapting the exhibit: the point is never revealed.

A `Vector3` is a value with three components. Here it represents a position; other programs can use such a value for a direction, a displacement or another quantity. Its meaning depends on how it is used. Giving a position a mesh, colour or collision body requires further work.

The adjacent `code_evolution_screen` displays a separate construction. Its PLAY control advances the presentation, not a running version of the shown program. [evolution.json](evolution.json) keeps both excerpts and complete illustrative scripts. Later stages accumulate elapsed time to control the example marker's visibility. They do not change the invisible point.

Source: [the invisible point](../../artifacts/the_invisible_point/the_invisible_point.gd).

## Carry one body between two addresses

Pick up `interactive_point_origin_force`. The inherited pickup code cycles its coordinate-label format, including a hidden-label state. The changing surface and responses belong to the artifact built around a position. Their complete implementation need not be learned before carrying it.

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

The two cards are at source cells `(2,9)` and `(2,11)`, facing +X at 1.4 m. Both use token scale 1 and display scale 2.4. Each is 1.728 × 1.44 m. Their two-metre separation leaves 0.272 m between their edges. These are authored dimensions, not a claim about comfortable headset reading distance.

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

Point One has introduced a position, a representation, a reference and a test for proximity. Point Lines adds a second position. Subtracting one position from another will give a displacement; drawing between them will give a segment. Remember the changing point: its coordinates alone have not kept the path your hand took. That question will return in Trace.

[Encounter reference](encounter-reference.md) records the first-walk order and additional implementation distinctions. [Current inventory](artifacts.md) distinguishes primary encounters from retained secondary works. Desktop/source evidence exists for the paired cards; physical reach, headset legibility and an unassisted beginner's walk remain observations to make.
