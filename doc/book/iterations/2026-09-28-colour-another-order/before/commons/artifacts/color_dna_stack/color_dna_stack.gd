extends Node3D
class_name ColorDNAStack
## Curated, static gallery DNA at architectural height. Reuses the gallery's
## primitive_stack builder; the snapshots and height adaptations are inspectable.
## A stack can combine several gallery configurations, joined by their bounds.
## No animation, physics balance or new pattern generator is implied.

const PrimitiveStack = preload("res://commons/primitive_grammar/primitive_stack.gd")
const TextScreen = preload("res://commons/ui/text_screen.gd")
const DATA := "res://commons/artifacts/color_dna_stack/"
const STUDIES := ["mondrian", "albers", "memphis", "bauhaus_tall", "blue", "kras_rainbow", "rainbow_crown", "memphis_beacon"]
@export_enum("mondrian", "albers", "memphis", "bauhaus_tall", "blue", "kras_rainbow", "rainbow_crown", "memphis_beacon") var study: String = "mondrian"
var _built := false
var part_bounds: Array[AABB] = []
var source_ids: Array[String] = []

func _ready() -> void:
	_read_config()
	_build()
	_built = true

func _read_config() -> void:
	var value := str(get_meta("config_study", study))
	study = value if value in STUDIES else "mondrian"

func apply_grid_config(config: Dictionary) -> void:
	var before := study
	if config.has("study"):
		set_meta("config_study", config.study)
	_read_config()
	if _built and study != before:
		_build()

func _json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	part_bounds.clear()
	source_ids.clear()
	var entries := _json(DATA + "studies.json")
	var entry: Dictionary = entries.get(study, {})
	var body := StaticBody3D.new()
	body.name = "Body"
	add_child(body)
	var y := 0.0
	var max_front := 0.0
	for item: Dictionary in entry.get("parts", []):
		var source := str(item.source)
		var cfg := _json(DATA + "configs/" + source + ".json")
		cfg.merge(item.get("overrides", {}), true)
		var form: Node3D = PrimitiveStack.build(cfg)
		form.name = "Part_%d_%s" % [part_bounds.size(), source]
		add_child(form)
		var bounds := _bounds(form)
		if bounds.size.y <= 0.0:
			push_error("color_dna_stack: empty source " + source)
			continue
		# Uniform scale preserves each vertical-stack study's proportions.
		# Kraš uses explicit shaft dimensions in the config, before this step.
		var factor := float(item.height) / bounds.size.y
		form.scale = Vector3.ONE * factor
		form.position.y = y - bounds.position.y * factor
		var placed := form.transform * bounds
		part_bounds.append(placed)
		source_ids.append(source)
		y = placed.end.y
		max_front = maxf(max_front, placed.end.z)
		# Each primitive has its own static convex collision, so the narrow
		# gaps between discs and beads remain visible and have matching bounds.
		for mi: MeshInstance3D in form.find_children("*", "MeshInstance3D", true, false):
			var collision := CollisionShape3D.new()
			collision.shape = mi.mesh.create_convex_shape()
			body.add_child(collision)
			collision.transform = global_transform.affine_inverse() * mi.global_transform
	_add_plate(body, entry, max_front + 0.10)

func _bounds(form: Node3D) -> AABB:
	var total := AABB()
	var first := true
	for mi: MeshInstance3D in form.find_children("*", "MeshInstance3D", true, false):
		var relative := form.global_transform.affine_inverse() * mi.global_transform
		var box: AABB = relative * mi.get_aabb()
		total = box if first else total.merge(box)
		first = false
	return total

func _add_plate(body: StaticBody3D, entry: Dictionary, front: float) -> void:
	var screen := TextScreen.new()
	screen.name = "Plate"
	screen.mode = 0
	screen.width_m = 0.95
	screen.title = str(entry.get("title", study))
	screen.body = str(entry.get("body", ""))
	screen.position = Vector3(0, 1.2, front)
	add_child(screen)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.15, 0.18)
	var post := MeshInstance3D.new()
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.065, 1.2, 0.065)
	post.mesh = post_mesh
	post.material_override = material
	post.position = Vector3(0, 0.6, front - 0.05)
	add_child(post)
	var post_collision := CollisionShape3D.new()
	var post_shape := BoxShape3D.new()
	post_shape.size = post_mesh.size
	post_collision.shape = post_shape
	post_collision.position = post.position
	body.add_child(post_collision)
	var plate_collision := CollisionShape3D.new()
	var plate_shape := BoxShape3D.new()
	plate_shape.size = Vector3(0.99, 0.63, 0.02)
	plate_collision.shape = plate_shape
	plate_collision.position = screen.position + Vector3(0, 0, -0.004)
	body.add_child(plate_collision)
