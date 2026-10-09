# mode_wedge_placer.gd — Wedge/ramp placement catalyst mode
#
# Places PrismMesh wedges on the grid, like the "wp" utility but as a
# catalyst skill. The wedge slopes toward the player's look direction.
# Found in the primitives sequence — the second bracelet stone.

const FIRE_RATE := 0.2
const MODE_COLOR := Color(0.85, 0.55, 0.2)

## Wedge mode doesn't fire projectiles — returns null.
## BecomingCatalyst handles wedge placement directly.
static func create_projectile(_pos: Vector3, _dir: Vector3) -> Node3D:
	return null

## Identifies this as a tool mode, not a projectile mode.
static func get_mode_type() -> String:
	return "tool"
