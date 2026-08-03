# ===========================================================================
# NOC Example 6.6: Grab
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 6.6: VR Grabbable Objects
## Demonstrates VR hand grabbing with Generic6DOFJoint3D
## Chapter 06: Physics Libraries

var grabbable_objects: Array[VRRigidBody] = []
var ground: StaticBody3D

# VR controller simulation (placeholder for actual VR input)
var simulated_controller: Node3D
var controller_grabbed_object: VRRigidBody = null

# UI
var info_label: Label3D
var instructions_label: Label3D

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `reveal`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHAT THE GRAB IS ALLOWED TO SHOW OF ITSELF.
#
# A grab in a physics library is three things a viewer never sees: a distance test
# that decides WHETHER, a constraint that decides WHAT HOLDS, and a set of degrees
# of freedom that decides WHAT IS STILL ALLOWED. This demo ships with none of them
# drawn. It shows a green sphere on a circular path and five pink bodies, and the
# whole subject — `if distance < 0.15`, `Generic6DOFJoint3D`, three linear limits
# enabled and three rotations left alone — lives in the source where no headset can
# reach it. `reveal` is the axis that puts one of the three on the geometry.
#
#   hand    the shipped build, byte for byte: the orbiting green marker, five loose
#           bodies, the two billboard labels. The grab is a thing that might happen,
#           entirely off-screen. The legacy lineage.
#   reach   the THRESHOLD. attempt_grab()'s 0.15 m becomes a wire bubble around the
#           marker, and a live line runs to every body — lit if it is inside the test,
#           dim if it is not — with the nearest distance read out. Nothing is staged:
#           this is the real comparison the real loop makes, every frame, and it is
#           worth watching, because the orbit carries the hand well above the pile the
#           bodies settle into and the honest answer is usually `no`.
#   joint   the CONSTRAINT. The demo grabs through its own shipped path at build time
#           and the Generic6DOFJoint3D that results is drawn: node_a, which is not the
#           hand but an anchor node created beside it, node_b, which is the body, and
#           the live link between them. A grab is not a hand closing. It is two bodies
#           and a relation, and the relation is the part with the physics in it.
#   dof     what the constraint LEAVES. Three barred axes through the held body for
#           the three linear limits grab_start() enables, three open rings for the
#           three rotations it never touches. The name says six degrees of freedom;
#           the code takes three of them and the picture says which.
#
# `hand` builds nothing and stages nothing. The other three add geometry and, for
# joint/dof, one grab through the unmodified attempt_grab() — the physics, the range
# test and the joint setup are the shipped code in every case.
@export_enum("hand", "reach", "joint", "dof") var reveal: String = "hand"

## Allow-list. An unknown word in a map token falls back to the shipped scene rather than
## stranding a placement with a blank exhibit.
const REVEALS: PackedStringArray = ["hand", "reach", "joint", "dof"]

## CAPTURE FIXTURE, not an axis. The marker's path has always been driven straight off the
## wall clock (Time.get_ticks_msec), so where the hand is depends on how long the process took
## to boot — which makes every still of this artifact a different still. -1 keeps that shipped
## behaviour exactly. Any value >= 0 pins the orbit to that phase in seconds and holds it, so a
## sweep of `reveal` measures the axis instead of measuring boot time.
@export var hand_phase: float = -1.0

## Geometry built by reach / joint / dof. Freed before any rebuild; empty on the shipped path,
## where not one of them is ever constructed.
var _reveal_parts: Array[Node3D] = []
var _rv_link: MeshInstance3D = null       # joint: the live node_a -> node_b line
var _rv_lines: MeshInstance3D = null      # reach: the live hand -> body lines
var _rv_readout: Label3D = null           # reach: the live nearest-distance text
## True only while joint/dof is holding a grab THIS exhibit took. A grab the player made by
## clicking is not ours and is never released behind their back.
var _rv_staged: bool = false

func _ready() -> void:
	_read_grid_config_meta()

	# Create UI
	create_info_labels()

	# Create ground
	create_ground()

	# Create grabbable objects
	create_grabbable_objects()

	# Create simulated controller
	create_simulated_controller()

	_apply_reveal()

	print("Example 6.6: VR Grabbable Objects - Click objects to grab/release")

func _process(_delta):
	# Simulate VR controller movement with mouse (placeholder)
	# In actual VR, this would track actual controller position
	update_simulated_controller()
	_rv_update()

func _input(event: InputEvent) -> void:
	# Simulate grab/release with mouse click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if controller_grabbed_object:
			release_object()
		else:
			attempt_grab()

func create_info_labels() -> void:
	"""Create info labels"""
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(1.0, 0.9, 1.0)
	info_label.position = Vector3(0, 0.6, 0)
	info_label.text = "VR Grabbable Objects"
	add_child(info_label)

	instructions_label = Label3D.new()
	instructions_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions_label.font_size = 20
	instructions_label.modulate = Color(0.8, 1.0, 0.8)
	instructions_label.position = Vector3(0, 0.5, 0)
	instructions_label.text = "[Click] Grab/Release\n[Move Mouse] Move Hand"
	add_child(instructions_label)

func create_ground() -> void:
	"""Create static ground"""
	ground = StaticBody3D.new()
	ground.position = Vector3(0, -0.45, 0)

	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.9, 0.02, 0.9)
	mesh_instance.mesh = box_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.7, 0.7, 1.0)
	mesh_instance.material_override = material

	ground.add_child(mesh_instance)

	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.9, 0.02, 0.9)
	collision.shape = box_shape
	ground.add_child(collision)

	add_child(ground)

func create_grabbable_objects() -> void:
	"""Create various grabbable objects"""
	# Box
	create_box(Vector3(-0.2, 0, 0), Vector3(0.1, 0.1, 0.1))

	# Sphere
	create_sphere(Vector3(0, 0, 0), 0.06)

	# Cylinder
	create_cylinder(Vector3(0.2, 0, 0), 0.05, 0.15)

	# Small box
	create_box(Vector3(-0.1, 0.2, 0.1), Vector3(0.07, 0.07, 0.07))

	# Large sphere
	create_sphere(Vector3(0.1, 0.15, -0.1), 0.08)

func create_box(pos: Vector3, size: Vector3) -> void:
	"""Create grabbable box"""
	var box = VRRigidBody.new()
	box.position = pos
	box.use_pink_material = true

	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	box.mesh_instance = mesh_instance
	box.add_child(mesh_instance)

	box.create_box_shape(size)
	box.setup_pink_material()

	add_child(box)
	grabbable_objects.append(box)

func create_sphere(pos: Vector3, radius: float) -> void:
	"""Create grabbable sphere"""
	var sphere = VRRigidBody.new()
	sphere.position = pos
	sphere.use_pink_material = true

	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2
	mesh_instance.mesh = sphere_mesh
	sphere.mesh_instance = mesh_instance
	sphere.add_child(mesh_instance)

	sphere.create_sphere_shape(radius)
	sphere.setup_pink_material()

	add_child(sphere)
	grabbable_objects.append(sphere)

func create_cylinder(pos: Vector3, radius: float, height: float) -> void:
	"""Create grabbable cylinder"""
	var cylinder = VRRigidBody.new()
	cylinder.position = pos
	cylinder.use_pink_material = true

	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = radius
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.height = height
	mesh_instance.mesh = cylinder_mesh
	cylinder.mesh_instance = mesh_instance
	cylinder.add_child(mesh_instance)

	cylinder.create_cylinder_shape(radius, height)
	cylinder.setup_pink_material()

	add_child(cylinder)
	grabbable_objects.append(cylinder)

func create_simulated_controller() -> void:
	"""Create visual controller representation"""
	simulated_controller = Node3D.new()

	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.03
	sphere_mesh.height = 0.06
	mesh_instance.mesh = sphere_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 1.0, 0.3, 0.8)
	material.emission_enabled = true
	material.emission = Color(0.3, 1.0, 0.3, 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material

	simulated_controller.add_child(mesh_instance)
	simulated_controller.position = Vector3(0, 0, 0.3)

	add_child(simulated_controller)

func update_simulated_controller() -> void:
	"""Update controller position based on mouse (placeholder for VR)"""
	if not simulated_controller:
		return

	# Simple circular motion for demo
	var time: float = Time.get_ticks_msec() / 1000.0
	if hand_phase >= 0.0:
		# Capture fixture: the orbit stands still at a chosen phase so a still is a still.
		time = hand_phase
	var radius = 0.2
	simulated_controller.position.x = cos(time) * radius
	simulated_controller.position.z = sin(time) * radius
	simulated_controller.position.y = 0.1 + sin(time * 2) * 0.1

	# Update grabbed object position
	if controller_grabbed_object:
		controller_grabbed_object.grab_update(simulated_controller)

func attempt_grab() -> void:
	"""Attempt to grab nearest object"""
	if not simulated_controller:
		return

	var nearest_object: VRRigidBody = null
	var nearest_distance: float = INF

	# Find nearest object within grab range
	for obj in grabbable_objects:
		var distance = simulated_controller.global_position.distance_to(obj.global_position)
		if distance < 0.15 and distance < nearest_distance:  # 15cm grab range
			nearest_object = obj
			nearest_distance = distance

	if nearest_object:
		controller_grabbed_object = nearest_object
		nearest_object.grab_start(simulated_controller)
		print("Grabbed: %s" % nearest_object.name)
		update_info_label()

func release_object() -> void:
	"""Release currently grabbed object"""
	if controller_grabbed_object:
		# Calculate throw velocity (simple version)
		var throw_velocity = controller_grabbed_object.linear_velocity

		controller_grabbed_object.grab_release(throw_velocity)
		print("Released: %s" % controller_grabbed_object.name)
		controller_grabbed_object = null
		update_info_label()

func update_info_label() -> void:
	"""Update info label"""
	if info_label:
		if controller_grabbed_object:
			info_label.text = "VR Grabbable Objects\nHolding: %s" % controller_grabbed_object.name
		else:
			info_label.text = "VR Grabbable Objects\nObjects: %d" % grabbable_objects.size()

func reset() -> void:
	"""Reset all objects"""
	if controller_grabbed_object:
		release_object()

	for obj in grabbable_objects:
		obj.queue_free()
	grabbable_objects.clear()

	create_grabbable_objects()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Grid config arrives twice and by two different routes: GridInteractablesComponent sets
## config_<key> metadata on the instantiated root and then calls apply_grid_config(), and the
## capture harness calls apply_grid_config() before the scene enters the tree. Reading the
## metadata on the way in means the exhibit is built once, correctly, instead of built as
## `hand` and then torn down.
##
## Costs nothing when no token is present: the exports keep their defaults and not a single
## existing placement changes.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_reveal"):
			reveal = str(node.get_meta("config_reveal"))
		if node.has_meta("config_hand_phase"):
			hand_phase = float(str(node.get_meta("config_hand_phase")))
		node = node.get_parent()


## Config from map_data.json tokens: #reveal:reach  ·  #reveal:joint#hand_phase:0.9
##
## GUARDED ON CHANGE, deliberately. A placement carrying any other token arrives here with no
## `reveal` key at all, and the grid reaches this twice for one placement; an unguarded rebuild
## would tear down and re-raise the geometry — and, for joint/dof, drop and re-take the grab —
## on both of those, for nothing.
func apply_grid_config(config: Dictionary) -> void:
	var was_reveal: String = reveal

	if config.has("hand_phase"):
		hand_phase = float(str(config["hand_phase"]))
	if config.has("reveal"):
		reveal = str(config["reveal"])

	if reveal == was_reveal:
		return
	# Before _ready() the scene does not exist yet and _ready() will do this itself.
	if not is_instance_valid(simulated_controller):
		return

	_apply_reveal()


# ═══════════════════════════════════════════════════════════════════════════
# REVEAL
# ═══════════════════════════════════════════════════════════════════════════

const RV_RANGE := 0.15                       # the constant attempt_grab() actually tests
const RV_CHALK := Color(0.88, 0.90, 0.95)
const RV_LIVE := Color(0.35, 1.0, 0.45)      # inside the range test
const RV_DEAD := Color(0.42, 0.45, 0.50)     # outside it
const RV_INK := Color(0.98, 0.74, 0.26)
const RV_FREE := Color(0.35, 0.76, 1.0)


func _apply_reveal() -> void:
	var want: String = String(reveal).strip_edges().to_lower()
	if not REVEALS.has(want):
		want = "hand"                        # an unknown word keeps the shipped build
	reveal = want

	for part in _reveal_parts:
		if is_instance_valid(part):
			part.queue_free()
	_reveal_parts.clear()
	_rv_link = null
	_rv_lines = null
	_rv_readout = null

	# Hand the body back if the previous exhibit was the one holding it.
	if _rv_staged and want != "joint" and want != "dof":
		_rv_staged = false
		if controller_grabbed_object != null:
			release_object()

	if want == "hand":
		return                               # the legacy lineage: marker + bodies, nothing added

	var root := Node3D.new()
	root.name = "Reveal_%s" % want
	add_child(root)
	_reveal_parts.append(root)

	match want:
		"reach":
			_rv_reach(root)
		"joint":
			_rv_stage_grab()
			_rv_joint(root)
		"dof":
			_rv_stage_grab()
			_rv_dof(root)
		_:
			pass


## Take a grab through the SHIPPED path. The marker is parked on the sphere at the origin so
## that attempt_grab()'s own 0.15 m test succeeds on its own terms — the range check, the anchor
## node and the Generic6DOFJoint3D are all the demo's untouched code. Nothing here reaches into
## grab_start(); the exhibits then draw whatever it built.
func _rv_stage_grab() -> void:
	if controller_grabbed_object != null:
		return
	if not is_instance_valid(simulated_controller):
		return
	simulated_controller.position = Vector3(0.0, 0.13, 0.0)
	attempt_grab()
	_rv_staged = controller_grabbed_object != null


## REACH — the decision boundary. attempt_grab() compares a distance to 0.15 for every body,
## every click, and that comparison has never had a shape. Here it does: a bubble at the exact
## test radius, riding the marker, and a line to each body coloured by the answer.
func _rv_reach(root: Node3D) -> void:
	var bubble := Node3D.new()
	simulated_controller.add_child(bubble)
	_reveal_parts.append(bubble)
	var ring_mat: StandardMaterial3D = _rv_mat(RV_LIVE, 0.7)
	bubble.add_child(_rv_ring(RV_RANGE, 0.004, ring_mat, Vector3(90.0, 0.0, 0.0)))
	bubble.add_child(_rv_ring(RV_RANGE, 0.004, ring_mat, Vector3(0.0, 0.0, 0.0)))
	bubble.add_child(_rv_ring(RV_RANGE, 0.004, ring_mat, Vector3(0.0, 0.0, 90.0)))

	_rv_lines = MeshInstance3D.new()
	_rv_lines.mesh = ImmediateMesh.new()
	var line_mat := StandardMaterial3D.new()
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_mat.vertex_color_use_as_albedo = true
	_rv_lines.material_override = line_mat
	root.add_child(_rv_lines)

	root.add_child(_rv_text("grab range %.2f m" % RV_RANGE, Vector3(0.0, 0.42, 0.0), 16, RV_LIVE))
	_rv_readout = _rv_text("", Vector3(0.0, 0.36, 0.0), 14, RV_CHALK)
	root.add_child(_rv_readout)


## JOINT — the constraint, named. grab_start() does not attach the body to the hand: it spawns
## an anchor node beside the hand, makes that node_a, makes the body node_b, and puts a
## Generic6DOFJoint3D between them. Three markers and one live line, which is the whole of what
## a grab is in a physics library.
func _rv_joint(root: Node3D) -> void:
	_rv_link = MeshInstance3D.new()
	_rv_link.mesh = ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_rv_link.material_override = mat
	root.add_child(_rv_link)

	root.add_child(_rv_text("Generic6DOFJoint3D", Vector3(0.0, 0.42, 0.0), 16, RV_INK))

	if controller_grabbed_object == null:
		root.add_child(_rv_text("nothing in range", Vector3(0.0, 0.36, 0.0), 14, RV_DEAD))
		return

	# node_a: the anchor grab_start() created. It is NOT the controller, and that is the point.
	var anchor: Node3D = controller_grabbed_object.grab_anchor
	if is_instance_valid(anchor):
		var a_mark := Node3D.new()
		anchor.add_child(a_mark)
		_reveal_parts.append(a_mark)
		_rv_wire_box(a_mark, Vector3.ZERO, Vector3(0.05, 0.05, 0.05), 0.004, _rv_mat(RV_INK, 1.0))
		a_mark.add_child(_rv_billboard("node_a  anchor", Vector3(0.0, 0.06, 0.0), 13, RV_INK))

	# node_b: the body the physics engine actually solves against.
	var b_mark := Node3D.new()
	controller_grabbed_object.add_child(b_mark)
	_reveal_parts.append(b_mark)
	_rv_wire_box(b_mark, Vector3.ZERO, Vector3(0.14, 0.14, 0.14), 0.004, _rv_mat(RV_CHALK, 0.6))
	b_mark.add_child(_rv_billboard("node_b  rigid body", Vector3(0.0, -0.11, 0.0), 13, RV_CHALK))


## DOF — what the constraint leaves alone. grab_start() enables the linear limit on x, y and z
## and never touches the three angular ones, so the held body is pinned in translation and free
## in rotation. Barred axes for the three that are taken, open rings for the three that are not.
func _rv_dof(root: Node3D) -> void:
	root.add_child(_rv_text("6 degrees of freedom", Vector3(0.0, 0.42, 0.0), 16, RV_CHALK))

	if controller_grabbed_object == null:
		root.add_child(_rv_text("nothing in range", Vector3(0.0, 0.36, 0.0), 14, RV_DEAD))
		return

	var cage := Node3D.new()
	controller_grabbed_object.add_child(cage)
	_reveal_parts.append(cage)

	var arm: float = 0.13
	var locked: StandardMaterial3D = _rv_mat(RV_INK, 1.0)
	var axes: Array[Vector3] = [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
	for ax in axes:
		var span: Vector3 = ax * (arm * 2.0)
		var bar: Vector3 = Vector3(
			maxf(absf(span.x), 0.004),
			maxf(absf(span.y), 0.004),
			maxf(absf(span.z), 0.004))
		cage.add_child(_rv_box(Vector3.ZERO, bar, locked))
		# The stops: a limit is a pair of ends, so draw the ends.
		cage.add_child(_rv_box(ax * arm, Vector3(0.022, 0.022, 0.022), locked))
		cage.add_child(_rv_box(-ax * arm, Vector3(0.022, 0.022, 0.022), locked))

	var free_mat: StandardMaterial3D = _rv_mat(RV_FREE, 0.9)
	cage.add_child(_rv_ring(0.10, 0.004, free_mat, Vector3(90.0, 0.0, 0.0)))
	cage.add_child(_rv_ring(0.10, 0.004, free_mat, Vector3(0.0, 0.0, 0.0)))
	cage.add_child(_rv_ring(0.10, 0.004, free_mat, Vector3(0.0, 0.0, 90.0)))

	cage.add_child(_rv_billboard("linear x3  LIMITED", Vector3(0.0, arm + 0.04, 0.0), 13, RV_INK))
	cage.add_child(_rv_billboard("angular x3  FREE", Vector3(0.0, -arm - 0.04, 0.0), 13, RV_FREE))


## The live half of reach and joint. Costs nothing on the shipped path, where both handles are
## null and this returns on the first line.
func _rv_update() -> void:
	if _rv_lines != null and is_instance_valid(_rv_lines) and is_instance_valid(simulated_controller):
		var im: ImmediateMesh = _rv_lines.mesh as ImmediateMesh
		im.clear_surfaces()
		var hand: Vector3 = simulated_controller.position
		var nearest: float = INF
		im.surface_begin(Mesh.PRIMITIVE_LINES)
		for obj in grabbable_objects:
			if not is_instance_valid(obj):
				continue
			var to_obj: Vector3 = obj.position
			var d: float = hand.distance_to(to_obj)
			nearest = minf(nearest, d)
			var c: Color = RV_LIVE if d < RV_RANGE else RV_DEAD
			im.surface_set_color(c)
			im.surface_add_vertex(hand)
			im.surface_set_color(c)
			im.surface_add_vertex(to_obj)
		im.surface_end()
		if _rv_readout != null and is_instance_valid(_rv_readout):
			if nearest < INF:
				var verdict: String = "GRAB" if nearest < RV_RANGE else "no"
				_rv_readout.text = "nearest %.2f m  ->  %s" % [nearest, verdict]
			else:
				_rv_readout.text = "no bodies"

	if _rv_link != null and is_instance_valid(_rv_link):
		var lm: ImmediateMesh = _rv_link.mesh as ImmediateMesh
		lm.clear_surfaces()
		if controller_grabbed_object == null:
			return
		var anchor: Node3D = controller_grabbed_object.grab_anchor
		if not is_instance_valid(anchor):
			return
		lm.surface_begin(Mesh.PRIMITIVE_LINES)
		lm.surface_set_color(RV_INK)
		lm.surface_add_vertex(to_local(anchor.global_position))
		lm.surface_set_color(RV_CHALK)
		lm.surface_add_vertex(to_local(controller_grabbed_object.global_position))
		lm.surface_end()


# ── Small builders (rv_-prefixed so nothing in the demo can collide) ──────

func _rv_mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m


func _rv_box(p: Vector3, s: Vector3, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = s
	mi.mesh = bm
	mi.material_override = m
	mi.position = p
	return mi


## Twelve edges, no faces — a box you can see the contents of.
func _rv_wire_box(root: Node3D, center: Vector3, size: Vector3, thick: float, m: StandardMaterial3D) -> void:
	var hx: float = size.x * 0.5
	var hy: float = size.y * 0.5
	var hz: float = size.z * 0.5
	var signs: Array[float] = [-1.0, 1.0]
	for sy: float in signs:
		for sz: float in signs:
			root.add_child(_rv_box(center + Vector3(0.0, hy * sy, hz * sz),
				Vector3(size.x, thick, thick), m))
	for sx: float in signs:
		for sz2: float in signs:
			root.add_child(_rv_box(center + Vector3(hx * sx, 0.0, hz * sz2),
				Vector3(thick, size.y, thick), m))
	for sx2: float in signs:
		for sy2: float in signs:
			root.add_child(_rv_box(center + Vector3(hx * sx2, hy * sy2, 0.0),
				Vector3(thick, thick, size.z), m))


func _rv_ring(radius: float, thick: float, m: StandardMaterial3D, rot: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = maxf(radius - thick, 0.002)
	tm.outer_radius = maxf(radius, 0.006)
	mi.mesh = tm
	mi.material_override = m
	mi.rotation_degrees = rot
	return mi


func _rv_text(content: String, p: Vector3, size: int, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = content
	l.font_size = size
	l.pixel_size = 0.0012
	l.modulate = c
	l.position = p
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return l


## Labels pinned to a body that is free to rotate have to turn to stay readable.
func _rv_billboard(content: String, p: Vector3, size: int, c: Color) -> Label3D:
	var l: Label3D = _rv_text(content, p, size, c)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return l
