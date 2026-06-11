extends Node3D

## Cube Button — a cube-shaped pressable button on a Dieter Rams plate.
##
## Wraps the proven push_button interactable (the XR area button + press sound) but
## swaps its cylindrical cap for a cube, and sits it on a light backing plate with a
## thin warm accent edge. Emits `pressed` when worked (relayed from push_button).
## Built once in _ready; reusable across the pattern / forces machines.

signal pressed

const PB_SCENE := "res://commons/interactables/push_button.tscn"

@export var cube_size: float = 0.055
@export var show_plate: bool = true
@export var label: String = ""
@export var cap_color: Color = Color(0.28, 0.28, 0.31)   # calm dark cube (Braun)
@export var accent: Color = Color(0.86, 0.34, 0.11)      # the one warm element
@export var plate_color: Color = Color(0.70, 0.68, 0.64) # light grey backing board

var _built := false


func _ready() -> void:
	if not _built:
		_build()


func _build() -> void:
	_built = true

	if show_plate:
		var plate := MeshInstance3D.new()
		plate.name = "Plate"
		var pb := BoxMesh.new()
		pb.size = Vector3(0.12, 0.12, 0.012)
		plate.mesh = pb
		plate.material_override = _mat(plate_color, 0.0, 0.85)
		plate.position = Vector3(0.0, 0.0, -0.009)
		add_child(plate)
		# one thin warm accent line along the bottom (the single Braun gesture)
		var edge := MeshInstance3D.new()
		var eb := BoxMesh.new()
		eb.size = Vector3(0.12, 0.006, 0.005)
		edge.mesh = eb
		edge.material_override = _mat(accent, 0.2, 0.4)
		edge.position = Vector3(0.0, -0.057, -0.002)
		add_child(edge)

	if ResourceLoader.exists(PB_SCENE):
		var btn: Node = load(PB_SCENE).instantiate()
		btn.name = "PushButton"
		add_child(btn)
		# swap the cap mesh for a cube + give it a calm Braun material
		var bm: Node = btn.get_node_or_null("Button/ButtonMesh")
		if bm is MeshInstance3D:
			var cube := BoxMesh.new()
			cube.size = Vector3.ONE * cube_size
			(bm as MeshInstance3D).mesh = cube
			(bm as MeshInstance3D).material_override = _mat(cap_color, 0.0, 0.4, 0.3)
		btn.set("released_color", cap_color)
		btn.set("pressed_color", accent)
		if btn.has_signal("pressed") and not btn.is_connected("pressed", _relay):
			btn.connect("pressed", _relay)

	if label != "":
		var l := Label3D.new()
		l.text = label
		l.font_size = 22
		l.pixel_size = 0.0009
		l.modulate = Color(0.17, 0.17, 0.19)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.position = Vector3(0.0, 0.078, 0.004)
		add_child(l)


func _relay() -> void:
	pressed.emit()


func _mat(c: Color, emit: float, rough: float, metal: float = 0.1) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rough
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m
