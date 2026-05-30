extends StaticBody3D
class_name PathBlock

# @identity
# essence: the brick of the path-and-block game — a single primitive with a collider that either WALLS the way or RAMPS over it. Cube = wall, wedge = walkable ramp, pyramid = climbable mound. The curriculum's progression (pyramid → wedge → cube → +) turned into the foe's vocabulary for editing your route.
# desire: to be the unit the whole game is played in. Everything the block-builder drops and everything the player places is one of these; the difference between losing and winning is which primitive lands where.
# critical_parameter: shape — cube blocks (not in path_passable, so the path watchdog routes around it); wedge + pyramid are tagged path_passable, so the route climbs straight through them. The same footprint, opposite meaning to the path.
# triggers: _ready() builds the mesh + matching collision shape for the chosen shape and, for ramps, joins the path_passable group so the watchdog treats the cell as walkable.
# emerges: a row of cubes with one wedge in it is a gate — the only cell the path can thread; a pyramid field is a slope you ascend; a cube maze is a wall you must open or be sealed behind.
# relationships: the unit the path_watchdog judges (cube → blocked cell, wedge/pyramid → passable cell); the static cousin of blockbuilderentity's dropped blocks; built from the same primitives the curriculum teaches.
# truth: a wall and a ramp can be the same size and the same material — what separates them is whether a body can pass. The block IS the rule.

## A single game block: cube (wall), wedge (ramp), or pyramid (mound).
## Cube blocks the path; wedge + pyramid join group "path_passable" so
## the path watchdog routes through them. Origin at the block's base
## (sits on the floor of its grid cell).

@export_group("Shape")
## "cube" | "wedge" | "pyramid"
@export var shape: String = "cube"
@export var size: float = 0.92        # < 1 so a small gap reads between blocks
@export var height: float = 1.0

@export_group("Look")
@export var cube_color: Color = Color(0.62, 0.65, 0.72)
@export var ramp_color: Color = Color(0.42, 0.85, 0.55)   # green = "you may pass"
@export var metallic: float = 0.15
@export var roughness: float = 0.5
## Render the block with the grid wireframe shader (same look as the
## floor) instead of a flat colour — so dropped blocks read as grid
## geometry growing out of the map.
@export var use_grid_shader: bool = false
@export var grid_wire_color: Color = Color(1.0, 0.2, 0.8)   # magenta, like the floor
@export var grid_fill_color: Color = Color(0.68, 0.73, 0.85)

const PASSABLE_GROUP := "path_passable"
const GRID_SHADER := preload("res://commons/resourses/shaders/Grid.gdshader")

var _built: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		remove_from_group(PASSABLE_GROUP)
		_built = false
	_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_shape"):
		shape = str(get_meta("config_shape")).to_lower()
	if has_meta("config_size"):
		size = float(str(get_meta("config_size")))
	if has_meta("config_height"):
		height = float(str(get_meta("config_height")))
	if has_meta("config_use_grid_shader"):
		var v := str(get_meta("config_use_grid_shader")).to_lower()
		use_grid_shader = v in ["true", "1", "yes", "on"]


func _build() -> void:
	_built = true
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Mesh"
	var coll := CollisionShape3D.new()
	coll.name = "Collision"

	match shape:
		"wedge":
			# Wedge is a RAMP — the one walkable block (the gate).
			_make_wedge(mesh_inst, coll)
			add_to_group(PASSABLE_GROUP)
		"pyramid":
			# Pyramid is a peaked MOUND — you can't cross a 1m point, so
			# it BLOCKS the path (not in the passable group).
			_make_pyramid(mesh_inst, coll)
		_:  # cube (default) — a wall
			_make_cube(mesh_inst, coll)

	add_child(mesh_inst)
	add_child(coll)


func _make_cube(mi: MeshInstance3D, cs: CollisionShape3D) -> void:
	var bm := BoxMesh.new()
	bm.size = Vector3(size, height, size)
	mi.mesh = bm
	mi.position = Vector3(0, height * 0.5, 0)
	mi.material_override = _build_material(cube_color)
	var box := BoxShape3D.new()
	box.size = Vector3(size, height, size)
	cs.shape = box
	cs.position = Vector3(0, height * 0.5, 0)


func _make_wedge(mi: MeshInstance3D, cs: CollisionShape3D) -> void:
	# A right-triangular ramp rising along +Z. PrismMesh is a triangular
	# prism; flat_side faces are the slope. Default prism points up along
	# Y; we lay it as a ramp.
	var pm := PrismMesh.new()
	pm.size = Vector3(size, height, size)
	pm.left_to_right = 0.0   # right triangle → a clean ramp face
	mi.mesh = pm
	mi.position = Vector3(0, height * 0.5, 0)
	mi.material_override = _build_material(ramp_color)
	# Convex collision from the prism so the player can actually walk up.
	var convex := pm.create_convex_shape()
	cs.shape = convex
	cs.position = Vector3(0, height * 0.5, 0)


func _make_pyramid(mi: MeshInstance3D, cs: CollisionShape3D) -> void:
	# A 4-sided pyramid (cylinder with 4 sides, top radius 0), rotated 45°
	# so its square base aligns to the cell. For a 45°-rotated 4-gon the
	# base EDGE = bottom_radius * sqrt(2), so radius = size/sqrt(2) gives a
	# base edge of `size` — a full 1m base when size = 1.0.
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = size * 0.70710678   # base edge ≈ size (1m at size 1.0)
	cm.height = height
	cm.radial_segments = 4
	mi.mesh = cm
	mi.position = Vector3(0, height * 0.5, 0)
	mi.rotation = Vector3(0, deg_to_rad(45.0), 0)   # square base aligns to cell
	mi.material_override = _build_material(ramp_color)
	var convex := cm.create_convex_shape()
	cs.shape = convex
	cs.position = Vector3(0, height * 0.5, 0)
	cs.rotation = Vector3(0, deg_to_rad(45.0), 0)


# Flat coloured material, or the grid wireframe shader when use_grid_shader.
func _build_material(c: Color) -> Material:
	if use_grid_shader:
		var sm := ShaderMaterial.new()
		sm.shader = GRID_SHADER
		sm.set_shader_parameter("modelColor", grid_fill_color)
		sm.set_shader_parameter("wireframeColor", grid_wire_color)
		sm.set_shader_parameter("emissionColor", grid_wire_color)
		sm.set_shader_parameter("emission_strength", 2.0)
		sm.set_shader_parameter("width", 2.0)
		sm.set_shader_parameter("show_interior", true)
		return sm
	return _mat(c)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metallic
	m.roughness = roughness
	return m
