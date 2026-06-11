extends Node3D

## Display Console — a grey-metal kiosk whose slanted screen face is a real CSG cut.
##
## A CSGCombiner3D: a cabinet block, minus a 28°-rotated wedge (the angled top face),
## minus a shallow pocket where the control plate is recessed — so the board sits INSIDE
## the console, framed by the metal bezel, like the reference data consoles. Forwards
## configure() to the plate and relays its changed / randomized signals.

signal changed(key: String, value: float)
signal randomized()

const PLATE_SCENE := "res://commons/artifacts/pattern_tunnel/pattern_control_plate.tscn"

@export var body_color: Color = Color(0.55, 0.56, 0.59)   # brushed grey metal
@export var trim_color: Color = Color(0.28, 0.29, 0.32)   # dark trim
@export var plate_scale: float = 0.85   # board scaled down a bit; the plate counter-scales its XR controls back to world-1.0
@export var tilt_deg: float = 28.0

# the slanted face is centred here (a point on the upper-front of the cabinet)
const FACE_CENTER := Vector3(0.0, 1.64, 0.22)

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

	# --- the cabinet body, cut by CSG -------------------------------------------
	var body := CSGCombiner3D.new()
	body.name = "Body"
	add_child(body)

	var block := CSGBox3D.new()
	block.name = "Block"
	block.size = Vector3(1.74, 2.1, 0.72)
	block.position = Vector3(0.0, 1.05, 0.0)
	block.material = _mat(body_color, 0.45, 0.4)
	body.add_child(block)

	# the 28° wedge: a big box reclined by tilt, sitting above the face plane, whose
	# under-side slices the top of the block into the slanted screen face.
	var wedge := CSGBox3D.new()
	wedge.name = "Cut28"
	wedge.operation = CSGShape3D.OPERATION_SUBTRACTION
	wedge.size = Vector3(2.4, 1.8, 2.4)
	wedge.rotation_degrees = Vector3(-tilt_deg, 0.0, 0.0)
	wedge.position = FACE_CENTER + _face_normal() * 1.0
	body.add_child(wedge)

	# a shallow pocket in the slanted face so the plate sits recessed (the bezel)
	var pocket := CSGBox3D.new()
	pocket.name = "Pocket"
	pocket.operation = CSGShape3D.OPERATION_SUBTRACTION
	pocket.size = Vector3(1.32, 1.24, 0.08)
	pocket.rotation_degrees = Vector3(-tilt_deg, 0.0, 0.0)
	pocket.position = FACE_CENTER
	body.add_child(pocket)

	# --- detailing (regular boxes) ----------------------------------------------
	add_child(_box(Vector3(0.0, 0.05, 0.0), Vector3(1.84, 0.1, 0.82), _mat(trim_color, 0.6, 0.2)))    # base plinth
	add_child(_box(Vector3(0.0, 0.62, 0.37), Vector3(0.82, 0.84, 0.014), _mat(trim_color, 0.7, 0.15)))# door
	add_child(_box(Vector3(0.34, 0.62, 0.38), Vector3(0.025, 0.12, 0.014), _mat(Color(0.7, 0.68, 0.64), 0.5, 0.3)))  # handle

	# --- the control plate, recessed flush in the slanted pocket ----------------
	var plate: Node = load(PLATE_SCENE).instantiate()
	plate.name = "Plate"
	plate.set("control_scale", 1.0 / maxf(plate_scale, 0.01))   # XR controls stay world-1.0 despite the scaled plate
	if plate.has_method("configure"):
		plate.call("configure", _cfg_title, _cfg_specs)
	add_child(plate)
	(plate as Node3D).scale = Vector3.ONE * plate_scale
	(plate as Node3D).rotation_degrees = Vector3(-tilt_deg, 0.0, 0.0)
	# the plate's local board centre is ~0.62 above its origin; offset so the board
	# centre lands on FACE_CENTER, just proud of the pocket floor.
	var face_n := _face_normal()
	var down_face := Vector3(0.0, -cos(deg_to_rad(tilt_deg)), sin(deg_to_rad(tilt_deg)))  # plate's local -Y in world
	(plate as Node3D).position = FACE_CENTER + down_face * (0.62 * plate_scale) + face_n * 0.012
	if plate.has_signal("changed"):
		plate.connect("changed", func(k, v): changed.emit(k, v))
	if plate.has_signal("randomized"):
		plate.connect("randomized", func(): randomized.emit())
	_plate = plate


## Outward normal of the reclined face (plate's local +Z, tilted -tilt about X).
func _face_normal() -> Vector3:
	var t := deg_to_rad(tilt_deg)
	return Vector3(0.0, sin(t), cos(t))


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
