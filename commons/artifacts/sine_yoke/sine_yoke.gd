extends Node3D
## Hand-driven Scotch yoke: the visible pin's Y coordinate constrains the slider.
## This is an ideal kinematic constraint, not a force/contact simulation. No clock,
## motor, hidden independent oscillator, inertia or simulated mechanical effort.
## Rotation has to come from the existing desktop pointer or XRTools crank grip.
const Timber = preload("res://commons/artifacts/primitive_encounters/timber_finish.gd")
const Wheel = preload("res://commons/artifacts/sine_yoke/hand_wheel.gd")
const MachineFinish = preload("res://commons/artifacts/machine_finish.gd")
@export_range(.2, .42) var crank_radius := .38
@export_range(.2, .42) var cube_edge := .36
@export var initial_angle := -25.0
signal state_changed(state: Dictionary)
var part_defaults: Dictionary = {}
var support: Node3D
var mechanism: Node3D
var wheel: Node3D
var pin: Node3D
var yoke: Node3D
var cube: Node3D
var steel: StandardMaterial3D
var brass: StandardMaterial3D
var wood: StandardMaterial3D
var angle_degrees := 0.0

func _ready() -> void:
	steel = MachineFinish.steel()
	brass = MachineFinish.ivory()
	wood = Timber.material()
	support = Node3D.new();support.name = "Support";add_child(support)
	for x in [-.2, 1.0]:
		box(support, Vector3(x, .065, 0), Vector3(.27, .13, .85), steel, true)
		box(support, Vector3(x, .14, -.22), Vector3(.12, .05, .55), steel)
	box(support, Vector3(.4, .22, -.22), Vector3(1.55, .16, .15), steel, true)
	box(support, Vector3(0, .74, -.23), Vector3(.12, 1.1, .14), steel, true)
	box(support, Vector3(0, 1.25, -.19), Vector3(.23, .23, .2), steel)
	box(support, Vector3(.98, 1.1, -.23), Vector3(.12, 1.8, .14), steel, true)
	for y in [.61, 1.89]:
		box(support, Vector3(.98, y, -.04), Vector3(.62, .08, .42), steel)
	for x in [.73, 1.23]:
		rod(support, Vector3(x, .59, .15), Vector3(x, 1.91, .15), .022, steel)
	# The mechanism remains one coupled editable part. Moving it preserves the
	# pin/slot/cube relation; its fixed support can be staged separately.
	mechanism = Node3D.new();mechanism.name = "Mechanism"
	mechanism.position.y = 1.25
	wheel = Wheel.new();wheel.name = "HandWheel";wheel.assemble()
	mechanism.add_child(wheel)
	var rotor: Node3D = wheel.get_node("HingeOrigin/InteractableHinge")
	# The hinge's X axis becomes world Z; all visible rotor geometry is in that frame.
	var rim := MeshInstance3D.new();rim.name = "OpenWheel"
	var torus := TorusMesh.new();torus.inner_radius = .435;torus.outer_radius = .485
	torus.rings = 48;torus.ring_segments = 10;rim.mesh = torus
	rim.rotation.z = PI / 2;rim.position.x = .04;rim.material_override = steel;rotor.add_child(rim)
	for i in 3:
		var a := i * TAU / 3
		rod(rotor, Vector3(.04,0,0), Vector3(.04,sin(a)*.45,-cos(a)*.45), .022, steel)
	rod(rotor, Vector3(-.16,0,0), Vector3(.11,0,0), .055, steel)
	rod(rotor, Vector3(.04,0,0), Vector3(.04,0,-crank_radius), .034, brass)
	rod(rotor, Vector3(.05,0,-.48), Vector3(.29,0,-.48), .028, brass)
	rod(rotor, Vector3(.23,0,-.48), Vector3(.34,0,-.48), .045, MachineFinish.pink()).name = "PinkGrip"
	pin = rod(rotor, Vector3(.06,0,-crank_radius), Vector3(.27,0,-crank_radius), .039, brass)
	pin.name = "VisibleCrankPin"
	# A narrow slot with rounded roller clearance, open to view from the front.
	yoke = Node3D.new();yoke.name = "SlottedYoke";mechanism.add_child(yoke)
	for y in [-.082, .082]:box(yoke, Vector3(0,y,.18), Vector3(1.02,.085,.075), steel)
	for x in [-.51, .51]:box(yoke, Vector3(x,0,.18), Vector3(.08,.249,.075), steel)
	rod(yoke, Vector3(.55,0,.18), Vector3(.98,0,.18), .035, steel)
	cube = box(yoke, Vector3(.98,0,.15), Vector3.ONE*cube_edge, MachineFinish.ivory())
	cube.name = "DrivenTimberCube"
	MachineFinish.outline(cube,cube_edge)
	# Small brass shoes make the attachment to the guides legible.
	for x in [.73,1.23]:box(yoke, Vector3(x,0,.15), Vector3(.085,.09,.085), brass)
	add_child(mechanism)
	wheel.hinge_moved.connect(_on_turn)
	wheel.set_angle_degrees(initial_angle)
	_on_turn(initial_angle)
	for child: Node3D in [support, mechanism]:
		var b := mesh_bounds(child, child)
		part_defaults[str(child.name)] = {"position":[child.position.x,child.position.y,child.position.z],"rotation":[0,0,0],"bounds":[b.position.x,b.position.y,b.position.z,b.size.x,b.size.y,b.size.z]}
	# The mechanism's editor box is its full sweep, not only the stopped snapshot.
	part_defaults.Mechanism.bounds = [-.55,-.62,-.2,1.83,1.24,.6]

func _on_turn(degrees: float) -> void:
	angle_degrees = degrees
	# Resolve the actual rendered pin in the mechanism's rest frame, rather than
	# run a second animation. A horizontal slot permits X and fixes the same Y.
	var pin_centre: Vector3 = wheel.rotor.to_global(Vector3(.18,0,-crank_radius))
	yoke.position.y = mechanism.to_local(pin_centre).y
	state_changed.emit({"angle":degrees,"displacement":yoke.position.y})

func apply_grid_config(config: Dictionary) -> void:
	if not is_node_ready():return
	if config.has("initial_angle") and is_instance_valid(wheel):wheel.set_angle_degrees(float(config.initial_angle))
	for child: Node3D in [support, mechanism]:
		if not is_instance_valid(child):continue
		var id := str(child.name)
		var shown: bool = not config.has("only_parts") or id in config.only_parts
		if not shown:
			part_defaults.erase(id)
			child.free()
			continue
		var pose: Dictionary = config.get("parts",{}).get(id,part_defaults[id])
		var at: Array = pose.get("position",part_defaults[id].position)
		var angles: Array = pose.get("rotation",part_defaults[id].rotation)
		child.position = Vector3(at[0],at[1],at[2])
		child.rotation_degrees = Vector3(angles[0],angles[1],angles[2])
		sync_bodies(child)

func sync_bodies(node: Node) -> void:
	if node is RigidBody3D:
		PhysicsServer3D.body_set_state(node.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,node.global_transform)
	for child in node.get_children():sync_bodies(child)

func finish(hex: String, metal: float, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new();mat.albedo_color = Color(hex)
	mat.metallic = metal;mat.roughness = roughness;return mat

func box(host: Node3D, at: Vector3, size: Vector3, mat: Material, solid := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = Timber.mesh(size) if mat == wood else BoxMesh.new()
	if mesh.mesh is BoxMesh:mesh.mesh.size = size
	mesh.material_override = mat;mesh.position = at;host.add_child(mesh)
	if solid:
		var body := StaticBody3D.new();var hit := CollisionShape3D.new()
		hit.shape = BoxShape3D.new();hit.shape.size = size;body.add_child(hit);mesh.add_child(body)
	return mesh

func rod(host: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new();var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius;cylinder.bottom_radius = radius;cylinder.height = a.distance_to(b)
	cylinder.radial_segments = 24;mesh.mesh = cylinder;mesh.material_override = mat
	mesh.position = (a+b)*.5
	mesh.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	host.add_child(mesh);return mesh

func mesh_bounds(node: Node3D, relative: Node3D) -> AABB:
	var result := AABB();var first := true
	for child in node.find_children("*","MeshInstance3D",true,false):
		if child.mesh == null:continue
		var b: AABB = relative.global_transform.affine_inverse()*child.global_transform*child.get_aabb()
		result = b if first else result.merge(b);first = false
	return result
