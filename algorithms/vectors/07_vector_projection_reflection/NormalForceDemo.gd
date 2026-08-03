extends "res://algorithms/vectors/shared/force_containment_base.gd"

## Normal Force Demo
## Demonstrates: Force projection onto surface normal
## Concept: N = F · n̂ (component perpendicular to surface)
## Agent-PhysicsArchitect: Shows force decomposition
## Protocol: IACP v2.2
##
## @identity
## essence: F_normal = (F.n)*n, F_parallel = F - F_normal. Gravity decomposes into the force that holds you up and the force that makes you slide.
## desire: To show that one force becomes two when it meets a surface — the part the surface resists and the part that causes motion.
## critical_parameter: surface_angle — steeper angle means more parallel component, more sliding. At 0 degrees all force is normal; at 90 degrees all force is parallel.
## triggers: Arrow keys → tilt surface angle, ball slides along surface driven by parallel component, R → reset, Space → freeze
## emerges: The ball accelerating faster on steeper surfaces. The normal force vector shrinking as the parallel one grows — a conservation visible in arrow lengths.
## needs: Adjustable surface angle via keyboard [has], three force vectors displayed [has]. Missing: VR slider for angle, friction toggle.
## relationships: Applies vector_projection_demo concepts to physics. Feeds into fluid_resistance (another force decomposition). Lives in VectorOperations.
## truth: The surface does not push you up. It pushes you perpendicular to itself. Gravity does the rest.

# --- STAGE-2 DNA PROMOTION (2026-07-29) -------------------------------------
# This demo had no exports: one hard-coded 30 degree tilt and one hard-coded
# transparent sheet. Both of those are secretly the argument. Its truth statement
# is "the surface does not push you up, it pushes you perpendicular to itself" —
# so the two things worth varying are HOW STEEP the surface is (which decides how
# much of gravity the surface answers) and WHAT THE SURFACE IS (a mathematical
# sheet you see through, a solid you cannot, or nothing at all — a normal
# direction with no object under it).
#
#   incline  how steep      flat · gentle · slope · steep · cliff
#   surface  what it is     plane · slab · ramp · absent
#
# incline=slope is exactly 30 degrees and surface=plane is exactly the old
# transparent PlaneMesh, so the default reproduces the pre-promotion scene.

## DNA axis 1 — the tilt of the surface, which is the split between the force the
## surface answers and the force it does not. slope = the historical 30 degrees.
@export var incline: String = "slope"

## DNA axis 2 — what the surface is made of. plane = the historical transparent
## mathematical sheet; slab = a thin opaque solid; ramp = a thick block of matter
## whose top face is the surface; absent = no object at all, only the normal.
@export var surface: String = "plane"

const INCLINES := {
	"flat": 0.0,
	"gentle": 15.0,
	"slope": 30.0,
	"steep": 45.0,
	"cliff": 60.0,
}
const SURFACE_BASE_POS := Vector3(0, -0.2, 0)
const SURFACE_TINT := Color(0.7, 0.7, 0.3, 0.6)

var _dna_built: bool = false
var _surface_body: MeshInstance3D

var gravity_vector: Node3D
var normal_vector: Node3D
var parallel_vector: Node3D
var surface_plane: MeshInstance3D

var _gravity_cache: Dictionary = {}
var _normal_cache: Dictionary = {}
var _parallel_cache: Dictionary = {}

var accumulator: float = 0.0
const UPDATE_INTERVAL = 0.1

# Surface angle (can be adjusted)
var surface_angle: float = 30.0  # degrees
var surface_normal: Vector3 = Vector3.ZERO

func _ready() -> void:
	super._ready()
	surface_angle = _angle_for_incline()
	_setup_demo()
	_update_surface_normal()
	_dna_built = true
	print("NormalForceDemo: Ready - See force decomposition!")

## The angle the chosen incline asks for. "slope" returns exactly the historical
## 30.0, so the default leaves every existing placement identical.
func _angle_for_incline() -> float:
	if INCLINES.has(incline):
		return float(INCLINES[incline])
	return 30.0

func _setup_demo() -> void:
	"""Setup normal force demonstration"""
	# Create angled surface
	_create_surface()
	
	# Gravity (constant downward) - Blue
	gravity_vector = create_force_vector(
		"Gravity",
		Vector3(0, -3.0, 0),
		Color(0.3, 0.5, 1.0, 1.0),
		false
	)
	_gravity_cache = _cached_vector_nodes["Gravity"]
	
	# Normal force (perpendicular to surface) - Green
	normal_vector = create_force_vector(
		"Normal",
		Vector3.ZERO,
		Color(0.3, 1.0, 0.3, 1.0),
		false
	)
	_normal_cache = _cached_vector_nodes["Normal"]
	
	# Parallel force (along surface) - Red
	parallel_vector = create_force_vector(
		"Parallel",
		Vector3.ZERO,
		Color(1.0, 0.3, 0.3, 1.0),
		false
	)
	_parallel_cache = _cached_vector_nodes["Parallel"]
	
	update_info_text([
		"Normal Force Demo",
		"Gravity decomposes into:",
		"Normal (⊥ surface)",
		"Parallel (∥ surface)"
	])

func _create_surface() -> void:
	"""Create angled surface plane"""
	surface_plane = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(0.6, 0.6) * SCENE_SCALE
	surface_plane.mesh = plane_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = SURFACE_TINT
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface_plane.material_override = mat

	# Position and rotate surface
	surface_plane.position = SURFACE_BASE_POS * SCENE_SCALE
	surface_plane.rotation_degrees = Vector3(-surface_angle, 0, 0)

	add_child(surface_plane)
	_build_surface_body()

## DNA axis 2. surface=plane leaves the transparent sheet alone and adds nothing
## (the historical scene). The other three hide the sheet and, for slab and ramp,
## put an opaque solid in its place — matter instead of mathematics.
func _build_surface_body() -> void:
	if _surface_body != null and is_instance_valid(_surface_body):
		if _surface_body.get_parent() == self:
			remove_child(_surface_body)
		_surface_body.queue_free()
	_surface_body = null
	if surface_plane == null:
		return
	var thickness: float = 0.0
	if surface == "plane":
		surface_plane.visible = true
		return
	elif surface == "absent":
		surface_plane.visible = false
		return
	elif surface == "slab":
		thickness = 0.04
	elif surface == "ramp":
		thickness = 0.30
	else:
		# Unknown value falls back to the historical sheet.
		surface_plane.visible = true
		return
	surface_plane.visible = false
	var box := BoxMesh.new()
	box.size = Vector3(0.6, thickness, 0.6) * SCENE_SCALE
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(SURFACE_TINT.r, SURFACE_TINT.g, SURFACE_TINT.b, 1.0)
	_surface_body = MeshInstance3D.new()
	_surface_body.name = "SurfaceBody"
	_surface_body.mesh = box
	_surface_body.material_override = mat
	add_child(_surface_body)
	_place_surface_body(thickness)

## Seat the solid so its TOP face sits where the mathematical sheet used to be —
## the surface stays in the same place, it just acquires a body below it.
func _place_surface_body(thickness: float) -> void:
	if _surface_body == null or not is_instance_valid(_surface_body):
		return
	_surface_body.rotation_degrees = Vector3(-surface_angle, 0, 0)
	var drop: float = thickness * 0.5 * SCENE_SCALE
	var down: Vector3 = _surface_body.transform.basis.y * drop
	_surface_body.position = SURFACE_BASE_POS * SCENE_SCALE - down

## Current solid thickness, so a re-tilt can re-seat it without rebuilding.
func _surface_body_thickness() -> float:
	if surface == "ramp":
		return 0.30
	elif surface == "slab":
		return 0.04
	return 0.04

func _update_surface_normal() -> void:
	"""Calculate surface normal from angle"""
	var angle_rad = deg_to_rad(surface_angle)
	surface_normal = Vector3(0, cos(angle_rad), sin(angle_rad)).normalized()

func _physics_process(delta: float) -> void:
	update_force_vector_position()
	
	# Gravity force (constant)
	var gravity = Vector3(0, -3.0, 0)
	
	# Project gravity onto surface normal: F_normal = (F · n̂) * n̂
	var normal_magnitude = gravity.dot(surface_normal)
	var f_normal = surface_normal * normal_magnitude
	
	# Parallel component: F_parallel = F - F_normal
	var f_parallel = gravity - f_normal
	
	# Update vectors
	_update_vector_fast_cached(_gravity_cache, gravity)
	_update_vector_fast_cached(_normal_cache, f_normal)
	_update_vector_fast_cached(_parallel_cache, f_parallel)
	
	# Apply forces (normal cancels with surface, parallel causes sliding)
	physics_ball.apply_central_force(f_parallel * SCENE_SCALE)
	
	# Throttled info update
	accumulator += delta
	if accumulator >= UPDATE_INTERVAL:
		_update_info(gravity, f_normal, f_parallel)
		accumulator = 0.0

func _update_info(gravity: Vector3, f_normal: Vector3, f_parallel: Vector3) -> void:
	"""Update info display"""
	var lines = [
		"Normal Force Demo",
		"Surface Angle: %.1f°" % surface_angle,
		"",
		"Gravity: %.2f N" % gravity.length(),
		"g = (%.2f, %.2f, %.2f)" % [gravity.x, gravity.y, gravity.z],
		"",
		"Normal Force: %.2f N" % f_normal.length(),
		"N = (g · n̂) * n̂",
		"N = (%.2f, %.2f, %.2f)" % [f_normal.x, f_normal.y, f_normal.z],
		"",
		"Parallel Force: %.2f N" % f_parallel.length(),
		"F∥ = g - N",
		"F∥ = (%.2f, %.2f, %.2f)" % [f_parallel.x, f_parallel.y, f_parallel.z]
	]
	update_info_text(lines)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_reset_demo()
		elif event.keycode == KEY_SPACE:
			physics_ball.linear_velocity = Vector3.ZERO
			physics_ball.angular_velocity = Vector3.ZERO
		elif event.keycode == KEY_UP:
			surface_angle = clamp(surface_angle + 5.0, 0.0, 60.0)
			_update_surface_angle()
		elif event.keycode == KEY_DOWN:
			surface_angle = clamp(surface_angle - 5.0, 0.0, 60.0)
			_update_surface_angle()

func _update_surface_angle() -> void:
	"""Update surface angle and normal"""
	if surface_plane:
		surface_plane.rotation_degrees = Vector3(-surface_angle, 0, 0)
	_place_surface_body(_surface_body_thickness())
	_update_surface_normal()
	print("NormalForceDemo: Angle = %.1f°" % surface_angle)

func _reset_demo() -> void:
	"""Reset to initial state"""
	reset_ball(Vector3(0, 0.1, 0))
	print("NormalForceDemo: Reset")

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Guarded: nothing is rebuilt unless a value actually CHANGED, and nothing is
## touched before _ready() has built once (config can arrive first — then the
## exports are seeded and _ready applies them).
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	var angle_changed: bool = false
	var surface_changed: bool = false
	if config.has("incline"):
		var new_incline: String = str(config["incline"])
		if new_incline != incline:
			incline = new_incline
			surface_angle = _angle_for_incline()
			angle_changed = true
	if config.has("surface"):
		var new_surface: String = str(config["surface"])
		if new_surface != surface:
			surface = new_surface
			surface_changed = true
	if not _dna_built:
		return
	if surface_changed:
		_build_surface_body()
	if angle_changed:
		_update_surface_angle()
