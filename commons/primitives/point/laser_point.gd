extends StaticBody3D

# @identity
# essence: a point you reach with light — the VR laser is your finger across the room
# desire: to make a 4-metre vector tip as movable as one on the table; distance should not mean unreachable
# critical_parameter: grab_distance — the point rides the laser ray at the distance it was caught, so a flick of the wrist sweeps it through space
# triggers: FunctionPointer ray hits this body (layer 21) → trigger press grabs → ray movement drags → release drops
# emerges: ranged manipulation; the room becomes the workbench, the hand a director's baton
# relationships: endpoint for the XL vector benches (addition/subtraction/…); sibling to snap_point (near-hand grab) — this one is for distance
# truth: interaction is not about proximity; a laser turns pointing into touching.

## A vector endpoint you move with the VR laser pointer
## (XROrigin3D/<Hand>/XRToolsCollisionHand/FunctionPointer). It sits on collision
## layer 21 — the pointer's DEFAULT_MASK target layer — and implements
## pointer_event(event) to grab and drag along the laser ray at constant distance.
## Built for the big (4 m+) vector benches where the tips are out of arm's reach;
## works at any scale. NOT an XRToolsPickable, so it never fights near-hand grab.

signal point_moved(global_pos: Vector3)
signal drag_started
signal drag_ended

@export var color: Color = Color(0.15, 0.85, 1.0, 1.0)
@export var highlight_color: Color = Color(0.4, 1.0, 0.7, 1.0)
## Visible marker radius (local). The scene root scale enlarges it in world space.
@export var radius: float = 0.04
## Collision radius — generous so the laser catches the point easily; defaults to
## a multiple of the visible radius.
@export var hit_radius: float = 0.0
## Minimum grab distance so the point can't be yanked into the player's face.
@export var min_grab_distance: float = 0.15

const POINTER_LAYER := 1 << 20  # collision layer 21 (FunctionPointer DEFAULT_MASK)

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _shape: CollisionShape3D
var _dragging := false
var _pointer: Node3D = null
var _grab_distance: float = 1.0

func _ready() -> void:
	collision_layer = POINTER_LAYER
	collision_mask = 0
	input_ray_pickable = false
	if hit_radius <= 0.0:
		hit_radius = radius * 2.2

	if _shape == null:
		_shape = CollisionShape3D.new()
		var s := SphereShape3D.new()
		s.radius = hit_radius
		_shape.shape = s
		add_child(_shape)

	if _mesh == null:
		_mesh = MeshInstance3D.new()
		_mesh.name = "Marker"
		var sm := SphereMesh.new()
		sm.radius = radius
		sm.height = radius * 2.0
		sm.radial_segments = 20
		sm.rings = 12
		_mesh.mesh = sm
		_mat = StandardMaterial3D.new()
		_mat.albedo_color = color
		_mat.emission_enabled = true
		_mat.emission = color
		_mat.emission_energy_multiplier = 0.9
		_mesh.material_override = _mat
		add_child(_mesh)

	# A faint ring that reads as "pointable" even before the laser arrives.
	var ring := MeshInstance3D.new()
	ring.name = "Halo"
	var tm := TorusMesh.new()
	tm.inner_radius = radius * 1.4
	tm.outer_radius = radius * 1.7
	ring.mesh = tm
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(color.r, color.g, color.b, 0.35)
	rmat.emission_enabled = true
	rmat.emission = color
	rmat.emission_energy_multiplier = 0.6
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = rmat
	add_child(ring)


## While grabbed, follow the laser ray EVERY frame from the live pointer
## transform — NOT only on the pointer's MOVED events. Event-driven dragging
## stutters whenever the scene's per-frame recalculation hitches the frame (the
## events batch up), so the point would freeze and jump. A per-frame follow
## keeps the movement free and continuous, independent of the recalculation.
func _process(_delta: float) -> void:
	if _dragging:
		_drag_to_ray()


## Called by XRToolsPointerEvent.report() when the laser interacts with this body.
func pointer_event(event) -> void:
	match event.event_type:
		XRToolsPointerEvent.Type.ENTERED:
			_set_hover(true)
		XRToolsPointerEvent.Type.EXITED:
			if not _dragging:
				_set_hover(false)
		XRToolsPointerEvent.Type.PRESSED:
			_begin_drag(event.pointer)
		XRToolsPointerEvent.Type.RELEASED:
			_end_drag()
		# MOVED is intentionally ignored — _process drives the follow so the
		# point tracks the ray smoothly even when MOVED events are sparse.


func _begin_drag(pointer: Node3D) -> void:
	if pointer == null or not is_instance_valid(pointer):
		return
	_pointer = pointer
	_dragging = true
	var ray := _ray_xform()
	var fwd: Vector3 = -ray.basis.z
	var to_pt: Vector3 = global_position - ray.origin
	_grab_distance = maxf(min_grab_distance, to_pt.dot(fwd))
	_set_hover(true)
	emit_signal("drag_started")


func _drag_to_ray() -> void:
	if _pointer == null or not is_instance_valid(_pointer):
		_end_drag()
		return
	var ray := _ray_xform()
	var new_global: Vector3 = ray.origin + (-ray.basis.z) * _grab_distance
	global_position = new_global
	emit_signal("point_moved", new_global)


func _end_drag() -> void:
	if not _dragging:
		return
	_dragging = false
	_pointer = null
	_set_hover(false)
	emit_signal("drag_ended")


## Exact laser axis: prefer the pointer's RayCast child, fall back to the
## pointer node's own -Z forward.
func _ray_xform() -> Transform3D:
	if _pointer and is_instance_valid(_pointer):
		var rc := _pointer.get_node_or_null("RayCast")
		if rc is Node3D:
			return (rc as Node3D).global_transform
		return _pointer.global_transform
	return global_transform


func _set_hover(on: bool) -> void:
	if _mat:
		_mat.albedo_color = highlight_color if on else color
		_mat.emission = highlight_color if on else color
		_mat.emission_energy_multiplier = 1.8 if on else 0.9
	if _mesh:
		_mesh.scale = Vector3.ONE * (1.3 if on else 1.0)


## Lets callers resize the handle (e.g. the vector bench shrinking the local
## radius so the world-space size stays sensible at large root scale).
func set_handle_radius(visible_r: float, collider_r: float = 0.0) -> void:
	radius = visible_r
	hit_radius = collider_r if collider_r > 0.0 else visible_r * 2.2
	if _shape and _shape.shape is SphereShape3D:
		(_shape.shape as SphereShape3D).radius = hit_radius
	if _mesh and _mesh.mesh is SphereMesh:
		(_mesh.mesh as SphereMesh).radius = radius
		(_mesh.mesh as SphereMesh).height = radius * 2.0
