# mode_biome_brush.gd — Biome paint catalyst mode (stone)
#
# A tool mode like the voxel editor: point at the floor, trigger paints the
# active biome element's density, grip erases. The behaviour lives in
# becoming_catalyst.gd (delegating to BiomeBrushController), gated on mode_id.
# See doc/VR_EDITING_SYSTEM.md and doc/PAINT_LAYERS.md.

const MODE_COLOR := Color(0.45, 0.85, 0.50)  # green — the living world

## Tool mode — doesn't fire projectiles. BecomingCatalyst routes trigger/grip
## to the biome brush instead.
static func create_projectile(_pos: Vector3, _dir: Vector3) -> Node3D:
	return null

static func get_mode_type() -> String:
	return "tool"
