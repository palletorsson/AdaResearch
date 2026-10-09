# mode_modifier.gd — Grid modifier catalyst mode (additive)
#
# A caretaker's hand for the grid: each touch records one op on the map's
# `modifiers` stack (colorize → random colours → normalize/clear) and applies
# it live. The stack is non-destructive (see commons/modifiers/modifier_stack.gd
# + doc/BRACELET_GARDEN_MODIFIERS.md) and saves into map_data.json's
# `modifiers` key, re-applying on load.
#
# Like the voxel/wedge editor modes this is a TOOL mode (fires no projectile);
# BecomingCatalyst dispatches add/undo/save directly. Always available (order 0).
#
# Loaded by path (MODE_DEFS script field) like the other thin descriptors —
# intentionally no class_name, matching mode_voxel_editor.gd / mode_wedge_placer.gd.

const MODE_ID := "modifier"
const MODE_NAME := "Modifier"
const DESCRIPTION := "Tend the grid: colorize / random / clear. Each touch is one op."
const FIRE_RATE := 0.2
const SEQUENCE := ""
const MODE_COLOR := Color(0.55, 0.85, 0.5)

## Modifier mode doesn't fire projectiles — returns null.
## BecomingCatalyst handles modifier ops directly.
static func create_projectile(_pos: Vector3, _dir: Vector3) -> Node3D:
	return null

## Identifies this as a tool mode, not a projectile mode.
static func get_mode_type() -> String:
	return "tool"
