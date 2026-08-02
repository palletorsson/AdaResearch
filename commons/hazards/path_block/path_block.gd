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

## AXIS — WARNING: how much the block tells you BEFORE it costs you anything.
## Adopted word for word from [[catalyst_vent]], which asks the same question of a
## spawn seam: one vocabulary across the hazards, so a room whose vents are caged
## cannot have blocks that say nothing. A block is the only object in this game whose
## entire function is CONSEQUENCE — it edits the route the path watchdog is judging —
## and the interesting variable is not what it does (that is fixed) but how much of it
## is legible from the doorway.
##
##   none    the block alone, unannounced: grey wall, green ramp, and nothing else.
##           THE LEGACY BODY, byte for byte — this is what every placement renders today.
##   stain   a discolouration soaked into the floor around its foot and nothing above it.
##           The warning exists but it is addressed to your feet: you can only read it
##           from a cell you are already standing in.
##   cage    a bolted bar frame with a filed yellow tag. Someone knew, catalogued it,
##           fenced it — and the block walls the cell through the bars on exactly the
##           same rule. A world that DOCUMENTS its obstacles has not removed any.
##   beacon  a lit mast on the crown and a glowing outline at the foot: the verdict is
##           broadcast as light, readable across a dark room before you commit to walking.
##   shroud  a canvas drape strapped over it. You cannot tell wall from ramp until you
##           touch it. The quietest tile and the loudest claim.
##
## APPEARANCE ONLY, and deliberately so. The collision shape, the size, the height and
## the `path_passable` membership that decides whether the route may cross are
## byte-identical across all five values. A block that hides itself is not a gentler
## block — that is the whole point of the axis.
const WARNING_VALUES: PackedStringArray = ["none", "stain", "cage", "beacon", "shroud"]
@export_enum("none", "stain", "cage", "beacon", "shroud") var warning: String = "none"

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
	# WARNING — normalised, and an unknown word keeps the default rather than
	# blanking the dressing. Read LAST so nothing above it moves.
	if has_meta("config_warning"):
		var w: String = str(get_meta("config_warning")).strip_edges().to_lower()
		warning = w if WARNING_VALUES.has(w) else warning


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

	# WARNING dressing, appended LAST so the mesh and the collider keep their
	# child indices and the passable group is already decided above. "none"
	# falls through and adds nothing at all — the legacy lineage.
	match warning:
		"stain":
			_warn_stain()
		"cage":
			_warn_cage()
		"beacon":
			_warn_beacon()
		"shroud":
			_warn_shroud()
		_:
			pass


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


# ── WARNING ──────────────────────────────────────────────────────────────────
# One axis, five values, the vocabulary shared with [[catalyst_vent]]. Every
# builder below adds MeshInstance3D children only — never a collider, never a
# group, never a size. Deterministic: no draw from the random stream, so five
# variants of the same block differ only in what is on it.

const WARN_STAIN_OUTER := Color(0.24, 0.19, 0.13)
const WARN_STAIN_CORE := Color(0.09, 0.075, 0.055)
const WARN_BAR := Color(0.52, 0.50, 0.44)
const WARN_TAG := Color(0.86, 0.72, 0.12)
const WARN_MAST := Color(0.38, 0.38, 0.40)
const WARN_LAMP := Color(1.0, 0.62, 0.12)
const WARN_CLOTH := Color(0.40, 0.38, 0.33)
const WARN_STRAP := Color(0.15, 0.14, 0.13)


## STAIN — the notice written on the ground. A wide dull discolouration soaked
## around the block's foot with a darker core right under it: readable only from
## a cell you already occupy, which is exactly one cell too late.
func _warn_stain() -> void:
	_warn_add(Vector3(0, 0.006, 0), Vector3(size * 1.9, 0.012, size * 1.9),
		_warn_mat(WARN_STAIN_OUTER, 1.0, 0.0))
	_warn_add(Vector3(0, 0.013, 0), Vector3(size * 1.24, 0.012, size * 1.24),
		_warn_mat(WARN_STAIN_CORE, 1.0, 0.0))
	# Two dry runs bled off one side — the stain has a direction, so it reads as
	# something that happened here rather than a painted square.
	_warn_add(Vector3(size * 0.86, 0.010, size * 0.18), Vector3(size * 0.62, 0.012, size * 0.17),
		_warn_mat(WARN_STAIN_CORE, 1.0, 0.0))
	_warn_add(Vector3(-size * 0.72, 0.010, -size * 0.40), Vector3(size * 0.44, 0.012, size * 0.13),
		_warn_mat(WARN_STAIN_CORE, 1.0, 0.0))


## CAGE — the notice as paperwork. Four corner posts, two rails and a filed
## yellow tag. The cell is still walled on exactly the same rule; the bars only
## record that somebody wrote it down.
func _warn_cage() -> void:
	# Posts sit just clear of the block's 0.92 m face, not out at the cell edge:
	# the frame has to read as fencing THIS block, and a wider box would only
	# zoom the sweep camera out and shrink the subject in every tile.
	var hx: float = size * 0.74
	var top: float = height * 1.26
	var bot: float = 0.02
	var bar: StandardMaterial3D = _warn_mat(WARN_BAR, 0.45, 0.55)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var px: float = float(sx) * hx
			var pz: float = float(sz) * hx
			_warn_add(Vector3(px, (bot + top) * 0.5, pz), Vector3(0.055, top - bot, 0.055), bar)
	for ry in [top, height * 0.50]:
		var y: float = float(ry)
		for s in [-1.0, 1.0]:
			var o: float = float(s) * hx
			_warn_add(Vector3(0, y, o), Vector3(hx * 2.0 + 0.055, 0.042, 0.042), bar)
			_warn_add(Vector3(o, y, 0), Vector3(0.042, 0.042, hx * 2.0 + 0.055), bar)
	_warn_add(Vector3(hx + 0.03, height * 0.84, 0.0), Vector3(0.018, 0.15, 0.23),
		_warn_mat(WARN_TAG, 0.7, 0.0))


## BEACON — the notice as broadcast. A mast on the crown with a lit head, and a
## glowing outline burnt around the foot: the verdict reaches the doorway.
func _warn_beacon() -> void:
	var mast_h: float = height * 0.85
	var mast: StandardMaterial3D = _warn_mat(WARN_MAST, 0.4, 0.6)
	var lamp: StandardMaterial3D = _warn_emissive(WARN_LAMP, 3.2)
	_warn_add(Vector3(0, height + mast_h * 0.5, 0), Vector3(0.055, mast_h, 0.055), mast)
	_warn_add(Vector3(0, height + mast_h + 0.06, 0), Vector3(0.20, 0.12, 0.20), lamp)
	# A shade cap over the lamp so it reads as a fitting, not a floating cube.
	_warn_add(Vector3(0, height + mast_h + 0.15, 0), Vector3(0.28, 0.045, 0.28), mast)
	# The foot outline — four thin lit bars on the floor around the base.
	var hx: float = size * 0.72
	for s in [-1.0, 1.0]:
		var o: float = float(s) * hx
		_warn_add(Vector3(0, 0.014, o), Vector3(hx * 2.0, 0.02, 0.045), lamp)
		_warn_add(Vector3(o, 0.014, 0), Vector3(0.045, 0.02, hx * 2.0), lamp)


## SHROUD — the notice withheld. A canvas drape strapped over the block, so wall
## and ramp share one silhouette and the rule is only discoverable by walking
## into it. The block underneath is untouched.
func _warn_shroud() -> void:
	var cloth: StandardMaterial3D = _warn_mat(WARN_CLOTH, 0.95, 0.0)
	var strap: StandardMaterial3D = _warn_mat(WARN_STRAP, 0.85, 0.1)
	var w: float = size + 0.13
	_warn_add(Vector3(0, height * 0.51, 0), Vector3(w, height * 1.02, w), cloth)
	# The gather knotted at the top, and a skirt where the cloth breaks on the floor.
	_warn_add(Vector3(0, height * 1.02 + 0.05, 0), Vector3(0.26, 0.10, 0.26), cloth)
	_warn_add(Vector3(0, 0.035, 0), Vector3(w + 0.09, 0.07, w + 0.09), cloth)
	# One strap around the waist.
	var hw: float = w * 0.5
	for s in [-1.0, 1.0]:
		var o: float = float(s) * hw
		_warn_add(Vector3(0, height * 0.58, o), Vector3(w + 0.012, 0.06, 0.014), strap)
		_warn_add(Vector3(o, height * 0.58, 0), Vector3(0.014, 0.06, w + 0.012), strap)


func _warn_add(center: Vector3, box_size: Vector3, mat: Material) -> void:
	var bm := BoxMesh.new()
	bm.size = box_size
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	mi.material_override = mat
	mi.position = center
	mi.add_to_group("hazard_warning")
	add_child(mi)


func _warn_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _warn_emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m
