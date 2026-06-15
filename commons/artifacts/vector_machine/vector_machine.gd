extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name VectorMachine

## @identity
## lineage: the dial of gravity — a console that aims and sizes the one vector ruling the
##   force field next to it. Point it down for the void to swallow; tilt it up-and-across to
##   turn the void into a bridge.
## essence: three controls — PITCH (down ↔ up), YAW (which way across), FORCE (how hard) —
##   compose a single force vector, drawn live as a big arrow, and pushed straight into every
##   force_field in the room. The default is gravity: straight down, 9.8.
## truth: a field is only ever as dangerous as the vector you hand it; this machine is where
##   the danger is chosen.
##
## Drives every node in group "force_field" via set_field_vector(). Sliders are the project's
## grabbable slider_horizontal (works in VR and with the desktop pointer).

const SLIDER := preload("res://commons/interactables/slider_horizontal.tscn")

@export var force_max: float = 15.0
@export var body_color: Color = Color(0.13, 0.14, 0.17)
@export var arrow_color: Color = Color(0.98, 0.78, 0.30)

var _pitch: Node3D
var _yaw: Node3D
var _mag: Node3D
var _preview: Node3D
var _arrow_mat: StandardMaterial3D
var _readout: Label3D


func _ready() -> void:
	_build()
	call_deferred("_update")          # push the default vector once the field is in the tree too


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("force_max"): force_max = float(config_data["force_max"])
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	body_color = _parse_color(config_data.get("body_color", body_color), body_color)
	# (sliders are scene instances — keep the existing build; just refresh the push)
	if _pitch == null:
		_build()
	call_deferred("_update")


func _build() -> void:
	# --- pedestal ---------------------------------------------------------------
	add_child(_box(Vector3(0, 0.5, 0), Vector3(0.7, 1.0, 0.5), _dark(body_color)))
	add_child(_box(Vector3(0, 1.04, 0.06), Vector3(0.72, 0.12, 0.62), _dark(body_color.lerp(Color(0.3,0.32,0.38), 0.4))))
	add_child(_box(Vector3(0, 0.02, 0), Vector3(0.84, 0.04, 0.64), _dark(body_color.darkened(0.3))))

	# --- the three sliders on the deck -----------------------------------------
	_pitch = _add_slider("PITCH", 0.0, Vector3(0, 1.12, 0.14))      # 0 = straight down
	_yaw = _add_slider("YAW", 0.0, Vector3(0, 1.12, 0.0))
	_mag = _add_slider("FORCE", 9.8 / force_max, Vector3(0, 1.12, -0.14))

	# --- the live preview arrow + readout --------------------------------------
	_preview = Node3D.new(); _preview.position = Vector3(0, 1.55, 0); add_child(_preview)
	_arrow_mat = _glow_mat(arrow_color, 2.0)
	_preview.add_child(_arrow(Vector3.ZERO, Vector3(0, 0.7, 0), 0.04, _arrow_mat))
	add_child(_sphere(Vector3(0, 1.55, 0), 0.05, _glow_mat(arrow_color.darkened(0.2), 1.0)))
	_readout = _billboard_label("", Vector3(0, 2.0, 0), 26, arrow_color.lerp(Color.WHITE, 0.3))
	add_child(_readout)


func _add_slider(label: String, default_norm: float, pos: Vector3) -> Node3D:
	var s := SLIDER.instantiate()
	s.position = pos
	s.scale = Vector3.ONE * 0.5
	add_child(s)
	if s.has_method("set_param_name"): s.set_param_name(label)
	if s.has_method("set_normalized_value"): s.set_normalized_value(default_norm)
	if s.has_signal("slider_moved"): s.slider_moved.connect(_on_slider_moved)
	return s


func _on_slider_moved(_v: float) -> void:
	_update()


func current_vector() -> Vector3:
	var pn: float = _pitch.get_normalized_value() if _pitch and _pitch.has_method("get_normalized_value") else 0.0
	var yn: float = _yaw.get_normalized_value() if _yaw and _yaw.has_method("get_normalized_value") else 0.0
	var mn: float = _mag.get_normalized_value() if _mag and _mag.has_method("get_normalized_value") else 0.65
	var pitch: float = lerpf(-PI * 0.5, PI * 0.5, pn)        # down ↔ up
	var yaw: float = yn * TAU
	var mag: float = mn * force_max
	var dir := Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw))
	return dir * mag


func _update() -> void:
	var v := current_vector()
	var mag: float = v.length()
	# preview arrow: redraw pointing along the vector (robust — no basis timing)
	if _preview:
		for ch in _preview.get_children():
			_preview.remove_child(ch); ch.queue_free()
		if mag > 0.001:
			_preview.add_child(_arrow(Vector3.ZERO, v.normalized() * clampf(mag / 9.8, 0.35, 2.0) * 0.6, 0.04, _arrow_mat))
	if _readout:
		var dy: float = v.y
		var word: String = "DOWN — fall" if dy < -1.0 else ("UP — lift" if dy > 1.0 else "ACROSS")
		_readout.text = "VECTOR MACHINE\nF = (%.1f, %.1f, %.1f)\n|F| = %.1f   %s" % [v.x, v.y, v.z, mag, word]
	# drive every force field in the room
	for f in get_tree().get_nodes_in_group("force_field"):
		if f.has_method("set_field_vector"):
			f.set_field_vector(v)


func _dark(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c; m.roughness = 0.6; m.metallic = 0.35
	return m
