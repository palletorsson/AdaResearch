extends Node3D

# Vector-Joint Playground
# Human-scale VR arena with 6 interactive stations.
# Each station pairs draggable vectors with a large physics joint mechanism.

const VECTOR_SCENE := preload("res://commons/primitives/line/line.tscn")
const GadgetBaseScript = preload("res://algorithms/vectors/shared/gadgets/gadget_base.gd")

# Layout
const STATION_RADIUS := 6.0
const STATION_COUNT := 6
const STATION_ARC_DEG := 180.0

# Colors (matching GadgetBase palette)
const COLOR_A := Color(1.0, 0.55, 0.2)       # Orange â€“ vector A
const COLOR_B := Color(0.3, 0.8, 0.9)        # Cyan â€“ vector B
const COLOR_RESULT := Color(0.95, 0.85, 0.2)  # Yellow â€“ result
const COLOR_METAL := Color(0.45, 0.48, 0.52)
const COLOR_DARK := Color(0.2, 0.22, 0.25)
const COLOR_FRAME := Color(0.15, 0.16, 0.18)

# Per-station bookkeeping
var _stations: Array = []  # Array of Dictionaries

# Material cache
var _mat_cache: Dictionary = {}

# Throttle text updates
var _text_timer: float = 0.0
const TEXT_INTERVAL := 0.1

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
#  LIFECYCLE
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _ready() -> void:
	_build_arena()
	_build_station_crane()
	_build_station_pistons()
	_build_station_door()
	_build_station_seesaw()
	_build_station_waterwheel()
	_build_station_spring()

func _process(delta: float) -> void:
	_text_timer += delta
	var do_text := _text_timer >= TEXT_INTERVAL
	if do_text:
		_text_timer = 0.0

	_update_crane(do_text)
	_update_pistons(do_text)
	_update_door(do_text)
	_update_seesaw(do_text)
	_update_waterwheel(do_text)
	_update_spring(do_text)

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
#  ARENA
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _build_arena() -> void:
	# Floor
	var floor_body := StaticBody3D.new()
	floor_body.name = "ArenaFloor"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(18.0, 0.1, 18.0)
	col.shape = shape
	col.position.y = -0.05
	floor_body.add_child(col)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(18.0, 0.1, 18.0)
	mesh.mesh = box
	mesh.material_override = _mat(Color(0.06, 0.07, 0.09))
	mesh.position.y = -0.05
	floor_body.add_child(mesh)
	add_child(floor_body)

	# Center marker
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.12
	sphere_mesh.height = 0.24
	var marker := MeshInstance3D.new()
	marker.mesh = sphere_mesh
	marker.material_override = _mat(Color.WHITE, true)
	marker.position.y = 0.12
	add_child(marker)

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
#  STATION 1: THE CRANE â€” Magnitude â†’ HingeJoint3D
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _build_station_crane() -> void:
	var sd := _init_station("Crane", 0)
	var h: Node3D = sd.helper  # GadgetBase instance

	# Pillar (static)
	var pillar = h.create_static_body(Vector3(0, 1.5, 0), h.make_box_mesh(Vector3(0.6, 3.0, 0.6)), COLOR_DARK, "Pillar")

	# Boom arm (rigid)
	var arm = h.create_rigid_body(Vector3(1.25, 3.0, 0), h.make_box_mesh(Vector3(2.5, 0.25, 0.25)), COLOR_A, 3.0, "BoomArm")
	arm.angular_damp = 3.0

	# Counterweight
	var cw := MeshInstance3D.new()
	cw.mesh = h.make_sphere_mesh(0.18)
	cw.material_override = h.get_material(COLOR_METAL)
	cw.position = Vector3(-1.1, 0, 0)
	arm.add_child(cw)

	# Hook indicator at arm tip
	var hook := MeshInstance3D.new()
	hook.mesh = h.make_sphere_mesh(0.12)
	hook.material_override = h.get_emissive_material(COLOR_RESULT, 1.5)
	hook.position = Vector3(1.1, -0.2, 0)
	arm.add_child(hook)

	# Hinge
	var hinge = h.create_hinge_joint(pillar, arm, Vector3(0, 3.0, 0), Vector3(0, 0, 90), true, 120.0, "CraneHinge")
	hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-10))
	hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(80))

	sd.joints = [hinge]
	sd.bodies = [arm]

	# One draggable vector
	var vec := _spawn_vector(sd.root, Vector3(-2.0, 1.2, 1.5), Vector3(-2.0, 2.5, 1.5), COLOR_A, "Magnitude")
	sd.vectors = [vec]
	sd.caches = [_cache_nodes(vec)]

	# Info panel
	sd.info_label = _build_info_panel(sd.root, "THE CRANE", "|v| = sqrt(xÂ² + yÂ² + zÂ²)", "Magnitude controls arm angle", Vector3(0, 4.8, -1.0))

func _update_crane(do_text: bool) -> void:
	var sd: Dictionary = _stations[0]
	var v := _get_vec(sd.vectors[0], sd.caches[0])
	var mag := v.length()
	var target_deg := clampf(mag * 25.0, -10.0, 80.0)
	var target_rad := deg_to_rad(target_deg)
	var arm: RigidBody3D = sd.bodies[0]
	var current := arm.rotation.z
	var vel := (target_rad - current) * 3.0
	var hinge: HingeJoint3D = sd.joints[0]
	hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, vel)
	if do_text and sd.info_label:
		sd.info_label.text = "v = (%.1f, %.1f, %.1f)\n|v| = %.2f\nArm angle = %.1fÂ°" % [v.x, v.y, v.z, mag, target_deg]

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
#  STATION 2: THE PISTONS â€” Addition â†’ SliderJoint3D Ã—2
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _build_station_pistons() -> void:
	var sd := _init_station("Pistons", 1)
	var h: Node3D = sd.helper

	# L-shaped static frame
	var frame_v = h.create_static_body(Vector3(0, 1.25, 0), h.make_box_mesh(Vector3(0.2, 2.5, 0.2)), COLOR_FRAME, "FrameV")
	var frame_h = h.create_static_body(Vector3(1.25, 0, 0), h.make_box_mesh(Vector3(2.5, 0.2, 0.2)), COLOR_FRAME, "FrameH")

	# Piston A â€“ horizontal (X-axis)
	var piston_a = h.create_rigid_body(Vector3(0.5, 0, 0), h.make_box_mesh(Vector3(0.4, 0.3, 0.3)), COLOR_A, 1.5, "PistonA")
	piston_a.linear_damp = 3.0
	var slider_a = h.create_slider_joint(frame_h, piston_a, Vector3(0.5, 0, 0), 0.0, 2.0, "SliderA")

	# Piston B â€“ vertical (Y-axis)
	var piston_b = h.create_rigid_body(Vector3(0, 0.5, 0), h.make_box_mesh(Vector3(0.3, 0.4, 0.3)), COLOR_B, 1.5, "PistonB")
	piston_b.linear_damp = 3.0
	piston_b.gravity_scale = 0.0  # Prevent gravity pulling it down
	var slider_b = h.create_slider_joint(frame_v, piston_b, Vector3(0, 0.5, 0), 0.0, 2.0, "SliderB")
	slider_b.rotation_degrees = Vector3(0, 0, 90)  # Align to Y-axis

	# Result marker
	var marker_mesh = h.make_sphere_mesh(0.15)
	var marker := MeshInstance3D.new()
	marker.name = "ResultMarker"
	marker.mesh = marker_mesh
	marker.material_override = h.get_emissive_material(COLOR_RESULT, 2.0)
	sd.root.add_child(marker)

	sd.joints = [slider_a, slider_b]
	sd.bodies = [piston_a, piston_b, marker]

	# Two draggable vectors
	var vec_a := _spawn_vector(sd.root, Vector3(-2.0, 1.0, 1.5), Vector3(-0.5, 1.0, 1.5), COLOR_A, "Vector A")
	var vec_b := _spawn_vector(sd.root, Vector3(-2.0, 1.5, 1.5), Vector3(-2.0, 3.0, 1.5), COLOR_B, "Vector B")
	sd.vectors = [vec_a, vec_b]
	sd.caches = [_cache_nodes(vec_a), _cache_nodes(vec_b)]

	sd.info_label = _build_info_panel(sd.root, "THE PISTONS", "C = A + B", "Addition: each magnitude drives a piston", Vector3(0, 4.2, -1.0))

func _update_pistons(do_text: bool) -> void:
	var sd: Dictionary = _stations[1]
	var a := _get_vec(sd.vectors[0], sd.caches[0])
	var b := _get_vec(sd.vectors[1], sd.caches[1])
	var mag_a := a.length()
	var mag_b := b.length()
	var target_a := clampf(mag_a * 0.5, 0.0, 2.0)
	var target_b := clampf(mag_b * 0.5, 0.0, 2.0)

	var piston_a: RigidBody3D = sd.bodies[0]
	var piston_b: RigidBody3D = sd.bodies[1]
	var force_a := (target_a - piston_a.position.x + 0.5) * 12.0  # offset for initial pos
	var force_b := (target_b - piston_b.position.y + 0.5) * 12.0
	piston_a.apply_central_force(Vector3(force_a, 0, 0))
	piston_b.apply_central_force(Vector3(0, force_b, 0))

	# Update result marker
	var marker: MeshInstance3D = sd.bodies[2]
	marker.position = Vector3(piston_a.position.x, piston_b.position.y, 0)

	if do_text and sd.info_label:
		var r := a + b
		sd.info_label.text = "A = (%.1f, %.1f, %.1f)  |A| = %.2f\nB = (%.1f, %.1f, %.1f)  |B| = %.2f\nA+B = (%.1f, %.1f, %.1f)" % [a.x, a.y, a.z, mag_a, b.x, b.y, b.z, mag_b, r.x, r.y, r.z]

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
#  STATION 3: THE DOOR â€” Dot Product â†’ HingeJoint3D Ã—2
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _build_station_door() -> void:
	var sd := _init_station("Door", 2)
	var h: Node3D = sd.helper

	# Central hinge post (static)
	var post = h.create_static_body(Vector3(0, 1.25, 0), h.make_cylinder_mesh(0.12, 2.5), COLOR_METAL, "HingePost")

	# Door panel A (left)
	var door_a = h.create_rigid_body(Vector3(-0.65, 1.25, 0), h.make_box_mesh(Vector3(1.2, 2.0, 0.08)), COLOR_A, 2.0, "DoorA")
	door_a.angular_damp = 3.0

	# Door panel B (right)
	var door_b = h.create_rigid_body(Vector3(0.65, 1.25, 0), h.make_box_mesh(Vector3(1.2, 2.0, 0.08)), COLOR_B, 2.0, "DoorB")
	door_b.angular_damp = 3.0

	# Hinges
	var hinge_a = h.create_hinge_joint(post, door_a, Vector3(0, 1.25, 0), Vector3.ZERO, true, 80.0, "HingeA")
	hinge_a.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	hinge_a.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-170))
	hinge_a.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, 0.0)

	var hinge_b = h.create_hinge_joint(post, door_b, Vector3(0, 1.25, 0), Vector3.ZERO, true, 80.0, "HingeB")
	hinge_b.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	hinge_b.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, 0.0)
	hinge_b.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(170))

	sd.joints = [hinge_a, hinge_b]
	sd.bodies = [door_a, door_b]

	var vec_a := _spawn_vector(sd.root, Vector3(-2.0, 1.2, 2.0), Vector3(-1.0, 2.0, 2.0), COLOR_A, "Vector A")
	var vec_b := _spawn_vector(sd.root, Vector3(-2.0, 1.8, 2.0), Vector3(-1.2, 2.8, 2.0), COLOR_B, "Vector B")
	sd.vectors = [vec_a, vec_b]
	sd.caches = [_cache_nodes(vec_a), _cache_nodes(vec_b)]

	sd.info_label = _build_info_panel(sd.root, "THE DOOR", "A Â· B = |A||B| cos Î¸", "Dot product angle opens the doors", Vector3(0, 4.2, -1.0))

func _update_door(do_text: bool) -> void:
	var sd: Dictionary = _stations[2]
	var a := _get_vec(sd.vectors[0], sd.caches[0])
	var b := _get_vec(sd.vectors[1], sd.caches[1])
	var mag_a := a.length()
	var mag_b := b.length()
	var dot := a.dot(b)
	var theta := 0.0
	if mag_a > 0.001 and mag_b > 0.001:
		theta = acos(clampf(dot / (mag_a * mag_b), -1.0, 1.0))

	# Each door opens to half the angle
	var half := theta * 0.5
	var door_a: RigidBody3D = sd.bodies[0]
	var door_b: RigidBody3D = sd.bodies[1]
	var vel_a := (-half - door_a.rotation.y) * 3.0
	var vel_b := (half - door_b.rotation.y) * 3.0
	var hinge_a: HingeJoint3D = sd.joints[0]
	var hinge_b: HingeJoint3D = sd.joints[1]
	hinge_a.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, vel_a)
	hinge_b.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, vel_b)

	if do_text and sd.info_label:
		sd.info_label.text = "A Â· B = %.2f\n|A| = %.2f  |B| = %.2f\nÎ¸ = %.1fÂ°\nDoor angle = %.1fÂ°" % [dot, mag_a, mag_b, rad_to_deg(theta), rad_to_deg(theta)]

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
#  STATION 4: THE SEESAW â€” Subtraction â†’ HingeJoint3D + gravity
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _build_station_seesaw() -> void:
	var sd := _init_station("Seesaw", 3)
	var h: Node3D = sd.helper

	# Fulcrum base plate + triangle
	h.create_static_body(Vector3(0, 0.05, 0), h.make_box_mesh(Vector3(1.0, 0.1, 0.6)), COLOR_FRAME, "BasePlate")
	var fulcrum = h.create_static_body(Vector3(0, 0.5, 0), h.make_cylinder_mesh(0.15, 0.8), COLOR_METAL, "Fulcrum")

	# Beam (rigid)
	var beam = h.create_rigid_body(Vector3(0, 0.95, 0), h.make_box_mesh(Vector3(3.0, 0.12, 0.35)), COLOR_METAL, 2.0, "Beam")
	beam.angular_damp = 1.5

	# Hinge (Z-axis tilt)
	var hinge = h.create_hinge_joint(fulcrum, beam, Vector3(0, 0.95, 0), Vector3(0, 0, 90), false, 0.0, "BeamHinge")
	hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-35))
	hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(35))

	# Weight A (left end)
	var weight_a = h.create_rigid_body(Vector3(-1.4, 0.6, 0), h.make_box_mesh(Vector3(0.3, 0.3, 0.3)), COLOR_A, 2.0, "WeightA")
	var pin_a := PinJoint3D.new()
	pin_a.name = "PinA"
	pin_a.position = Vector3(-1.4, 0.95, 0)
	pin_a.node_a = beam.get_path()
	pin_a.node_b = weight_a.get_path()
	pin_a.set_exclude_nodes_from_collision(true)
	h.add_child(pin_a)

	# Weight B (right end)
	var weight_b = h.create_rigid_body(Vector3(1.4, 0.6, 0), h.make_box_mesh(Vector3(0.3, 0.3, 0.3)), COLOR_B, 2.0, "WeightB")
	var pin_b := PinJoint3D.new()
	pin_b.name = "PinB"
	pin_b.position = Vector3(1.4, 0.95, 0)
	pin_b.node_a = beam.get_path()
	pin_b.node_b = weight_b.get_path()
	pin_b.set_exclude_nodes_from_collision(true)
	h.add_child(pin_b)

	sd.joints = [hinge, pin_a, pin_b]
	sd.bodies = [beam, weight_a, weight_b]

	var vec_a := _spawn_vector(sd.root, Vector3(-2.0, 1.0, 1.5), Vector3(-0.8, 1.8, 1.5), COLOR_A, "Vector A")
	var vec_b := _spawn_vector(sd.root, Vector3(2.0, 1.0, 1.5), Vector3(0.8, 2.2, 1.5), COLOR_B, "Vector B")
	sd.vectors = [vec_a, vec_b]
	sd.caches = [_cache_nodes(vec_a), _cache_nodes(vec_b)]

	sd.info_label = _build_info_panel(sd.root, "THE SEESAW", "C = A âˆ’ B = A + (âˆ’B)", "Magnitudes as weights â€” gravity shows the difference", Vector3(0, 3.5, -1.0))

func _update_seesaw(do_text: bool) -> void:
	var sd: Dictionary = _stations[3]
	var a := _get_vec(sd.vectors[0], sd.caches[0])
	var b := _get_vec(sd.vectors[1], sd.caches[1])
	var mass_a := clampf(a.length(), 0.2, 10.0)
	var mass_b := clampf(b.length(), 0.2, 10.0)

	var weight_a: RigidBody3D = sd.bodies[1]
	var weight_b: RigidBody3D = sd.bodies[2]
	weight_a.mass = lerpf(weight_a.mass, mass_a, 0.1)
	weight_b.mass = lerpf(weight_b.mass, mass_b, 0.1)

	# Visual scale reflects mass
	var scale_a := weight_a.mass * 0.3 + 0.3
	var scale_b := weight_b.mass * 0.3 + 0.3
	weight_a.get_child(0).scale = Vector3(scale_a, scale_a, scale_a)
	weight_b.get_child(0).scale = Vector3(scale_b, scale_b, scale_b)

	if do_text and sd.info_label:
		var diff := a - b
		sd.info_label.text = "|A| = %.2f (weight left)\n|B| = %.2f (weight right)\nAâˆ’B = (%.1f, %.1f, %.1f)\n|Aâˆ’B| = %.2f" % [a.length(), b.length(), diff.x, diff.y, diff.z, diff.length()]

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
#  STATION 5: THE WATERWHEEL â€” Cross Product â†’ HingeJoint3D
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _build_station_waterwheel() -> void:
	var sd := _init_station("Waterwheel", 4)
	var h: Node3D = sd.helper

	# Axle supports (two posts)
	h.create_static_body(Vector3(0, 0.75, -0.35), h.make_box_mesh(Vector3(0.15, 1.5, 0.15)), COLOR_DARK, "PostL")
	h.create_static_body(Vector3(0, 0.75, 0.35), h.make_box_mesh(Vector3(0.15, 1.5, 0.15)), COLOR_DARK, "PostR")

	# Wheel hub (rigid)
	var wheel = h.create_rigid_body(Vector3(0, 1.5, 0), h.make_cylinder_mesh(0.12, 0.5), COLOR_METAL, 3.0, "Wheel")
	wheel.rotation_degrees.x = 90  # Lay axle along Z
	wheel.angular_damp = 0.5

	# 6 blades
	for i in range(6):
		var angle := float(i) * TAU / 6.0
		var blade := MeshInstance3D.new()
		var blade_mesh := BoxMesh.new()
		blade_mesh.size = Vector3(0.5, 0.03, 0.2)
		blade.mesh = blade_mesh
		blade.material_override = h.get_material(Color(0.3, 0.5, 1.0))
		blade.position = Vector3(cos(angle) * 0.55, sin(angle) * 0.55, 0)
		blade.rotation.z = angle
		wheel.add_child(blade)

	# Hub ring (visual)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.7
	torus.outer_radius = 0.8
	torus.ring_segments = 32
	torus.rings = 12
	ring.mesh = torus
	ring.material_override = h.get_material(COLOR_METAL)
	wheel.add_child(ring)

	# Hinge (Z-axis, horizontal spin)
	var anchor_body = h.create_static_body(Vector3(0, 1.5, 0), h.make_sphere_mesh(0.05), COLOR_DARK, "WheelAnchor")
	var hinge = h.create_hinge_joint(anchor_body, wheel, Vector3(0, 1.5, 0), Vector3(90, 0, 0), true, 80.0, "WheelHinge")

	sd.joints = [hinge]
	sd.bodies = [wheel]

	var vec_a := _spawn_vector(sd.root, Vector3(-2.0, 1.0, 1.5), Vector3(-1.0, 1.8, 1.5), COLOR_A, "Vector A")
	var vec_b := _spawn_vector(sd.root, Vector3(-2.0, 2.0, 1.5), Vector3(-1.5, 3.0, 2.0), COLOR_B, "Vector B")
	sd.vectors = [vec_a, vec_b]
	sd.caches = [_cache_nodes(vec_a), _cache_nodes(vec_b)]

	sd.info_label = _build_info_panel(sd.root, "THE WATERWHEEL", "A Ã— B = |A||B| sin Î¸  nÌ‚", "Cross product magnitude spins the wheel", Vector3(0, 3.8, -1.0))

func _update_waterwheel(do_text: bool) -> void:
	var sd: Dictionary = _stations[4]
	var a := _get_vec(sd.vectors[0], sd.caches[0])
	var b := _get_vec(sd.vectors[1], sd.caches[1])
	var cross := a.cross(b)
	var cross_mag := cross.length()
	var speed := cross_mag * 2.0
	if cross_mag > 0.001:
		var dir := signf(cross.y + cross.z * 0.5)
		if dir == 0.0:
			dir = 1.0
		speed *= dir
	var hinge: HingeJoint3D = sd.joints[0]
	hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, speed)

	if do_text and sd.info_label:
		sd.info_label.text = "A Ã— B = (%.1f, %.1f, %.1f)\n|A Ã— B| = %.2f\nWheel speed = %.1f rad/s" % [cross.x, cross.y, cross.z, cross_mag, speed]

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
#  STATION 6: THE SPRING TOWER â€” Forces â†’ Generic6DOFJoint3D
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _build_station_spring() -> void:
	var sd := _init_station("Spring", 5)
	var h: Node3D = sd.helper

	# Base plate (static)
	var base = h.create_static_body(Vector3(0, 0.075, 0), h.make_box_mesh(Vector3(1.0, 0.15, 1.0)), COLOR_FRAME, "Base")

	# Guide columns
	for offset in [Vector3(-0.4, 1.75, -0.4), Vector3(0.4, 1.75, -0.4), Vector3(-0.4, 1.75, 0.4), Vector3(0.4, 1.75, 0.4)]:
		var col := MeshInstance3D.new()
		col.mesh = h.make_cylinder_mesh(0.04, 3.5)
		col.material_override = h.get_material(COLOR_METAL)
		col.position = offset
		sd.root.add_child(col)

	# Platform (rigid)
	var platform = h.create_rigid_body(Vector3(0, 0.6, 0), h.make_box_mesh(Vector3(0.8, 0.12, 0.8)), COLOR_RESULT, 2.0, "Platform")
	platform.linear_damp = 2.0
	platform.gravity_scale = 1.0

	# Spring joint
	var spring = h.create_spring_joint(base, platform, Vector3(0, 0.4, 0), "y", 25.0, 4.0, 0.0, 3.0, "TowerSpring")

	# Visual coil springs (8 toruses along guides)
	var coils: Array[MeshInstance3D] = []
	for i in range(8):
		var coil := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = 0.02
		t.outer_radius = 0.12
		t.ring_segments = 16
		t.rings = 8
		coil.mesh = t
		coil.material_override = h.get_emissive_material(Color(0.4, 0.7, 1.0), 1.0)
		coil.rotation_degrees.x = 90
		sd.root.add_child(coil)
		coils.append(coil)

	# Indicator sphere on platform
	var ind := MeshInstance3D.new()
	ind.mesh = h.make_sphere_mesh(0.1)
	ind.material_override = h.get_emissive_material(COLOR_RESULT, 2.0)
	ind.position.y = 0.15
	platform.add_child(ind)

	sd.joints = [spring]
	sd.bodies = [platform]
	sd["coils"] = coils

	# Two force vectors
	var vec_a := _spawn_vector(sd.root, Vector3(-2.0, 1.0, 1.5), Vector3(-2.0, 2.5, 1.5), COLOR_A, "Thrust")
	var vec_b := _spawn_vector(sd.root, Vector3(-2.0, 2.8, 1.5), Vector3(-2.0, 1.8, 1.5), COLOR_B, "Gravity")
	sd.vectors = [vec_a, vec_b]
	sd.caches = [_cache_nodes(vec_a), _cache_nodes(vec_b)]

	sd.info_label = _build_info_panel(sd.root, "THE SPRING TOWER", "F_net = Î£F_i", "Net force compresses or extends the spring", Vector3(0, 4.8, -1.0))

func _update_spring(do_text: bool) -> void:
	var sd: Dictionary = _stations[5]
	var a := _get_vec(sd.vectors[0], sd.caches[0])
	var b := _get_vec(sd.vectors[1], sd.caches[1])
	var net := a + b
	var force_up := net.length() * 12.0
	# Use Y component sign to determine direction
	if net.y < 0:
		force_up = -force_up * 0.5
	var platform: RigidBody3D = sd.bodies[0]
	platform.apply_central_force(Vector3(0, force_up, 0))

	# Redistribute coil springs between base and platform
	var coils: Array = sd.get("coils", [])
	var plat_y: float = platform.global_position.y - sd.root.global_position.y
	var base_y := 0.15
	var span := maxf(plat_y - base_y, 0.1)
	for i in range(coils.size()):
		var t := (float(i) + 0.5) / float(coils.size())
		var cy := base_y + t * span
		coils[i].position = Vector3(0, cy, 0)

	if do_text and sd.info_label:
		sd.info_label.text = "Thrust = (%.1f, %.1f, %.1f)\nGravity = (%.1f, %.1f, %.1f)\nF_net = (%.1f, %.1f, %.1f)\n|F_net| = %.2f" % [a.x, a.y, a.z, b.x, b.y, b.z, net.x, net.y, net.z, net.length()]

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
#  SHARED HELPERS
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _init_station(station_name: String, index: int) -> Dictionary:
	var pos := _station_position(index)
	var facing := _station_facing(index)

	var root := Node3D.new()
	root.name = "Station_%s" % station_name
	root.position = pos
	root.rotation_degrees.y = facing
	add_child(root)

	var helper := GadgetBaseScript.new()
	helper.name = "Helper"
	root.add_child(helper)

	var sd := {
		"root": root,
		"helper": helper,
		"vectors": [],
		"caches": [],
		"joints": [],
		"bodies": [],
		"info_label": null,
	}
	_stations.append(sd)
	return sd

func _station_position(index: int) -> Vector3:
	# Semicircle: left to right when facing -Z
	var t := float(index) / float(STATION_COUNT - 1) if STATION_COUNT > 1 else 0.0
	var angle_deg := 180.0 - t * STATION_ARC_DEG
	var angle_rad := deg_to_rad(angle_deg)
	return Vector3(cos(angle_rad) * STATION_RADIUS, 0.0, sin(angle_rad) * STATION_RADIUS)

func _station_facing(index: int) -> float:
	var pos := _station_position(index)
	return rad_to_deg(atan2(-pos.x, -pos.z))

# â”€â”€â”€ Vector helpers (no SCENE_SCALE) â”€â”€â”€

func _spawn_vector(parent: Node3D, origin: Vector3, endpoint: Vector3, color: Color, label: String) -> Node3D:
	var arrow: Node3D = VECTOR_SCENE.instantiate()
	arrow.name = label.replace(" ", "_")
	arrow.position = origin
	var line_node = arrow.get_node_or_null("lineContainer")
	if line_node:
		line_node.set("vector_name", label)
		line_node.set("line_color", color)
	var start_node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere")
	var end_node: Node3D = arrow.get_node_or_null("lineContainer/GrabSphere2")
	if start_node:
		start_node.position = Vector3.ZERO
	if end_node:
		end_node.position = endpoint - origin
	parent.add_child(arrow)
	return arrow

func _cache_nodes(arrow: Node3D) -> Dictionary:
	return {
		"start": arrow.get_node_or_null("lineContainer/GrabSphere"),
		"end": arrow.get_node_or_null("lineContainer/GrabSphere2"),
		"line_container": arrow.get_node_or_null("lineContainer"),
	}

func _get_vec(_arrow: Node3D, cache: Dictionary) -> Vector3:
	var s: Node3D = cache.get("start")
	var e: Node3D = cache.get("end")
	if s and e:
		return e.global_position - s.global_position
	return Vector3.ZERO

# â”€â”€â”€ Info panel builder â”€â”€â”€

func _build_info_panel(parent: Node3D, title: String, formula: String, desc: String, pos: Vector3) -> Label3D:
	var panel := Node3D.new()
	panel.name = "InfoPanel"
	panel.position = pos
	parent.add_child(panel)

	var panel_w := 2.0
	var panel_h := 1.0
	var title_h := 0.18

	# Title backing
	var title_panel := Node3D.new()
	title_panel.position.y = panel_h / 2.0 + title_h / 2.0 + 0.04
	panel.add_child(title_panel)

	var tb := MeshInstance3D.new()
	var tb_mesh := BoxMesh.new()
	tb_mesh.size = Vector3(panel_w, title_h, 0.02)
	tb.mesh = tb_mesh
	tb.material_override = _mat(Color(0.06, 0.07, 0.1, 0.95), false, true)
	title_panel.add_child(tb)

	var tl := Label3D.new()
	tl.text = title
	tl.pixel_size = 0.002
	tl.font_size = 32
	tl.modulate = Color.WHITE
	tl.no_depth_test = true
	tl.render_priority = 100
	tl.outline_size = 4
	tl.outline_modulate = Color(0, 0, 0, 0.8)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tl.position.z = 0.02
	title_panel.add_child(tl)

	# Main backing
	var backing := MeshInstance3D.new()
	var b_mesh := BoxMesh.new()
	b_mesh.size = Vector3(panel_w, panel_h, 0.02)
	backing.mesh = b_mesh
	backing.material_override = _mat(Color(0.04, 0.05, 0.07, 0.95), false, true)
	panel.add_child(backing)

	# Formula label
	var fl := Label3D.new()
	fl.text = formula
	fl.pixel_size = 0.002
	fl.font_size = 26
	fl.modulate = Color(0.85, 0.95, 1.0)
	fl.no_depth_test = true
	fl.render_priority = 100
	fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fl.position = Vector3(0, panel_h / 2.0 - 0.12, 0.02)
	panel.add_child(fl)

	# Accent line
	var accent := MeshInstance3D.new()
	var al_mesh := BoxMesh.new()
	al_mesh.size = Vector3(panel_w * 0.6, 0.004, 0.008)
	accent.mesh = al_mesh
	var accent_mat := StandardMaterial3D.new()
	accent_mat.albedo_color = Color(0.4, 0.7, 1.0)
	accent_mat.emission_enabled = true
	accent_mat.emission = Color(0.3, 0.5, 0.8)
	accent_mat.emission_energy_multiplier = 1.5
	accent.material_override = accent_mat
	accent.position = Vector3(0, panel_h / 2.0 - 0.22, 0.005)
	panel.add_child(accent)

	# Description label
	var dl := Label3D.new()
	dl.text = desc
	dl.pixel_size = 0.002
	dl.font_size = 18
	dl.modulate = Color(0.55, 0.6, 0.65)
	dl.no_depth_test = true
	dl.render_priority = 100
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dl.position = Vector3(0, panel_h / 2.0 - 0.32, 0.02)
	panel.add_child(dl)

	# Live data label (returned for updating)
	var live := Label3D.new()
	live.name = "LiveData"
	live.text = ""
	live.pixel_size = 0.002
	live.font_size = 20
	live.modulate = Color.WHITE
	live.no_depth_test = true
	live.render_priority = 100
	live.outline_size = 3
	live.outline_modulate = Color(0, 0, 0, 0.8)
	live.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	live.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	live.position = Vector3(-panel_w / 2.0 + 0.08, panel_h / 2.0 - 0.42, 0.02)
	panel.add_child(live)

	return live

# â”€â”€â”€ Material helper â”€â”€â”€

func _mat(color: Color, unlit: bool = false, transparent: bool = false) -> StandardMaterial3D:
	var key := str(color) + ("_u" if unlit else "_l") + ("_t" if transparent else "")
	if _mat_cache.has(key):
		return _mat_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if unlit:
		mat.emission_enabled = true
		mat.emission = color * 0.8
		mat.roughness = 0.2
	else:
		mat.roughness = 0.6
		mat.metallic = 0.3
	if transparent or color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.render_priority = -10
	_mat_cache[key] = mat
	return mat

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

