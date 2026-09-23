extends Node3D
## Working reference for the shared instrument profile. The physical controls
## retain their native input paths; their effects are visible on the specimen.
const Presets = preload("res://commons/ui/interface_presets.gd")
@export var skin: String = "braun"
var console: Node3D
var size_control: Node3D
var turn_control: Node3D
var position_control: Node3D
var reset_control: Node3D
var specimen: MeshInstance3D
var readout: Label
var offset := Vector2.ZERO

func _ready() -> void:
	_make_stage()
	console = Presets.build("workbench", "BODY / TRANSFORM", 1.0, skin, "instrument")
	console.panel().layout_columns = 2
	console.position.y = 1.0
	add_child(console)
	readout = console.add_readout("")
	size_control = console.add_slider("SIZE", "size")
	size_control.set_range(0.5, 1.5)
	turn_control = console.add_dial("TURN", "turn")
	turn_control.set_range(-135, 135)
	position_control = console.add_joystick("POSITION")
	reset_control = console.add_button("RESET")
	size_control.slider_moved.connect(func(_v): _apply())
	turn_control.hinge_moved.connect(func(_v): _apply())
	var joystick := position_control.get_node("JoystickOrigin/InteractableJoystick")
	joystick.joystick_moved.connect(_on_position)
	reset_control.pressed.connect(reset)
	reset()

func reset() -> void:
	size_control.set_normalized_value(0.5)
	turn_control.set_normalized_value(0.5)
	position_control.get_node("JoystickOrigin/InteractableJoystick").move_joystick(0.0, 0.0)
	offset = Vector2.ZERO
	_apply()

func _on_position(x_degrees: float, y_degrees: float) -> void:
	offset = Vector2(x_degrees, y_degrees) / 45.0
	_apply()

func _apply() -> void:
	var size_value: float = lerpf(0.5, 1.5, size_control.get_normalized_value())
	var turn_value: float = lerpf(-135, 135, turn_control.get_normalized_value())
	specimen.scale = Vector3.ONE * size_value
	specimen.rotation_degrees.y = turn_value
	specimen.position = Vector3(offset.x * 0.22, 1.49 + size_value * 0.16, -0.90 + offset.y * 0.22)
	readout.text = "SIZE %.2f   TURN %+.0f°\nX %+.2f   Z %+.2f" % [size_value, turn_value, offset.x, offset.y]

func _make_stage() -> void:
	var stage := MeshInstance3D.new()
	var drum := CylinderMesh.new()
	drum.top_radius = 0.34
	drum.bottom_radius = 0.34
	drum.height = 0.04
	stage.mesh = drum
	stage.position = Vector3(0, 1.47, -0.90)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.16, 0.19, 0.19)
	dark.roughness = 0.7
	stage.material_override = dark
	add_child(stage)
	var support := MeshInstance3D.new()
	var stem := BoxMesh.new()
	stem.size = Vector3(0.14, 1.45, 0.14)
	support.mesh = stem
	support.position = Vector3(0, 0.725, -0.90)
	support.material_override = dark
	add_child(support)
	specimen = MeshInstance3D.new()
	specimen.name = "Specimen"
	var block := BoxMesh.new()
	block.size = Vector3(0.4, 0.32, 0.22)
	specimen.mesh = block
	var orange := StandardMaterial3D.new()
	orange.albedo_color = Color(0.95, 0.35, 0.10)
	orange.roughness = 0.35
	specimen.material_override = orange
	add_child(specimen)
