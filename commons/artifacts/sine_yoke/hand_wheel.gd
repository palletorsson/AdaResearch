extends "res://commons/interactables/physical_angular_control.gd"
## The existing pointer drag and XR handle driver, without a console or motor.
const Driver = preload("res://commons/interactables/angular_driver.gd")
const Handle = preload("res://commons/interactables/angular_handle.gd")
const PointerBody = preload("res://commons/interactables/joystick_pointer_body.gd")
var grip: XRToolsInteractableHandle
var rotor: Node3D

func _ready() -> void:
	# Children are assembled before tree entry so XRTools discovers the grip.
	hinge = get_node("HingeOrigin/InteractableHinge")
	rotor = hinge
	grip = get_node("HingeOrigin/InteractableHinge/Handles/Crank/InteractableHandle")
	hinge.hinge_moved.connect(_on_moved)
	hinge.grabbed.connect(func(_node): _cancel_pointer(false))
	set_process(false)

func assemble() -> void:
	var origin := Node3D.new();origin.name = "HingeOrigin"
	origin.rotation.y = -PI / 2;add_child(origin)
	var driver := Node3D.new();driver.name = "InteractableHinge"
	driver.set_script(Driver)
	driver.hinge_limit_min = -1000000.0;driver.hinge_limit_max = 1000000.0
	origin.add_child(driver)
	var handles := Node3D.new();handles.name = "Handles";driver.add_child(handles)
	var crank := Node3D.new();crank.name = "Crank"
	crank.position = Vector3(.29, 0, -.48);handles.add_child(crank)
	var handle := RigidBody3D.new();handle.name = "InteractableHandle"
	handle.set_script(Handle);handle.control_path = NodePath("../../../../..")
	handle.freeze = true;handle.collision_layer = (1 << 18) | POINTER_LAYERS
	handle.collision_mask = 0;handle.picked_up_layer = 0
	var shape := CollisionShape3D.new();shape.shape = SphereShape3D.new()
	shape.shape.radius = .065;handle.add_child(shape);crank.add_child(handle)
	# Pointer hits on the metal rim forward to this same angular control.
	for i in 24:
		var angle := i * TAU / 24
		var body := StaticBody3D.new();body.set_script(PointerBody)
		body.control_path = NodePath("../../..")
		body.collision_layer = POINTER_LAYERS;body.collision_mask = 0
		body.position = Vector3(.055, sin(angle) * .46, -cos(angle) * .46)
		var hit := CollisionShape3D.new();hit.shape = SphereShape3D.new()
		hit.shape.radius = .065;body.add_child(hit);driver.add_child(body)
