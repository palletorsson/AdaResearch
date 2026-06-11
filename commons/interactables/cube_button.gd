extends Node3D

## Cube Button — a cube-shaped pressable button seated in a Dieter Rams plate.
##
## Wraps the proven push_button interactable (XR area button + press sound) but hides
## push_button's own round cap base + accent ring and swaps the cap mesh for a cube, so
## the only visual is a clean cube sitting in a light plate with a raised rim (the box).
## Emits `pressed` (relayed). Reusable across the pattern / forces machines.

signal pressed

const PB_SCENE := "res://commons/interactables/push_button.tscn"

@export var cube_size: float = 0.06
@export var show_plate: bool = true
@export var label: String = ""
@export var cap_color: Color = Color(0.28, 0.28, 0.31)   # calm dark cube (Braun)
@export var accent: Color = Color(0.86, 0.34, 0.11)      # warm press colour
@export var plate_color: Color = Color(0.72, 0.70, 0.66) # light grey plate
@export var frame_color: Color = Color(0.55, 0.53, 0.50) # raised rim

var _built := false


func _ready() -> void:
	if not _built:
		_build()


func _build() -> void:
	_built = true

	if show_plate:
		add_child(_box(Vector3(0.0, 0.0, -0.012), Vector3(0.15, 0.15, 0.014), _mat(plate_color, 0.85)))
		_rim(0.14, 0.14, 0.012)

	if ResourceLoader.exists(PB_SCENE):
		var btn: Node = load(PB_SCENE).instantiate()
		btn.name = "PushButton"
		add_child(btn)
		# hide push_button's own base plate + accent ring — the plate/rim above IS the box
		var base: Node = btn.get_node_or_null("ButtonBase")
		if base is Node3D:
			(base as Node3D).visible = false
		var ring: Node = btn.get_node_or_null("AccentRing")
		if ring is Node3D:
			(ring as Node3D).visible = false
		# swap the round cap for a cube
		var bm: Node = btn.get_node_or_null("Button/ButtonMesh")
		if bm is MeshInstance3D:
			var cube := BoxMesh.new()
			cube.size = Vector3.ONE * cube_size
			(bm as MeshInstance3D).mesh = cube
			(bm as MeshInstance3D).material_override = _mat(cap_color, 0.4, 0.3)
		btn.set("released_color", cap_color)
		btn.set("pressed_color", accent)
		if btn.has_signal("pressed") and not btn.is_connected("pressed", _relay):
			btn.connect("pressed", _relay)

	if label != "":
		var l := Label3D.new()
		l.text = label
		l.font_size = 20
		l.pixel_size = 0.0011
		l.modulate = Color(0.17, 0.17, 0.19)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.position = Vector3(0.0, 0.10, 0.004)
		add_child(l)


func _rim(w: float, h: float, thick: float) -> void:
	var m := _mat(frame_color, 0.55)
	var hw := w * 0.5
	var hh := h * 0.5
	var z := 0.006
	add_child(_box(Vector3(0.0, hh, z), Vector3(w + thick, thick, 0.012), m))
	add_child(_box(Vector3(0.0, -hh, z), Vector3(w + thick, thick, 0.012), m))
	add_child(_box(Vector3(-hw, 0.0, z), Vector3(thick, h, 0.012), m))
	add_child(_box(Vector3(hw, 0.0, z), Vector3(thick, h, 0.012), m))


func _relay() -> void:
	pressed.emit()


func _box(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = mat
	return mi


func _mat(c: Color, rough: float, metal: float = 0.1) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rough
	return m
