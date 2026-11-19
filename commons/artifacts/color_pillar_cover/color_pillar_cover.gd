extends Node3D
class_name ColorPillarCover
## Architectural pillar covering built from curated color-stacks-gallery configs.
## Wraps a 0.90 m square Void structural column (and its 0.944 m corner guards)
## from floor slab (y = 0) to ceiling soffit (y = 5.64 m) using the gallery's
## exact sequence, shapes, and colours. Sphere levels carry a colour-matched
## 1.00 m inner collar so concrete never pokes out near the poles.

const DATA := "res://commons/artifacts/color_pillar_cover/configs/"
const ROUGHNESS := 0.55
const GUARD_TOP_Y := 1.56
const NECK_RADIUS_LOWER := 0.676
const NECK_RADIUS_UPPER := 0.656
const MIN_BOX_WIDTH := 1.02
const DEFAULT_HEIGHT := 5.64
const DEFAULT_MAX_WIDTH := 1.46

const STACKS: PackedStringArray = [
	"stack_analogous_warm",
	"stack_complementary_blue_orange",
	"stack_complementary_red_green",
	"stack_complementary_yellow_violet",
	"stack_monochrome_blue",
	"stack_simultaneous_contrast",
	"stack_triadic_primary",
	"stack_triadic_secondary",
	"stack_value_steps_cool",
	"stack_value_steps_warm",
]

const AUTO_REPEAT_TWO: PackedStringArray = [
	"stack_complementary_blue_orange",
	"stack_triadic_primary",
	"stack_triadic_secondary",
]

@export_enum(
	"stack_analogous_warm",
	"stack_complementary_blue_orange",
	"stack_complementary_red_green",
	"stack_complementary_yellow_violet",
	"stack_monochrome_blue",
	"stack_simultaneous_contrast",
	"stack_triadic_primary",
	"stack_triadic_secondary",
	"stack_value_steps_cool",
	"stack_value_steps_warm"
) var stack: String = "stack_triadic_primary"
@export var total_height: float = DEFAULT_HEIGHT
@export var max_width: float = DEFAULT_MAX_WIDTH
@export var repeats: int = 0

var _built := false

func _ready() -> void:
	_read_meta()
	_build()
	_built = true

func _read_meta() -> void:
	var s := str(get_meta("config_stack", stack)).strip_edges()
	if s in STACKS:
		stack = s
	if has_meta("config_height"):
		total_height = clampf(float(get_meta("config_height")), 2.0, 9.0)
	if has_meta("config_max_width"):
		max_width = clampf(float(get_meta("config_max_width")), 1.08, 1.80)
	if has_meta("config_repeats"):
		repeats = maxi(0, int(get_meta("config_repeats")))

func apply_grid_config(config: Dictionary) -> void:
	var before := [stack, total_height, max_width, repeats]
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta()
	if _built and [stack, total_height, max_width, repeats] != before:
		_build()

func _load_config(id: String) -> Dictionary:
	var path := DATA + id + ".json"
	if not FileAccess.file_exists(path):
		push_error("color_pillar_cover: missing config " + path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var cfg := _load_config(stack)
	var base_seq: Array = cfg.get("sequence", [])
	if base_seq.is_empty():
		return

	var effective_repeats := repeats if repeats > 0 else (2 if stack in AUTO_REPEAT_TWO else 1)
	var seq: Array[Dictionary] = []
	for _r in range(effective_repeats):
		for item in base_seq:
			if item is Dictionary:
				seq.append(item)

	# Compute vertical weights so spheres stay lush and boxes preserve gallery rhythm.
	var weights: Array[float] = []
	var weight_sum := 0.0
	var box_min := INF
	var box_max := 0.0
	for item in seq:
		var shape := str(item.get("shape", "cube"))
		var sc := float(item.get("scale", 1.0))
		var wy := sc
		if shape == "cuboid":
			wy = sc * 0.50
		elif shape == "sphere":
			wy = 0.96 if sc < 0.75 else maxf(sc * 1.18, 1.08)
		weights.append(wy)
		weight_sum += wy
		if shape != "sphere":
			var nat := sc * (1.3 if shape == "cuboid" else 1.0)
			box_min = minf(box_min, nat)
			box_max = maxf(box_max, nat)

	var body := StaticBody3D.new()
	body.name = "Body"
	add_child(body)

	var y := 0.0
	for i in range(seq.size()):
		var item: Dictionary = seq[i]
		var shape := str(item.get("shape", "cube"))
		var sc := float(item.get("scale", 1.0))
		var color := Color.from_string(str(item.get("color", "#888888")), Color(0.6, 0.6, 0.6))
		var h := total_height * (weights[i] / weight_sum)
		var center_y := y + h * 0.5

		if shape == "sphere":
			# Smooth cylindrical neck encloses the 0.90 m column (and corner guards below
			# 1.56 m) so the sphere meets it along clean horizontal rings instead of
			# square box corners slicing through the round silhouette.
			var neck_r := NECK_RADIUS_LOWER if y < GUARD_TOP_Y else NECK_RADIUS_UPPER
			var collar := MeshInstance3D.new()
			collar.name = "Collar_%d" % i
			var cmesh := CylinderMesh.new()
			cmesh.top_radius = neck_r
			cmesh.bottom_radius = neck_r
			cmesh.height = h + 0.004
			cmesh.radial_segments = 48
			collar.mesh = cmesh
			collar.material_override = _material(color.darkened(0.05))
			collar.position = Vector3(0.0, center_y, 0.0)
			add_child(collar)

			var diameter := 1.44 if sc < 0.75 else maxf(1.54, minf(max_width + 0.14, 1.54 + clampf((sc - 0.8) / 0.4, 0.0, 1.0) * 0.08))
			var orb := MeshInstance3D.new()
			orb.name = "Element_%d_sphere" % i
			var smesh := SphereMesh.new()
			smesh.radius = diameter * 0.5
			smesh.height = h
			smesh.radial_segments = 48
			smesh.rings = 24
			orb.mesh = smesh
			orb.material_override = _material(color)
			orb.position = Vector3(0.0, center_y, 0.0)
			add_child(orb)

			var col_shape := CollisionShape3D.new()
			var col_cyl := CylinderShape3D.new()
			col_cyl.radius = maxf(neck_r, diameter * 0.47)
			col_cyl.height = h
			col_shape.shape = col_cyl
			col_shape.position = Vector3(0.0, center_y, 0.0)
			body.add_child(col_shape)
		else:
			var nat := sc * (1.3 if shape == "cuboid" else 1.0)
			var w: float
			if box_max <= box_min + 0.0001:
				w = max_width
			elif (box_min / box_max) * max_width >= MIN_BOX_WIDTH:
				w = (nat / box_max) * max_width
			else:
				var t := (nat - box_min) / (box_max - box_min)
				w = MIN_BOX_WIDTH + t * (max_width - MIN_BOX_WIDTH)

			var block := MeshInstance3D.new()
			block.name = "Element_%d_%s" % [i, shape]
			var bmesh := BoxMesh.new()
			bmesh.size = Vector3(w, h, w)
			block.mesh = bmesh
			block.material_override = _material(color)
			block.position = Vector3(0.0, center_y, 0.0)
			add_child(block)

			var col_shape := CollisionShape3D.new()
			var col_box := BoxShape3D.new()
			col_box.size = bmesh.size
			col_shape.shape = col_box
			col_shape.position = Vector3(0.0, center_y, 0.0)
			body.add_child(col_shape)

		y += h

func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = ROUGHNESS
	m.metallic = 0.0
	return m
