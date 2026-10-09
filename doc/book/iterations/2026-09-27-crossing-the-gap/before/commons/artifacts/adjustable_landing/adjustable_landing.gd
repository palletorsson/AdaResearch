extends Node3D
## A bank is a participant in a crossing. Root stands on the left side aisle;
## the landing is two metres to its right. No bridge transform is modified.
## In Trans_Introduction, root (3,18), landing (5,20), bridge centre (5,17).

const TRAVEL := 1.0
const SPEED := 0.25
const HOME := Vector3(2.0, -0.10, 2.0)
const SIZE := Vector3(3.0, 0.20, 3.0)
var displacement := 0.0
var target_displacement := 0.0
var landing: AnimatableBody3D
var slider: Node
var readout: Label3D
var _syncing := false
var control_rig: Node3D
var control_offset := Vector3.ZERO

func _ready() -> void:
	control_rig = Node3D.new()
	control_rig.name = "BankControls"
	control_rig.position = control_offset
	add_child(control_rig)
	landing = AnimatableBody3D.new()
	landing.name = "MovingBank"
	landing.collision_layer = 1
	landing.collision_mask = 0
	landing.position = HOME
	add_child(landing)
	# A 3 mm visual lift avoids coplanar flicker where the bank overlaps the
	# fixed exit floor. The collider itself remains precisely at deck height.
	box(landing, SIZE, Vector3(0,0.003,0), Color("58b9ba"))
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = SIZE
	collision.shape = shape
	landing.add_child(collision)
	# White leading edge and stripes make the same bank legible as it moves.
	box(landing, Vector3(3.0,0.012,0.07), Vector3(0,0.109,-1.45), Color("fff1d2"))
	for x in [-1.25,1.25]:
		box(landing, Vector3(0.035,0.012,2.8), Vector3(x,0.109,0), Color("163d49"))
	for x in [0.58,3.42]:
		box(self, Vector3(0.05,0.08,4.0), Vector3(x,-0.26,2.5), Color("b6a895"))
	box(control_rig, Vector3(0.40,0.96,0.34), Vector3(0,0.48,-0.10), Color("263942"))
	var rack: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = rack.create_panel("MOVE THE BANK", [
		[{"type":"slider_h", "label":"BANK", "default":-1.0}],
		[{"type":"button", "label":"RESET"}]])
	panel.position = Vector3(0,1.06,-0.1)
	panel.rotation_degrees = Vector3(-25,180,0)
	panel.scale = Vector3.ONE * 2.0
	control_rig.add_child(panel)
	slider = panel.find_child("Param_0",true,false)
	slider.slider_moved.connect(_on_slider)
	var reset := panel.find_child("Btn_0",true,false).get_node("InteractableAreaButton")
	reset.button_pressed.connect(func(_button): reset_landing())
	readout = Label3D.new()
	readout.name = "BankReadout"
	box(control_rig, Vector3(0.64,0.21,0.035), Vector3(0,1.40,0.025), Color("263942"))
	readout.position = Vector3(0,1.40,0)
	readout.rotation_degrees.y = 180
	readout.font_size = 32
	readout.pixel_size = 0.0012
	readout.outline_size = 5
	control_rig.add_child(readout)
	_update_readout()
	reset_landing.call_deferred()

func apply_grid_config(config: Dictionary) -> void:
	if config.has("control_offset"):
		var value: Variant = config["control_offset"]
		var candidate := Vector3.ZERO
		if value is Vector3:
			candidate = value
		else:
			var parts := str(value).split(",")
			if parts.size() != 3:
				return
			for part in parts:
				if not str(part).is_valid_float():
					return
			candidate = Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
		if not candidate.is_finite():
			return
		control_offset = candidate
		if is_instance_valid(control_rig):
			control_rig.position = control_offset


func _on_slider(_value: Variant) -> void:
	if not _syncing:
		set_bank_fraction(float(slider.get_normalized_value()))

func set_bank_fraction(fraction: float) -> void:
	target_displacement = clampf(fraction,0.0,1.0) * TRAVEL
	if is_instance_valid(slider) and not _syncing:
		_syncing = true
		slider.set_normalized_value(target_displacement/TRAVEL)
		_syncing = false

func reset_landing() -> void:
	set_bank_fraction(0.0)

func _physics_process(delta: float) -> void:
	displacement = move_toward(displacement,target_displacement,SPEED * delta)
	landing.position = HOME + Vector3.BACK * displacement
	_update_readout()

func _update_readout() -> void:
	# This is a surface relation at the bridge's quarter-turn pose, not a claim
	# that a particular capsule can/cannot cross a particular gap.
	var separation := displacement - 0.30
	var relation := "overlap %.2f m" % -separation if separation <= 0 else "gap %.2f m" % separation
	readout.text = "BANK +%.2f m\nAligned: %s\nRESET / side aisles open" % [displacement,relation]

func box(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.6
	mesh.material_override = material
	parent.add_child(mesh)
