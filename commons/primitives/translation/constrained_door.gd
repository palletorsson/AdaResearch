# Constrained Door - Two-phase axis-restricted movement
# Uses a small grab cube as doorknob, door mesh follows as child
# Phase 1: slide along phase1_dir, for target_y
# Phase 2: slide along phase2_dir, for target_x
#
# GENERALISED 2026-08-05 for translation_cube_demo's `course` axis. The two phases were
# welded to +Y and +X: phase 1 wrote knob_pos.x/z back to their start values and clamped
# knob_pos.y, phase 2 pinned y and z and clamped x. Those are the special case of a
# projection onto a unit direction, and the direction is now a property.
#
# THE DEFAULTS ARE THE WELD. phase1_dir = +Y with span target_y and phase2_dir = +X with
# span target_x reduce the code below, line for line, to the clamps it replaced — the
# projection onto +Y IS "keep x and z, move y" — so a caller that sets nothing gets the
# shipped door. phase_count = 2 and unconstrained = false are likewise the shipped gate.
extends Node3D

signal phase_changed(phase: int)
signal goal_reached

@export var target_y: float = 0.3  # Signed span of phase 1, along phase1_dir
@export var target_x: float = 0.0  # Signed span of phase 2, along phase2_dir
@export var y_threshold: float = 0.08
@export var x_threshold: float = 0.08
@export var door_color: Color = Color(0.8, 0.3, 0.3)
@export var door_width: float = 0.6
@export var door_height: float = 1.2
@export var door_depth: float = 0.04
@export var knob_height: float = 0.6  # Height of doorknob on door
@export var mirror_knob: bool = false  # Put knob on opposite side

## Unit direction the knob is free to run in during phase 1. +Y is the shipped weld.
@export var phase1_dir: Vector3 = Vector3(0.0, 1.0, 0.0)
## Unit direction for phase 2. +X is the shipped weld.
@export var phase2_dir: Vector3 = Vector3(1.0, 0.0, 0.0)
## 2 = the shipped gate (phase 2 unlocks only when phase 1 completes). 1 = a single
## permission, no gate: reaching the end of phase 1 IS the goal.
@export var phase_count: int = 2
## Both freedoms conceded at once — no gate, no projection, only a bounding box around
## the same destination. The negative case the shipped door exists to argue against.
@export var unconstrained: bool = false

var _knob: RigidBody3D  # Small grab cube as doorknob
var _door_mesh: MeshInstance3D  # Visual door
var _current_phase: int = 1
var _is_grabbed: bool = false
var _goal_reached: bool = false
var _locked_rotation: Basis = Basis.IDENTITY

func _ready() -> void:
	_create_door_mesh()
	_create_knob()

func _create_door_mesh() -> void:
	# Create the visual door panel
	_door_mesh = MeshInstance3D.new()
	_door_mesh.name = "DoorMesh"

	var box = BoxMesh.new()
	box.size = Vector3(door_width, door_height, door_depth)
	_door_mesh.mesh = box

	# Position so bottom of door is at Y=0
	_door_mesh.position.y = door_height / 2.0

	# Material
	var material = StandardMaterial3D.new()
	material.albedo_color = door_color
	material.emission_enabled = true
	material.emission = door_color * 0.4
	material.roughness = 0.8
	_door_mesh.material_override = material

	add_child(_door_mesh)

func _create_knob() -> void:
	# Load small grab cube as doorknob
	var grab_cube_scene = load("res://commons/primitives/cubes/grab_cube.tscn")
	_knob = grab_cube_scene.instantiate()
	_knob.name = "Knob"

	# Keep knob small (default 0.1 size is fine)
	_knob.scale = Vector3(1.2, 1.2, 1.2)  # Slightly larger for easier grabbing

	# Position knob on the door at handle height
	# mirror_knob puts it on the opposite (left) side
	_knob.position = _knob_start()

	# Lock rotation
	_knob.lock_rotation = true
	_knob.angular_damp = 100.0

	# Connect signals
	if _knob.has_signal("picked_up"):
		_knob.picked_up.connect(_on_picked_up)
	if _knob.has_signal("dropped"):
		_knob.dropped.connect(_on_dropped)

	add_child(_knob)
	_locked_rotation = _knob.basis

func _on_picked_up(_pickable) -> void:
	_is_grabbed = true

func _on_dropped(_pickable) -> void:
	_is_grabbed = false

## Where the knob rests before anything is grabbed. One place, so reset(), _create_knob()
## and the constraint below cannot drift apart.
func _knob_start() -> Vector3:
	var knob_x: float = door_width * 0.35
	if mirror_knob:
		knob_x = -door_width * 0.35
	return Vector3(knob_x, knob_height, door_depth)


## Clamp a scalar run along one leg to [0, span] for a span of EITHER SIGN, with the two
## slacks the shipped clamps used: `near` at the starting end, `far` past the target.
## Phase 1 shipped (0.0, 0.05) — no give backwards, 5 cm of overshoot. Phase 2 shipped
## (0.02, 0.02) — 2 cm at both ends.
func _clamp_run(t: float, span: float, near: float, far: float) -> float:
	var lo: float = -near
	var hi: float = span + far
	if span < 0.0:
		lo = span - far
		hi = near
	return clampf(t, lo, hi)


func _physics_process(_delta: float) -> void:
	if not _knob:
		return

	# Force no rotation
	_knob.basis = _locked_rotation
	_knob.angular_velocity = Vector3.ZERO

	# Get knob position
	var knob_pos: Vector3 = _knob.position
	var start: Vector3 = _knob_start()

	if unconstrained:
		# No gate and no projection: the same destination, reachable any way at all.
		var goal_off: Vector3 = phase1_dir * target_y + phase2_dir * target_x
		var far: Vector3 = start + goal_off
		knob_pos.x = clampf(knob_pos.x, minf(start.x, far.x) - 0.02, maxf(start.x, far.x) + 0.02)
		knob_pos.y = clampf(knob_pos.y, minf(start.y, far.y) - 0.02, maxf(start.y, far.y) + 0.02)
		knob_pos.z = clampf(knob_pos.z, minf(start.z, far.z) - 0.02, maxf(start.z, far.z) + 0.02)
		if not _goal_reached and knob_pos.distance_to(far) < x_threshold:
			_goal_reached = true
			goal_reached.emit()
	else:
		match _current_phase:
			1:  # phase1_dir only. At the +Y default this IS "lock X and Z, clamp Y".
				var t: float = _clamp_run((knob_pos - start).dot(phase1_dir), target_y, 0.0, 0.05)
				knob_pos = start + phase1_dir * t

				if absf(t) >= absf(target_y) - y_threshold:
					if phase_count <= 1:
						# One permission, no gate: the end of the first leg is the goal.
						if not _goal_reached:
							_goal_reached = true
							goal_reached.emit()
					else:
						_transition_to_phase_2()

			2:  # phase2_dir only, from the position phase 1 ended at.
				var base2: Vector3 = start + phase1_dir * target_y
				var u: float = _clamp_run((knob_pos - base2).dot(phase2_dir), target_x, 0.02, 0.02)
				knob_pos = base2 + phase2_dir * u

				if not _goal_reached and absf(u - target_x) < x_threshold:
					_goal_reached = true
					goal_reached.emit()

	# Apply constrained position to knob
	_knob.position = knob_pos

	# Move door mesh to follow knob movement
	var knob_offset: Vector3 = knob_pos - start
	_door_mesh.position = Vector3(knob_offset.x, door_height / 2.0 + knob_offset.y, knob_offset.z)

func _transition_to_phase_2() -> void:
	if _current_phase == 2:
		return
	_current_phase = 2
	phase_changed.emit(2)

func get_phase() -> int:
	return _current_phase

func is_goal_reached() -> bool:
	return _goal_reached

func reset() -> void:
	_current_phase = 1
	_goal_reached = false
	if _knob:
		_knob.position = _knob_start()
	if _door_mesh:
		_door_mesh.position = Vector3(0, door_height / 2.0, 0)

# For compatibility with old code
func set_door_scale(_new_scale: Vector3) -> void:
	pass  # Door size is now set via exports
