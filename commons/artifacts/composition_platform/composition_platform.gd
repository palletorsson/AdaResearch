# composition_platform.gd
# A pedestal that captures whatever the player has stacked on top of it
# back into a primitive_stack JSON config — closing the loop from the
# upgraded conveyor (vocabulary feeder) to the gallery pipeline (bake +
# place). Press the green button: the platform scans every body in the
# capture column, sorts them by Y, reads each body's `shape_type` and
# `piece_color` metadata (set by the conveyor's spawner), and emits a
# config the bake pipeline can consume.
#
# @identity
# essence: turn a player's freeform stack into a curatable composition
# desire: the player invents → the engine remembers → the gallery grows
# critical_parameter: capture_height — how tall the scan column is
# triggers: button press; emits saved file path on `composition_captured`
# emerges: a "player creations" gallery alongside the curated canon
# needs: pieces with `shape_type` + `piece_color` metadata (conveyor sets these)
# relationships: the federation's output side; conveyor is the input side
# truth: the catalog wants what the player actually built, not what we
#   thought they'd build

extends Node3D
class_name CompositionPlatform

signal composition_captured(path: String, config: Dictionary)

@export var platform_radius: float = 0.4
@export var platform_height: float = 0.05
@export var capture_height: float = 1.5
@export var save_dir_user: String = "user://player_compositions/"
@export var save_dir_repo: String = "res://commons/generated/player_compositions/"
@export var label_prefix: String = "Composition Platform"

var _detector: Area3D
var _label: Label3D
var _capture_count: int = 0
var _last_path: String = ""


func _ready() -> void:
	_build_pedestal()
	_build_detector()
	_build_button()
	_build_label()


# ── Construction ─────────────────────────────────────────────────

func _build_pedestal() -> void:
	# Cylindrical platform (top surface — pieces rest here).
	var top := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = platform_radius
	cm.bottom_radius = platform_radius
	cm.height = platform_height
	top.mesh = cm
	top.position = Vector3(0, platform_height * 0.5, 0)
	var top_mat := StandardMaterial3D.new()
	top_mat.albedo_color = Color(0.92, 0.92, 0.95)
	top_mat.metallic = 0.3
	top_mat.roughness = 0.4
	top.material_override = top_mat
	add_child(top)

	# Static collision so dropped pieces rest on the surface.
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = platform_radius
	shape.height = platform_height
	cs.shape = shape
	cs.position = Vector3(0, platform_height * 0.5, 0)
	sb.add_child(cs)
	add_child(sb)

	# Glow ring under the platform — visual cue for the capture column.
	var ring := MeshInstance3D.new()
	var rm := TorusMesh.new()
	rm.inner_radius = platform_radius - 0.015
	rm.outer_radius = platform_radius + 0.005
	ring.mesh = rm
	ring.position = Vector3(0, 0.005, 0)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.2, 0.85, 0.95)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.2, 0.85, 0.95)
	ring_mat.emission_energy_multiplier = 1.4
	ring.material_override = ring_mat
	add_child(ring)


func _build_detector() -> void:
	# Area3D defines the "capture column" — a tall cylinder above the platform.
	_detector = Area3D.new()
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = platform_radius
	shape.height = capture_height
	cs.shape = shape
	cs.position = Vector3(0, capture_height * 0.5 + platform_height, 0)
	_detector.add_child(cs)
	add_child(_detector)


func _build_button() -> void:
	# Capture button on a small post next to the platform.
	var btn_scene := load("res://commons/interactables/push_button.tscn") as PackedScene
	if btn_scene == null:
		push_warning("composition_platform: push_button scene missing — capture won't trigger.")
		return
	var btn := btn_scene.instantiate()
	btn.position = Vector3(platform_radius + 0.18, 0.10, 0.0)
	# Match the rim's cyan tint so the affordance reads as one piece.
	if "released_color" in btn:
		btn.released_color = Color(0.15, 0.55, 0.65)
	if "pressed_color" in btn:
		btn.pressed_color = Color(0.2, 0.95, 1.0)
	add_child(btn)
	if btn.has_signal("pressed"):
		btn.pressed.connect(capture)
	else:
		# Fall back to listening on the inner InteractableArea.
		var inner := btn.get_node_or_null("InteractableAreaButton")
		if inner and inner.has_signal("button_pressed"):
			inner.button_pressed.connect(func(_b): capture())


func _build_label() -> void:
	_label = Label3D.new()
	_label.name = "PlatformLabel"
	_label.text = label_prefix + " · ready"
	_label.font_size = 22
	_label.modulate = Color(0.95, 0.95, 1.0, 0.95)
	_label.position = Vector3(0, capture_height + platform_height + 0.1, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)


# ── Capture ──────────────────────────────────────────────────────

## Scan the capture column, build a primitive_stack-compatible config,
## and save it to disk under both user:// and the repo's generated dir.
func capture() -> Dictionary:
	if _detector == null:
		return {}
	var bodies := _detector.get_overlapping_bodies()
	var entries: Array = []
	for b in bodies:
		if not (b is Node3D):
			continue
		# Skip pieces still being held by a controller.
		if b.has_method("is_picked_up") and b.is_picked_up():
			continue
		var shape_str := str(b.get_meta("shape_type", "cube"))
		var col: Color = b.get_meta("piece_color", Color.WHITE)
		var sc: Vector3 = b.scale
		var y: float = b.global_position.y
		entries.append({
			"shape": shape_str,
			"color": _color_to_hex(col),
			# Convert per-axis scale back to a single nominal "scale" by
			# averaging — primitive_stack accepts a scalar `scale` per
			# primitive in its sequence config.
			"scale": (sc.x + sc.y + sc.z) / 3.0,
			"_y": y,
		})

	# Sort bottom → top so the saved sequence matches stacking order.
	entries.sort_custom(func(a, b): return float(a["_y"]) < float(b["_y"]))

	var sequence: Array = []
	for e in entries:
		e.erase("_y")
		sequence.append(e)

	var ts := int(Time.get_unix_time_from_system())
	var cid := "player_%d" % ts
	var cfg := {
		"id": cid,
		"layout": "vertical_stack",
		"palette": "player_creation",
		"base_scale": 0.25,
		"notes": "Player composition captured at runtime — %d primitives." % sequence.size(),
		"captured_at": Time.get_datetime_string_from_system(),
		"sequence": sequence,
	}

	var fname := "%s.json" % cid
	var saved_paths: Array = []
	for dir in [save_dir_user, save_dir_repo]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		var fp: String = dir + fname   # NOT := — `dir` is an untyped loop var, so the sum has no inferred type and the file does not parse
		var f := FileAccess.open(fp, FileAccess.WRITE)
		if f == null:
			push_warning("composition_platform: could not write %s" % fp)
			continue
		f.store_string(JSON.stringify(cfg, "\t"))
		f.close()
		saved_paths.append(fp)

	_capture_count += 1
	_last_path = saved_paths[0] if saved_paths.size() > 0 else ""
	if _label:
		_label.text = "%s · captured %d (last: %d primitives)" % [
			label_prefix, _capture_count, sequence.size(),
		]
	print("[composition_platform] captured %d primitives -> %s" % [sequence.size(), _last_path])
	composition_captured.emit(_last_path, cfg)
	return cfg


# ── Utilities ────────────────────────────────────────────────────

func _color_to_hex(c: Color) -> String:
	return "#%02x%02x%02x" % [int(c.r * 255.0), int(c.g * 255.0), int(c.b * 255.0)]


func apply_grid_config(cfg: Dictionary) -> void:
	var rebuild := false
	if cfg.has("platform_radius"):
		platform_radius = float(cfg["platform_radius"]); rebuild = true
	if cfg.has("capture_height"):
		capture_height = float(cfg["capture_height"]); rebuild = true
	if cfg.has("label_prefix"):
		label_prefix = str(cfg["label_prefix"])
		if _label: _label.text = label_prefix + " · ready"
	if rebuild:
		# Tear down and rebuild geometry / detector.
		for c in get_children():
			c.queue_free()
		_capture_count = 0
		_last_path = ""
		# The config can arrive while this node is OUT of the tree: the grid defers
		# apply_grid_config, and composers (curation_station) configure what they build.
		# get_tree() is null there. Wait for a tree; a node never added never resumes.
		if not is_inside_tree():
			await tree_entered
		await get_tree().process_frame
		_build_pedestal()
		_build_detector()
		_build_button()
		_build_label()
