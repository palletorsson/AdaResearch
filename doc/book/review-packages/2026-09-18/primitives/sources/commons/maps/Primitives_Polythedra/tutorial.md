# Enclose a region, then meet a body

Triangle separated closing a loop from drawing its face. This hall follows faces into an open corner, a closed surface and a route through the room. The next hall, Point_Animatedcube, makes the construction of a cube available for inspection.

## Inspect the opening

Turn `grab_trihedron`. Count three faces sharing an apex and locate the missing base. Compare `grab_tetrahedron`, whose fourth face completes a closed surface. The regular tetrahedron has different proportions from the open corner; the comparison concerns closure, not a live before/after button.

The trihedron's actual face indices are:

```gdscript
[0, 1, 2]
[0, 2, 3]
[0, 3, 1]
```

Its renderer emits those faces. Separately, the script gives its collision shape all four positions:

```gdscript
var convex_shape = ConvexPolygonShape3D.new()
convex_shape.points = geometry["vertices"]
collision_shape.shape = convex_shape
```

The hull includes the missing base. This is a reason to distinguish visible opening and physical passage. A test must identify a colliding body and its layers; the behavior of an unconstrained tracked hand cannot settle that question.

## Carry the comparison into the room

At `prism_block`, compare the whole block, quartered version and shell. Each is a placed configuration. Changing the visible grain leaves the original static collision surface. There is no visitor grain selector here.

Try the utility wedges from the low end. Their rise and run are scaled by the museum builder, but successful ascent also needs connected floors and suitable movement settings. Compare with approaching an upright face. Report a failed join as a failed join.

Follow the concrete enclosure's outside edge. Its striped material and extruded profile make a visible boundary; `#blocking:1` supplies a physical one. Then read STOP and the arrows. Those sign scenes contain no collision object. Ask where a pause began, and inspect a suggested route before trusting it.

We can now distinguish a surface's enclosure, a body's collision and a reader's response to a sign. All participate in this room, with different rules. The [technical reference](technical.md) unfolds the source and calculations behind the comparison.

## Return visits

These works remain in their original positions. Choose a question; their secondary role does not make them disposable.

### Barrier and sign: stay with the arrangement

The first passage touches these briefly. To continue, follow the stepped end profile of `concrete_barrier` and compare it with the bare prism. Both use a cross-section carried along a length; their profiles differ. The technical reference shows the actual extrusion code.

At `street_sign`, find ahead, left, right and both ways. Stand where one becomes legible, then inspect its route. The rectangular shaft and triangular head form a geometric mark; the mark does not check the floor. Choose one pause you would preserve, one arrow you would turn or one barrier you would move. Whose movement would change? The installed fixtures remain fixed, so distinguish a proposal from an available grab control.

The critical text develops continuity, division and the question of who benefits from an arrangement. This later reading does not require deciding that barriers are intrinsically oppressive or that every opening is beneficial.

### Pyramid: change a corner

At `pyramid_edit`, find the apex handle and four base handles. Keep the base still and raise the apex. Predict which faces change before lowering it again. Then change a base corner. The placed editor allows independent movement; its other constraint modes are source configuration options, not promised buttons.

A crossing or collapsed set of faces can outlive the name we gave it. The editor updates positions without certifying every result as an enclosed pyramid. A changed apex can still make a perfectly valid pyramid. The question is which relations remain, not how far the handle moved.

Source: [pyramid_edit.gd](../../primitives/pyramid/pyramid_edit.gd).

### Cube: count and compare

At `cube_scene`, count eight vertices, twelve edges and six geometric square faces. Compare the tetrahedron's four, six and four. Both give `V - E + F = 2`. Be explicit about whether you count square faces or rendering triangles: introducing a face diagonal adds an edge as well as a face.

The technical reference keeps this calculation and angular defect. Neither measures volume. These are useful questions to revisit after the small enclosure lesson, without requiring the visitor to learn every invariant before leaving.

### Diamonds: a relation repeated

Follow how successive units turn along the stack. The configured default accumulates an angle from one unit to the next. Distinguish the shape of a unit from the rule arranging several. The source offers fixed, alternating and accelerating arrangements too; this room does not supply a switch between them. Those would make a comparison for a later iteration.

Source: [diamonds.gd](../../primitives/combines/diamonds.gd).

### Rocks: a boundary between neighbours

The `rock_spawner` placement requests thirty irregular rocks. Look for gaps between their boundaries. Shape, arrangement, gravity and collision all contribute to the pile. Irregularity does not by itself establish that no denser packing is possible. The existing wall phrase “thirty rocks that never pack” is an invitation to investigate, not a mathematical result.

Source: [RockSpawner.gd](../../primitives/rockfactory/RockSpawner.gd).

### Scanner: what would a section retain?

At `rock_scanner`, watch the cyan plane move through its height range. Predict how a cut through a rock would change as the height changes. The current scene moves the plane and its thin collision box. Its own ready/process path does not call the separate display-creation and cross-section-update functions, so do not expect an active measured contour display.

The unused display code is also an approximation, not a mesh-intersection algorithm. A future comparison should hold one rock still, expose the cut height, and distinguish its geometric intersection from any approximation. The plane currently has a collider, so a later slicing experiment must decide whether the instrument should also move the objects it is meant to examine.

Source: [RockScanner.gd](../../primitives/rockfactory/RockScanner.gd).

### Other systems and a request

`interactive_point_origin_force` and `becoming_catalyst` retain a route toward acting on other bodies. `path_watchdog` and `path_game_controller` retain the older path-game layer. They are not prerequisites for this geometric walk, and their presence alone does not demonstrate an active path game in the endless museum. Inspect their integration before giving visitors a challenge that depends on it.

The `if_not_exist_create` marker requests a primitive gallery. It records work still to make. Two traffic cones remain part of the room's directional vocabulary. None of these has been removed to narrow the book.
