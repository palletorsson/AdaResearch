extends Node3D

## Display Console — a grey-metal kiosk body that carries a control plate as its
## reclined screen face. The pattern_control_plate sits on top, tilted back ~28° like
## a lectern / data console, a bit smaller than free-standing. Forwards configure() to
## the plate and relays its `changed` / `randomized` signals, so a machine can drop a
## display_console in place of the bare plate and get the same wiring.

signal changed(key: String, value: float)
signal randomized()

const PLATE_SCENE := "res://commons/artifacts/pattern_tunnel/pattern_control_plate.tscn"

@export var body_color: Color = Color(0.55, 0.56, 0.59)   # brushed grey metal
@export var trim_color: Color = Color(0.28, 0.29, 0.32)   # dark trim
@export var plate_scale: float = 0.5
@export var tilt_deg: float = 28.0

var _plate: Node = null
var _cfg_title: String = "PATTERN CONTROL"
var _cfg_specs: Array = []
var _built := false


func _ready() -> void:
	if not _built:
		_build()


func configure(title: String, specs: Array) -> void:
	_cfg_title = title
	_cfg_specs = specs
	if _plate != null and _plate.has_method("configure"):
		_plate.call("configure", title, specs)


func _build() -> void:
	_built = true

	# --- the cabinet body (a grey-metal podium) ---------------------------------
	add_child(_box(Vector3(0.0, 0.56, -0.04), Vector3(0.92, 1.12, 0.58), _mat(body_color, 0.45, 0.4)))
	add_child(_box(Vector3(0.0, 0.04, 0.0), Vector3(0.98, 0.08, 0.66), _mat(trim_color, 0.6, 0.2)))     # base plinth
	add_child(_box(Vector3(0.0, 1.13, -0.02), Vector3(0.96, 0.06, 0.64), _mat(trim_color, 0.6, 0.2)))   # top lip
	# a small dark front panel detail (like the reference consoles)
	add_child(_box(Vector3(0.0, 0.42, 0.27), Vector3(0.46, 0.5, 0.012), _mat(trim_color, 0.7, 0.15)))
	add_child(_box(Vector3(0.20, 0.42, 0.28), Vector3(0.02, 0.08, 0.012), _mat(Color(0.7, 0.68, 0.64), 0.5, 0.3)))  # handle

	# --- the control plate, reclined on top -------------------------------------
	var plate: Node = load(PLATE_SCENE).instantiate()
	plate.name = "Plate"
	if plate.has_method("configure"):
		plate.call("configure", _cfg_title, _cfg_specs)
	add_child(plate)
	(plate as Node3D).scale = Vector3.ONE * plate_scale
	(plate as Node3D).rotation_degrees = Vector3(-tilt_deg, 0.0, 0.0)
	# seated on the reclined top: board bottom (sliders) at the cabinet front edge,
	# the screen row rising up-and-back
	(plate as Node3D).position = Vector3(0.0, 1.1, 0.24)
	if plate.has_signal("changed"):
		plate.connect("changed", func(k, v): changed.emit(k, v))
	if plate.has_signal("randomized"):
		plate.connect("randomized", func(): randomized.emit())
	_plate = plate


func _box(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = mat
	return mi


func _mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rough
	return m
