extends Node3D
class_name ArtifactReadoutScreen

# Preload (not the global class_name) so a freshly-created kit resolves headless too.
const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the curated, framed 2D-in-3D screen that NAMES an artifact — a worn-metal bezel around a self-lit panel of baked text, on a stalk / wall-plate / legs / desk stand. The deliberate replacement for floating billboard labels.
# desire: to give an artifact a caption that lives in the room with it, lit and framed, instead of a label hovering in the air with no body. A readout you could walk up to and read like a real instrument.
# critical_parameter: mount — stalk (a freestanding readout beside the artifact, image-2 style), wall (a plate against a backing wall), freestand (two-legged sign), desk (a low tabletop screen). The mount is how the caption attaches to the room.
# triggers: _ready/_read_metadata_overrides/_build; apply_grid_config rebuilds with new text/mount/size.
# emerges: green-on-dark + amber header reads "terminal / live"; the stalk + antenna reads "field instrument"; the same text floated as a Label3D reads "UI overlay" — the frame is what makes it diegetic.
# needs: HangarKit.readout (bezel + emissive face + baked header/lines) [present]; painted-metal mount geometry [present]
# relationships: the caption half of the packaging family — names what stands on [[hangar_podium]] or sits in [[hangar_wall_panel]]'s screen slot. Built on BakedTextAlbedo (the fire_extinguisher integrated-text principle) and HangarKit.
# truth: a label that floats is an annotation; a label that is framed, lit, and mounted is part of the world. Text wants a body too.

@export_group("Content")
@export var header: String = "ARTIFACT"
@export_multiline var body: String = "STATUS  OK\nPOWER   30%"

@export_group("Screen")
@export var screen_w: float = 0.5
@export var screen_h: float = 0.34
## stalk | wall | freestand | desk
@export var mount: String = "stalk"

@export_group("Color")
## Dieter Rams / Braun default — calm anthracite screen, warm off-white text, one warm header.
@export var screen_bg: Color = Color(0.12, 0.12, 0.135)
@export var text_color: Color = Color(0.90, 0.89, 0.85)
@export var header_color: Color = Color(0.86, 0.34, 0.11)
@export var frame_color: Color = Color(0.70, 0.68, 0.64)

const MOUNT_Y := {"stalk": 1.25, "wall": 1.55, "freestand": 1.35, "desk": 0.95}

var _built := false


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
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_header"): header = str(get_meta("config_header"))
	if has_meta("config_body"): body = str(get_meta("config_body"))
	if has_meta("config_screen_w"): screen_w = float(str(get_meta("config_screen_w")))
	if has_meta("config_screen_h"): screen_h = float(str(get_meta("config_screen_h")))
	if has_meta("config_mount"): mount = str(get_meta("config_mount")).to_lower()
	if has_meta("config_screen_bg"): screen_bg = _pc(str(get_meta("config_screen_bg")), screen_bg)
	if has_meta("config_text_color"): text_color = _pc(str(get_meta("config_text_color")), text_color)
	if has_meta("config_header_color"): header_color = _pc(str(get_meta("config_header_color")), header_color)
	if has_meta("config_frame_color"): frame_color = _pc(str(get_meta("config_frame_color")), frame_color)


func _build() -> void:
	_built = true
	var lines: Array = []
	for l in body.split("\n"):
		if str(l).strip_edges() != "":
			lines.append(str(l))
	var sy: float = float(MOUNT_Y.get(mount, 1.25))

	var ro: Node3D = HangarKit.readout(header, lines, Vector2(screen_w, screen_h), screen_bg, text_color, header_color)
	ro.position = Vector3(0, sy, 0)
	add_child(ro)

	match mount:
		"wall": _build_wall(sy)
		"freestand": _build_legs(sy)
		"desk": _build_desk(sy)
		_: _build_stalk(sy)


func _build_stalk(sy: float) -> void:
	var mat := HangarKit.rams_body(frame_color, 0.08)
	var worn := HangarKit.rams_body(frame_color, 0.14)
	# foot
	add_child(HangarKit.box(Vector3(0, 0.05, -0.02), Vector3(0.22, 0.10, 0.18), worn))
	# post up the back of the screen
	var post := CylinderMesh.new()
	post.top_radius = 0.025
	post.bottom_radius = 0.03
	post.height = sy - 0.08
	var pm := MeshInstance3D.new()
	pm.mesh = post
	pm.material_override = mat
	pm.position = Vector3(0, (sy - 0.08) * 0.5 + 0.08, -screen_h * 0.5 - 0.05)
	add_child(pm)
	# antenna arcing up off the top — the field-instrument silhouette (image 2)
	var amat := HangarKit.worn_metal(Color(0.12, 0.12, 0.14))
	var prev: Vector3 = Vector3(0, sy + screen_h * 0.5, -0.04)
	for i in range(5):
		var t: float = float(i + 1) / 5.0
		var nxt := Vector3(t * 0.16, sy + screen_h * 0.5 + t * 0.55, -0.04 - t * 0.06)
		add_child(_rod(prev, nxt, 0.012, amat))
		prev = nxt
	add_child(HangarKit.box(prev, Vector3(0.03, 0.03, 0.03), HangarKit.emissive(text_color, 1.8)))


func _build_wall(sy: float) -> void:
	# a tall narrow backing plate (reads as wall-mounted signage)
	var mat := HangarKit.rams_body(frame_color, 0.08)
	add_child(HangarKit.box(Vector3(0, sy, -0.05), Vector3(screen_w + 0.3, 2.0, 0.06), mat))
	# bolt rows down the sides
	var bm := HangarKit.worn_metal(Color(0.1, 0.1, 0.12))
	add_child(HangarKit.bolts(Vector3(-screen_w * 0.5 - 0.1, sy - 0.9, -0.015), Vector3(-screen_w * 0.5 - 0.1, sy + 0.9, -0.015), 4, 0.02, bm))
	add_child(HangarKit.bolts(Vector3(screen_w * 0.5 + 0.1, sy - 0.9, -0.015), Vector3(screen_w * 0.5 + 0.1, sy + 0.9, -0.015), 4, 0.02, bm))


func _build_legs(sy: float) -> void:
	var mat := HangarKit.rams_body(frame_color, 0.08)
	var foot := HangarKit.rams_body(frame_color, 0.13)
	for sx in [-1.0, 1.0]:
		var x: float = sx * (screen_w * 0.5 - 0.04)
		var leg := CylinderMesh.new()
		leg.top_radius = 0.022
		leg.bottom_radius = 0.028
		leg.height = sy - screen_h * 0.5
		var lm := MeshInstance3D.new()
		lm.mesh = leg
		lm.material_override = mat
		lm.position = Vector3(x, (sy - screen_h * 0.5) * 0.5, -0.03)
		add_child(lm)
		add_child(HangarKit.box(Vector3(x, 0.02, -0.03), Vector3(0.18, 0.04, 0.18), foot))


func _build_desk(sy: float) -> void:
	var mat := HangarKit.rams_body(frame_color, 0.13)
	# small wedge stand under a low screen
	add_child(HangarKit.box(Vector3(0, 0.04, -0.02), Vector3(screen_w + 0.1, 0.08, 0.16), mat))
	add_child(HangarKit.box(Vector3(0, sy * 0.5, -screen_h * 0.5 - 0.03), Vector3(0.06, sy, 0.06), mat))


func _rod(a: Vector3, b: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = maxf(a.distance_to(b), 0.001)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	var y: Vector3 = (b - a).normalized()
	var ref: Vector3 = Vector3.UP if absf(y.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	mi.transform = Transform3D(Basis(x, y, z), (a + b) * 0.5)
	return mi


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
