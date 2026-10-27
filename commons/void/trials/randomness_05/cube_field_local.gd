extends "res://commons/primitives/cubes/CubeSpawner.gd"
## Trial-only adapter (randomness_05, R3) for Random_Game's falling field
## (`cube_projectile_spawner#mode:field#field_height:8...`).
##
## The source launches each cube 8 m above the emitter. That height was set under the
## museum's open roof. A Void storey is 6 m with a 0.36 m slab, so a launch 8 m up starts
## about 2 m above the floor of the storey above: the cube falls onto floor 4 (ProjectileCube
## collides with layer 1; it has no contact monitor, so it lies there for its 10 s
## lifetime) and floor 5's field stays empty. Static inference; the focused check `field`
## measures the launch heights.
##
## This is an EFFECTIVE-HEIGHT ADAPTATION, not unchanged behaviour: cubes start about 5.2 m
## up instead of 8 m, so each fall is shorter (about 2-3 s instead of 3-5 s at the source's
## 1.6-2.6 m/s). The configured value is kept as `source_field_height`; every other source
## value (field size, speeds, drift, jitter, interval, cap) is untouched. The cap is the
## underside of the slab above this floor (clear height - cube half - margin), measured from
## the field origin (spawner + field_center_offset) at every launch, so it stays right after
## a height change, a move, a rotation or at any floor depth. Outside the Void (no floor
## root) nothing is capped. The original readout reports the height actually used.
##
## The debug keys in `_input` (P toggle, O single cube, C clear) are disabled: C is the
## Void's desktop hands-together key. RUN / STOP and CLEAR remain on the original
## field-stand panel; the single-cube O key has no button.
const CUBE_HALF := 0.25
const CEILING_MARGIN := 0.2
## The configured launch height (source token value), before the storey cap.
var source_field_height: float = -1.0

# Same signature as the source `func _ready():` (an override must match it).
func _ready():
	super._ready()
	set_process_input(false)

func apply_grid_config(config_data: Dictionary) -> void:
	super.apply_grid_config(config_data)
	# A later config without field_height (e.g. curation's {"emissive": false}) must not
	# record the already-capped value as the source.
	if config_data.has("field_height") or source_field_height < 0.0:
		source_field_height = field_spawn_height
	_cap_launch()

func _configure_falling_field_projectile(projectile: Node3D) -> void:
	_cap_launch()
	super._configure_falling_field_projectile(projectile)

func _cap_launch() -> void:
	if source_field_height < 0.0:
		source_field_height = field_spawn_height
	field_spawn_height = minf(source_field_height, launch_limit())

## Highest launch above the field origin (this spawner + field_center_offset, as the source
## samples it) that keeps a cube under the slab of the floor above.
func launch_limit() -> float:
	var floor_root: Node3D = null
	var node: Node = get_parent()
	while node != null:
		if node is Node3D and node.has_meta("void_content_floor"):
			floor_root = node
			break
		node = node.get_parent()
	if floor_root == null or not is_inside_tree():
		return INF
	var spec: Variant = null
	node = floor_root.get_parent()
	while node != null and spec == null:
		spec = node.get("spec")
		node = node.get_parent()
	if not spec is Dictionary:
		return INF
	var clear: float = float(spec.get("storey_height", 6.0)) - float(spec.get("slab_thickness", 0.36))
	var ceiling_y: float = floor_root.global_position.y + clear
	var field_origin_y: float = global_position.y + field_center_offset.y
	return maxf(0.5, ceiling_y - CUBE_HALF - CEILING_MARGIN - field_origin_y)
