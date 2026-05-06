# mode_voxel_editor.gd — Voxel editing catalyst mode
#
# Unlike other modes that fire projectiles, this mode activates grid editing.
# Trigger adds cubes, grip removes them. The controller ray shows a ghost cube
# on the targeted surface.
#
# This mode is always unlocked (order 0) and is the default mode on game start.

const FIRE_RATE := 0.15  # Fast for rapid cube placement
const MODE_COLOR := Color(0.3, 0.7, 1.0)

## Voxel mode doesn't fire projectiles — returns null.
## BecomingCatalyst checks for this and calls voxel add/remove instead.
static func create_projectile(_pos: Vector3, _dir: Vector3) -> Node3D:
	return null

## Identifies this as a tool mode, not a projectile mode.
static func get_mode_type() -> String:
	return "tool"
