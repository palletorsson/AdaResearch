extends Node3D

## ONE LINE, FOUR ANGLES — the family behind the cross.
##
## 2026-09-01, Palle left four wishes standing in Point_Lines: `horizontal line`,
## `vertical line`, `diagonal line`, `diagonal line 2`. They are not four
## artifacts. They are one artifact and one axis, which is the room's own point:
## a line has a direction, the direction is a CHOICE, and horizontal and vertical
## are two picks out of infinitely many that a culture happens to have named.
##
## Building them as four separate tokens would have said the opposite — that
## `vertical` is a kind of thing rather than a value. So: `axis_line`, with
## `orientation` as a declared DNA axis, four values, one scene.
##
##   horizontal   along X, at cross_height_m — the near bar of the cross
##   vertical     along Y, centred on the same height
##   diagonal     +45 degrees in the XY plane
##   diagonal_2   -45 degrees; with `diagonal`, an X
##
## COMPOSITION IS THE POINT. A horizontal and a vertical at the same place make a
## cross; set apart in depth they make a cross ONLY from the corridor, which is
## what anamorphic_cross builds out of the same two elements. The pair of
## diagonals make an X. Nothing here knows about crosses — the room composes
## them, the way the room composes a line out of two points.

## ON ONE LINE. check_dna_declarations.py looks for `@export ... var <name>` and
## a wrapped annotation reads as NO EXPORT — the axis was declared, the gate said
## the code did not have it, and a sweep would have set a value nothing received.
@export_enum("horizontal", "vertical", "diagonal", "diagonal_2") var orientation: String = "horizontal"
@export var length_m: float = 1.6
@export var thickness_m: float = 0.055
## Palle: "A horizontal line at y 1.0". That is the default and it is deliberate:
## chest height on a standing adult, so the bar is met rather than looked at.
@export var cross_height_m: float = 1.0
@export var line_color: Color = Color(0.86, 0.31, 0.26)
@export var glow: float = 0.35

var _bar: MeshInstance3D


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("orientation"):
		var o: String = str(config_data["orientation"]).strip_edges().to_lower()
		if o in ["horizontal", "vertical", "diagonal", "diagonal_2"]:
			orientation = o
	if config_data.has("length_m"):
		length_m = float(config_data["length_m"])
	if config_data.has("cross_height_m"):
		cross_height_m = float(config_data["cross_height_m"])
	if config_data.has("thickness_m"):
		thickness_m = float(config_data["thickness_m"])
	if _bar:
		_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()

	_bar = MeshInstance3D.new()
	_bar.name = "Bar"
	var bm := BoxMesh.new()
	# The bar is built along X and then TURNED, rather than built four different
	# ways. Four constructions would be four things to get wrong; one bar and a
	# rotation is the same claim the artifact is making about lines.
	bm.size = Vector3(length_m, thickness_m, thickness_m)
	_bar.mesh = bm
	_bar.position = Vector3(0, cross_height_m, 0)
	_bar.rotation = _turn()
	_bar.material_override = _mat()
	add_child(_bar)


func _turn() -> Vector3:
	match orientation:
		"vertical":
			return Vector3(0, 0, PI * 0.5)
		"diagonal":
			return Vector3(0, 0, PI * 0.25)
		"diagonal_2":
			return Vector3(0, 0, -PI * 0.25)
		_:
			return Vector3.ZERO


func _mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = line_color
	m.roughness = 0.42
	m.emission_enabled = true
	m.emission = line_color
	m.emission_energy_multiplier = glow
	return m
