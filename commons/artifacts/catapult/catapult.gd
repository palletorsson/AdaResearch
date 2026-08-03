# Catapult.gd
# A procedural catapult that teaches force/velocity vectors through projectile launch.
#
# @identity
# essence: p(t) = p0 + v0*t + 0.5*g*t^2. A launch is an initial condition. Set the
#   angle (direction) and the force (magnitude) and the parabola is already written —
#   you only watch it play out.
# desire: To fling. To pull two levers and watch a stone trace the arc you composed.
# critical_parameter: The release velocity = launch_dir(angle) * force. Direction and
#   magnitude together. After FIRE, gravity alone bends the rest.
# triggers: angle slider → arm tilts + live parabola redraws; force slider → arrow
#   grows + parabola lengthens; FIRE → arm swings, ball launches along the preview.
# emerges: The realisation that the velocity arrow + the constant gravity arrow ARE
#   the parabola. Aim becomes prediction.
# truth: Velocity is what you give. Gravity is what is given. The arc is their sum.
extends Node3D
class_name Catapult

# ── Tunable configuration (overridable via apply_grid_config) ───────────────
var gravity_magnitude: float = 9.8          # m/s^2, downward
var default_angle_deg: float = 50.0          # launch elevation, 10..80
var default_force: float = 9.0               # launch speed (m/s)
var min_force: float = 3.0
var max_force: float = 16.0
var min_angle_deg: float = 10.0
var max_angle_deg: float = 80.0
var projectile_lifetime: float = 6.0
var max_live_projectiles: int = 5

# ── DNA axes (stage 2) ──────────────────────────────────────────────────────
## foresight — how much of the arc is handed to you BEFORE you fire.
##   parabola: the whole dotted flight path (the arc is already written)
##   apex:     only the peak of the throw is marked (the summit, not the route)
##   landing:  only the impact ring on the floor (the target, not the flight)
##   none:     nothing — aim from the vectors alone
@export_enum("parabola", "apex", "landing", "none") var foresight: String = "parabola"

## vectors — how "what you give" is drawn at the basket.
##   sum:        one velocity arrow + the constant gravity arrow
##   components: velocity split into its horizontal and vertical parts
##   velocity:   only the throw; gravity is left unstated
##   gravity:    only the given; the throw is left unstated
@export_enum("sum", "components", "velocity", "gravity") var vectors: String = "sum"

## throw — the initial condition the machine is BUILT to deliver. foresight and
## vectors both draw the same arc in different amounts; until this axis existed
## there was only ever one arc to draw. Every catapult in the world stood at
## 50 deg / 9.0 m/s, so the artifact's own claim — that you compose the parabola
## by writing direction and magnitude — was never once demonstrated by a placement.
## The four non-default values are a 2x2 around the shipped throw: two turn the
## DIRECTION at unchanged magnitude, two turn the MAGNITUDE at unchanged direction.
##   balanced: a deliberate NO-OP. Leaves default_angle_deg / default_force exactly
##             as the scene (or a map's #angle:/#force: config) set them.
##   mortar:   75 deg, same force. Steep and near — the arm stands almost upright
##             and most of the throw is spent going up and coming back.
##   flat:     20 deg, same force. A low line, and SHORTER than balanced: with
##             mortar it brackets the 45 deg optimum from both sides.
##   heavy:    same 50 deg aim, 13 m/s. Identical direction, more magnitude, and
##             the range goes as v^2 — twice the arc for half again the speed.
##   weak:     same 50 deg aim, 5 m/s. The other half of the same lesson.
@export_enum("balanced", "mortar", "flat", "heavy", "weak") var throw: String = "balanced"

## [angle_deg, force] per throw. "balanced" is absent ON PURPOSE — it means "use
## whatever the scene/config authored", which is how the 4 shipped placements stay
## byte-identical. Values sit inside the shipped 10..80 deg / 3..16 m/s limits, so
## nothing is clamped away and the sliders can still walk anywhere from here.
const THROWS := {
	"mortar": [75.0, 9.0],
	"flat": [20.0, 9.0],
	"heavy": [50.0, 13.0],
	"weak": [50.0, 5.0],
}

## Force the counterweight block was modelled against. At this force the block is
## its shipped size, so `balanced` never touches the geometry.
const THROW_REFERENCE_FORCE: float = 9.0

# Colors
var frame_color: Color = Color(0.32, 0.22, 0.14)        # wood-brown frame
var metal_color: Color = Color(0.25, 0.27, 0.30)        # metal fittings
var arm_color: Color = Color(0.45, 0.30, 0.18)          # throwing arm
var counterweight_color: Color = Color(0.18, 0.18, 0.20)
var ball_color: Color = Color(0.85, 0.55, 0.20)
var velocity_arrow_color: Color = Color(0.20, 1.0, 0.55)  # green = the throw
var gravity_arrow_color: Color = Color(1.0, 0.30, 0.30)   # red = constant down
var trajectory_color: Color = Color(1.0, 0.95, 0.55)      # yellow parabola

# ── Runtime state ───────────────────────────────────────────────────────────
var _angle_deg: float = 50.0
var _force: float = 9.0

# Geometry constants (local space). Basket sits at the tip of the throwing arm.
const ARM_LENGTH: float = 0.85
const ARM_PIVOT_HEIGHT: float = 0.75
const ARROW_THICKNESS: float = 0.018

# Node references
var _arm_pivot: Node3D = null            # rotates to show launch angle
var _arm_tip: Node3D = null              # marker at end of arm (basket origin)
var _basket: Node3D = null
var _counterweight: MeshInstance3D = null   # scaled by the `throw` axis only
var _velocity_arrow: Node3D = null
var _gravity_arrow: Node3D = null
var _vx_arrow: Node3D = null            # built lazily, only for vectors = components
var _vy_arrow: Node3D = null
var _trajectory_mesh: ImmediateMesh = null
var _trajectory_instance: MeshInstance3D = null
var _velocity_label: Label3D = null
var _gravity_label: Label3D = null
var _readout_label: Label3D = null
var _controls_root: Node3D = null
var _angle_slider: Node3D = null
var _force_slider: Node3D = null
var _fire_button: Node3D = null
var _projectile_container: Node3D = null

# Arm swing animation state
var _is_firing: bool = false
var _fire_time: float = 0.0
const FIRE_SWING_DURATION: float = 0.28     # how long the visible arm swing lasts
var _rest_angle_offset: float = 0.0         # extra tilt-back applied while loaded

# Preloaded interactables
const SLIDER_SCENE := preload("res://commons/interactables/slider_horizontal.tscn")
const BUTTON_SCENE := preload("res://commons/interactables/push_button.tscn")

signal fired(launch_velocity: Vector3)


# ═════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# At throw = "balanced" this is exactly the two clamps that stood here before
	# the axis existed, so the shipped placements build unchanged.
	_apply_throw()

	_projectile_container = Node3D.new()
	_projectile_container.name = "Projectiles"
	add_child(_projectile_container)

	_build_frame()
	_build_arm()
	_build_vector_indicators()
	_build_trajectory_preview()
	_build_controls()
	_build_readout()

	_apply_angle_to_arm()
	_refresh_visuals()


func _process(delta: float) -> void:
	if _is_firing:
		_advance_fire_swing(delta)


# ═════════════════════════════════════════════════════════════════════════
# CATAPULT GEOMETRY
# ═════════════════════════════════════════════════════════════════════════

## Base + frame: two A-frame uprights, ground sill beams, a pivot axle.
func _build_frame() -> void:
	var frame := Node3D.new()
	frame.name = "Frame"
	add_child(frame)

	var wood_mat := _make_material(frame_color, 0.0, 0.85, 0.05)
	var metal_mat := _make_material(metal_color, 0.0, 0.45, 0.6)

	# Ground sill beams (two rails running front-to-back)
	for side in [-0.45, 0.45]:
		var sill := MeshInstance3D.new()
		var sill_box := BoxMesh.new()
		sill_box.size = Vector3(0.12, 0.12, 1.5)
		sill.mesh = sill_box
		sill.material_override = wood_mat
		sill.position = Vector3(side, 0.06, 0.0)
		frame.add_child(sill)

	# Cross brace at the back (counterweight side)
	var brace := MeshInstance3D.new()
	var brace_box := BoxMesh.new()
	brace_box.size = Vector3(1.02, 0.10, 0.12)
	brace.mesh = brace_box
	brace.material_override = wood_mat
	brace.position = Vector3(0.0, 0.06, 0.55)
	frame.add_child(brace)

	# Two A-frame uprights that carry the pivot axle
	for side in [-0.45, 0.45]:
		var upright := MeshInstance3D.new()
		var up_box := BoxMesh.new()
		up_box.size = Vector3(0.10, ARM_PIVOT_HEIGHT, 0.12)
		upright.mesh = up_box
		upright.material_override = wood_mat
		upright.position = Vector3(side, ARM_PIVOT_HEIGHT * 0.5, 0.0)
		frame.add_child(upright)

		# Diagonal strut for torsion-machine look
		var strut := MeshInstance3D.new()
		var strut_box := BoxMesh.new()
		strut_box.size = Vector3(0.07, ARM_PIVOT_HEIGHT * 0.95, 0.07)
		strut.mesh = strut_box
		strut.material_override = wood_mat
		strut.position = Vector3(side, ARM_PIVOT_HEIGHT * 0.45, 0.30)
		strut.rotation = Vector3(deg_to_rad(-32.0), 0.0, 0.0)
		frame.add_child(strut)

	# Pivot axle (the cylinder the arm rotates around), along X
	var axle := MeshInstance3D.new()
	var axle_cyl := CylinderMesh.new()
	axle_cyl.top_radius = 0.05
	axle_cyl.bottom_radius = 0.05
	axle_cyl.height = 1.05
	axle.mesh = axle_cyl
	axle.material_override = metal_mat
	axle.position = Vector3(0.0, ARM_PIVOT_HEIGHT, 0.0)
	axle.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))  # lay cylinder along X
	frame.add_child(axle)

	# Torsion bundle (decorative coil look at the pivot)
	var torsion := MeshInstance3D.new()
	var tor_cyl := CylinderMesh.new()
	tor_cyl.top_radius = 0.10
	tor_cyl.bottom_radius = 0.10
	tor_cyl.height = 0.30
	torsion.mesh = tor_cyl
	torsion.material_override = _make_material(Color(0.55, 0.40, 0.20), 0.0, 0.7, 0.1)
	torsion.position = Vector3(0.0, ARM_PIVOT_HEIGHT, 0.0)
	torsion.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	frame.add_child(torsion)


## Throwing arm with a basket/cup at the tip and a counterweight at the short end.
func _build_arm() -> void:
	_arm_pivot = Node3D.new()
	_arm_pivot.name = "ArmPivot"
	_arm_pivot.position = Vector3(0.0, ARM_PIVOT_HEIGHT, 0.0)
	add_child(_arm_pivot)

	var arm_mat := _make_material(arm_color, 0.0, 0.8, 0.08)

	# The long throwing beam. Local +Z is the "long arm" direction; the pivot
	# rotation about X tilts it up toward launch. We model the beam extending
	# along +Z so that an arm-pivot rotation maps cleanly to elevation.
	var beam := MeshInstance3D.new()
	beam.name = "Beam"
	var beam_box := BoxMesh.new()
	beam_box.size = Vector3(0.10, 0.10, ARM_LENGTH)
	beam.mesh = beam_box
	beam.material_override = arm_mat
	beam.position = Vector3(0.0, 0.0, ARM_LENGTH * 0.5)
	_arm_pivot.add_child(beam)

	# Short counterweight arm (opposite end, along -Z)
	var short_arm := MeshInstance3D.new()
	var short_box := BoxMesh.new()
	short_box.size = Vector3(0.08, 0.08, 0.35)
	short_arm.mesh = short_box
	short_arm.material_override = arm_mat
	short_arm.position = Vector3(0.0, 0.0, -0.20)
	_arm_pivot.add_child(short_arm)

	# Counterweight block
	var weight := MeshInstance3D.new()
	var weight_box := BoxMesh.new()
	weight_box.size = Vector3(0.26, 0.26, 0.26)
	weight.mesh = weight_box
	weight.material_override = _make_material(counterweight_color, 0.0, 0.55, 0.5)
	weight.position = Vector3(0.0, 0.0, -0.40)
	_arm_pivot.add_child(weight)
	_counterweight = weight
	# The counterweight is machine build, not aim: it follows the `throw` axis and
	# is left alone by the FORCE slider. At `balanced` it is never touched at all.
	_apply_counterweight_scale()

	# Tip marker (basket origin) at the end of the long beam
	_arm_tip = Node3D.new()
	_arm_tip.name = "ArmTip"
	_arm_tip.position = Vector3(0.0, 0.0, ARM_LENGTH)
	_arm_pivot.add_child(_arm_tip)

	# Basket / cup at the tip
	_basket = Node3D.new()
	_basket.name = "Basket"
	_arm_tip.add_child(_basket)

	var cup_mat := _make_material(Color(0.30, 0.22, 0.12), 0.0, 0.9, 0.05)
	# Cup floor
	var cup_floor := MeshInstance3D.new()
	var floor_cyl := CylinderMesh.new()
	floor_cyl.top_radius = 0.11
	floor_cyl.bottom_radius = 0.08
	floor_cyl.height = 0.03
	cup_floor.mesh = floor_cyl
	cup_floor.material_override = cup_mat
	cup_floor.position = Vector3(0.0, 0.05, 0.0)
	_basket.add_child(cup_floor)

	# A loaded ball resting in the cup (cosmetic; hidden during flight)
	var loaded := MeshInstance3D.new()
	loaded.name = "LoadedBall"
	var loaded_sphere := SphereMesh.new()
	loaded_sphere.radius = 0.07
	loaded_sphere.height = 0.14
	loaded.mesh = loaded_sphere
	loaded.material_override = _make_material(ball_color, 0.6, 0.5, 0.2)
	loaded.position = Vector3(0.0, 0.10, 0.0)
	_basket.add_child(loaded)


# ═════════════════════════════════════════════════════════════════════════
# VECTOR INDICATORS + TRAJECTORY
# ═════════════════════════════════════════════════════════════════════════

func _build_vector_indicators() -> void:
	_velocity_arrow = _create_arrow("VelocityArrow", velocity_arrow_color)
	add_child(_velocity_arrow)
	_gravity_arrow = _create_arrow("GravityArrow", gravity_arrow_color)
	add_child(_gravity_arrow)

	_velocity_label = _make_label("v0", velocity_arrow_color)
	add_child(_velocity_label)
	_gravity_label = _make_label("g", gravity_arrow_color)
	add_child(_gravity_label)


func _build_trajectory_preview() -> void:
	_trajectory_mesh = ImmediateMesh.new()
	_trajectory_instance = MeshInstance3D.new()
	_trajectory_instance.name = "TrajectoryPreview"
	_trajectory_instance.mesh = _trajectory_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = trajectory_color
	mat.emission_enabled = true
	mat.emission = trajectory_color
	mat.emission_energy_multiplier = 0.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_trajectory_instance.material_override = mat
	add_child(_trajectory_instance)


## Build an arrow (shaft cylinder + cone head). Mirrors hl_turret_vectors.
func _create_arrow(arrow_name: String, color: Color) -> Node3D:
	var arrow := Node3D.new()
	arrow.name = arrow_name

	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = ARROW_THICKNESS
	cylinder.bottom_radius = ARROW_THICKNESS
	cylinder.height = 1.0
	shaft.mesh = cylinder
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	shaft.material_override = mat
	arrow.add_child(shaft)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = ARROW_THICKNESS * 2.5
	cone.height = ARROW_THICKNESS * 5.0
	head.mesh = cone
	head.material_override = mat
	arrow.add_child(head)

	return arrow


## Position an arrow from start to end (both in this node's local space),
## scaling shaft and placing the head. Mirrors hl_turret_vectors._position_arrow.
func _position_arrow(arrow: Node3D, start: Vector3, end: Vector3) -> void:
	var dir := end - start
	var length := dir.length()
	if length < 0.01:
		arrow.visible = false
		return
	arrow.visible = true

	arrow.transform = Transform3D.IDENTITY
	arrow.position = start

	var shaft: Node3D = arrow.get_node("Shaft")
	var head: Node3D = arrow.get_node("Head")

	var shaft_length: float = length - ARROW_THICKNESS * 5.0
	shaft.scale = Vector3(1, max(shaft_length, 0.01), 1)
	shaft.position = dir.normalized() * (shaft_length / 2.0)
	head.position = dir.normalized() * (length - ARROW_THICKNESS * 2.5)

	# look_at() works in GLOBAL space. `dir` is expressed in the arrow's parent
	# local frame, so rotate it by the parent's global basis to get a world
	# direction before aiming. This keeps arrows correct even when the catapult
	# is placed with rotation/scale in a map.
	var parent := arrow.get_parent() as Node3D
	var world_dir := dir
	if parent:
		world_dir = parent.global_transform.basis * dir
	var up := Vector3.UP
	if world_dir.length() > 0.0001 and abs(world_dir.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD
	arrow.look_at(arrow.global_position + world_dir, up)
	arrow.rotate_object_local(Vector3.RIGHT, PI / 2.0)


# ═════════════════════════════════════════════════════════════════════════
# MATH — direction, velocity, parabola
# ═════════════════════════════════════════════════════════════════════════

## Unit launch direction in this node's local space from the elevation angle.
## The catapult throws toward +Z (forward), rising by angle above the floor.
func _launch_direction() -> Vector3:
	var a := deg_to_rad(_angle_deg)
	return Vector3(0.0, sin(a), cos(a)).normalized()


## Full initial velocity vector (local space).
func _launch_velocity() -> Vector3:
	return _launch_direction() * _force


## Basket position in local space (where the projectile leaves the arm).
func _basket_local_position() -> Vector3:
	if _arm_tip == null:
		return Vector3(0.0, ARM_PIVOT_HEIGHT + ARM_LENGTH * 0.5, 0.3)
	# Convert the basket's global position into this node's local space.
	var basket_global := _arm_tip.global_transform.origin
	return to_local(basket_global)


# ═════════════════════════════════════════════════════════════════════════
# CONTROLS
# ═════════════════════════════════════════════════════════════════════════

func _build_controls() -> void:
	_controls_root = Node3D.new()
	_controls_root.name = "Controls"
	# A small console in front of the machine, facing the player.
	_controls_root.position = Vector3(0.0, 0.95, -0.85)
	add_child(_controls_root)

	# Console panel for the sliders/button to sit on
	var panel := MeshInstance3D.new()
	var panel_box := BoxMesh.new()
	panel_box.size = Vector3(0.7, 0.32, 0.04)
	panel.mesh = panel_box
	panel.material_override = _make_material(Color(0.10, 0.11, 0.13), 0.05, 0.6, 0.4)
	panel.rotation = Vector3(deg_to_rad(-25.0), 0.0, 0.0)
	_controls_root.add_child(panel)

	# ANGLE slider
	_angle_slider = SLIDER_SCENE.instantiate()
	_angle_slider.position = Vector3(-0.18, 0.06, 0.05)
	_angle_slider.rotation = Vector3(deg_to_rad(-25.0), 0.0, 0.0)
	_controls_root.add_child(_angle_slider)
	if _angle_slider.has_method("set_param_name"):
		_angle_slider.set_param_name("ANGLE")
	if _angle_slider.has_method("set_range"):
		_angle_slider.set_range(min_angle_deg, max_angle_deg)
	if _angle_slider.has_method("set_normalized_value"):
		_angle_slider.set_normalized_value(
			inverse_lerp(min_angle_deg, max_angle_deg, _angle_deg))
	if _angle_slider.has_signal("slider_moved"):
		_angle_slider.connect("slider_moved", Callable(self, "_on_angle_slider_moved"))

	# FORCE slider
	_force_slider = SLIDER_SCENE.instantiate()
	_force_slider.position = Vector3(0.18, 0.06, 0.05)
	_force_slider.rotation = Vector3(deg_to_rad(-25.0), 0.0, 0.0)
	_controls_root.add_child(_force_slider)
	if _force_slider.has_method("set_param_name"):
		_force_slider.set_param_name("FORCE")
	if _force_slider.has_method("set_range"):
		_force_slider.set_range(min_force, max_force)
	if _force_slider.has_method("set_normalized_value"):
		_force_slider.set_normalized_value(
			inverse_lerp(min_force, max_force, _force))
	if _force_slider.has_signal("slider_moved"):
		_force_slider.connect("slider_moved", Callable(self, "_on_force_slider_moved"))

	# FIRE button
	_fire_button = BUTTON_SCENE.instantiate()
	_fire_button.position = Vector3(0.0, -0.07, 0.07)
	_fire_button.rotation = Vector3(deg_to_rad(-25.0), 0.0, 0.0)
	# push_button.tscn root rotates -90deg about X so its face points up; we set
	# colors via dynamic .set() so this stays robust to property renames.
	_fire_button.set("pressed_color", Color(1.0, 0.35, 0.10))
	_fire_button.set("released_color", Color(0.90, 0.85, 0.30))
	_controls_root.add_child(_fire_button)
	# The push_button root exposes a clean `pressed` signal; prefer it. Fall back
	# to the inner InteractableAreaButton.button_pressed if unavailable.
	if _fire_button.has_signal("pressed"):
		_fire_button.connect("pressed", Callable(self, "_on_fire_pressed"))
	else:
		var inner := _fire_button.get_node_or_null("InteractableAreaButton")
		if inner and inner.has_signal("button_pressed"):
			inner.connect("button_pressed", Callable(self, "_on_fire_button_inner"))
	# Refresh button color now that we changed it externally.
	if _fire_button.has_method("update_colors"):
		_fire_button.call_deferred("update_colors")

	# Console labels
	var angle_lbl := _make_label("LAUNCH ANGLE", Color(0.8, 0.9, 1.0), 18)
	angle_lbl.position = Vector3(-0.18, 0.15, 0.06)
	_controls_root.add_child(angle_lbl)
	var force_lbl := _make_label("FORCE (SPEED)", Color(0.8, 0.9, 1.0), 18)
	force_lbl.position = Vector3(0.18, 0.15, 0.06)
	_controls_root.add_child(force_lbl)
	var fire_lbl := _make_label("FIRE", Color(1.0, 0.6, 0.3), 20)
	fire_lbl.position = Vector3(0.0, -0.16, 0.06)
	_controls_root.add_child(fire_lbl)


func _build_readout() -> void:
	_readout_label = _make_label("", Color(0.7, 1.0, 0.7), 16)
	_readout_label.position = Vector3(0.0, ARM_PIVOT_HEIGHT + 1.05, 0.0)
	add_child(_readout_label)


# ═════════════════════════════════════════════════════════════════════════
# CONTROL CALLBACKS
# ═════════════════════════════════════════════════════════════════════════

func _on_angle_slider_moved(_value) -> void:
	var norm := 0.5
	if _angle_slider and _angle_slider.has_method("get_normalized_value"):
		norm = _angle_slider.get_normalized_value()
	_angle_deg = lerp(min_angle_deg, max_angle_deg, clamp(norm, 0.0, 1.0))
	if not _is_firing:
		_apply_angle_to_arm()
	_refresh_visuals()


func _on_force_slider_moved(_value) -> void:
	var norm := 0.5
	if _force_slider and _force_slider.has_method("get_normalized_value"):
		norm = _force_slider.get_normalized_value()
	_force = lerp(min_force, max_force, clamp(norm, 0.0, 1.0))
	_refresh_visuals()


func _on_fire_pressed() -> void:
	_fire()


func _on_fire_button_inner(_button) -> void:
	_fire()


# ═════════════════════════════════════════════════════════════════════════
# VISUAL REFRESH (arm angle, arrows, parabola, readout)
# ═════════════════════════════════════════════════════════════════════════

## Tilt the throwing arm so its long beam (+Z) rises to the launch elevation.
func _apply_angle_to_arm() -> void:
	if _arm_pivot == null:
		return
	# Rotating about X by -angle lifts local +Z up toward +Y.
	_arm_pivot.rotation = Vector3(deg_to_rad(-_angle_deg) + _rest_angle_offset, 0.0, 0.0)


## Write the chosen initial condition into the live angle/force.
##
## "balanced" is the else-branch and is the two clamps _ready always did, reading
## default_angle_deg / default_force — which _apply_throw never overwrites. So a
## map that switches to `mortar` and back to `balanced` lands on the authored
## throw again, and a map that says nothing gets the shipped 50 deg / 9.0 m/s.
func _apply_throw() -> void:
	if THROWS.has(throw):
		var entry: Array = THROWS[throw]
		_angle_deg = clamp(float(entry[0]), min_angle_deg, max_angle_deg)
		_force = clamp(float(entry[1]), min_force, max_force)
	else:
		_angle_deg = clamp(default_angle_deg, min_angle_deg, max_angle_deg)
		_force = clamp(default_force, min_force, max_force)
	_apply_counterweight_scale()


## Size the counterweight block against the throw it is built to deliver: mass
## goes as volume, so the edge scales with the cube root of the force ratio.
## Guarded on THROWS so `balanced` — including a placement that overrides the
## force through config — leaves the block at the size it was modelled.
func _apply_counterweight_scale() -> void:
	if _counterweight == null or not THROWS.has(throw):
		return
	var ratio: float = maxf(_force, 0.1) / THROW_REFERENCE_FORCE
	var edge: float = pow(ratio, 1.0 / 3.0)
	_counterweight.scale = Vector3(edge, edge, edge)


func _refresh_visuals() -> void:
	# Force-affecting transforms must be current before we read the basket pose.
	_update_vector_arrows()
	_update_trajectory()
	_update_readout()


## The component arrows only exist when the `components` value asks for them, so
## the default scene tree (and its capture AABB) is exactly the pre-promotion one.
func _ensure_component_arrows() -> void:
	if _vx_arrow != null:
		return
	_vx_arrow = _create_arrow("VxArrow", velocity_arrow_color)
	add_child(_vx_arrow)
	_vy_arrow = _create_arrow("VyArrow", Color(0.35, 0.75, 1.0))
	add_child(_vy_arrow)


func _update_vector_arrows() -> void:
	var p0 := _basket_local_position()
	var v0 := _launch_velocity()

	var split: bool = vectors == "components"
	var show_velocity: bool = vectors != "gravity"
	var show_gravity: bool = vectors != "velocity"
	if split:
		_ensure_component_arrows()

	# Velocity arrow: scaled down so it reads as a direction handle, not the
	# full metric length (which can be long). 0.10 m per (m/s).
	var vel_end := p0 + v0 * 0.10
	if _velocity_arrow:
		if show_velocity and not split:
			_position_arrow(_velocity_arrow, p0, vel_end)
		else:
			_velocity_arrow.visible = false

	# Component arrows: the same throw, written as horizontal + vertical.
	if _vx_arrow:
		if split:
			_position_arrow(_vx_arrow, p0, p0 + Vector3(0.0, 0.0, v0.z) * 0.10)
		else:
			_vx_arrow.visible = false
	if _vy_arrow:
		if split:
			var vx_end := p0 + Vector3(0.0, 0.0, v0.z) * 0.10
			_position_arrow(_vy_arrow, vx_end, vx_end + Vector3(0.0, v0.y, 0.0) * 0.10)
		else:
			_vy_arrow.visible = false

	if _velocity_label:
		if split:
			_velocity_label.text = "vx = %.1f   vy = %.1f" % [v0.z, v0.y]
			_velocity_label.position = vel_end + Vector3(0.0, 0.12, 0.0)
			_velocity_label.visible = true
		elif show_velocity:
			_velocity_label.text = "v0 = %.1f m/s @ %d deg" % [_force, int(round(_angle_deg))]
			_velocity_label.position = vel_end + Vector3(0.0, 0.12, 0.0)
			_velocity_label.visible = true
		else:
			_velocity_label.visible = false

	# Gravity arrow: constant downward, fixed visual length, drawn near basket.
	var g_start := p0 + Vector3(0.25, 0.0, 0.0)
	var g_end := g_start + Vector3(0.0, -0.45, 0.0)
	if _gravity_arrow:
		if show_gravity:
			_position_arrow(_gravity_arrow, g_start, g_end)
		else:
			_gravity_arrow.visible = false
	if _gravity_label:
		if show_gravity:
			_gravity_label.text = "g = %.1f m/s^2" % gravity_magnitude
			_gravity_label.position = g_end + Vector3(0.0, -0.10, 0.0)
			_gravity_label.visible = true
		else:
			_gravity_label.visible = false


## Live prediction via p(t) = p0 + v0*t + 0.5*g*t^2 (local space). How much of
## that prediction is drawn is the `foresight` axis.
func _update_trajectory() -> void:
	if _trajectory_mesh == null:
		return
	_trajectory_mesh.clear_surfaces()
	if foresight == "none":
		return

	var p0 := _basket_local_position()
	var v0 := _launch_velocity()
	var g := Vector3(0.0, -gravity_magnitude, 0.0)

	# Floor in local space sits roughly at y = 0 (the machine base).
	var floor_y := 0.0

	_trajectory_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	match foresight:
		"apex":
			_emit_apex_marks(p0, v0, g)
		"landing":
			_emit_landing_ring(p0, v0, floor_y)
		_:
			_emit_dotted_arc(p0, v0, g, floor_y)
	_trajectory_mesh.surface_end()


func _emit_segment(a: Vector3, b: Vector3) -> void:
	_trajectory_mesh.surface_set_color(trajectory_color)
	_trajectory_mesh.surface_add_vertex(a)
	_trajectory_mesh.surface_set_color(trajectory_color)
	_trajectory_mesh.surface_add_vertex(b)


## The whole flight path, dotted: short LINE segments with gaps between samples.
func _emit_dotted_arc(p0: Vector3, v0: Vector3, g: Vector3, floor_y: float) -> void:
	var steps := 64
	var dt := 0.045
	var prev := p0
	var have_prev := false
	for i in range(1, steps + 1):
		var t := i * dt
		var pos := p0 + v0 * t + 0.5 * g * t * t
		var draw_segment := have_prev and (i % 2 == 0)  # skip every other = dotted
		if draw_segment:
			_emit_segment(prev, pos)
		prev = pos
		have_prev = true
		if pos.y <= floor_y and t > dt:
			break


## Only the summit: a launch tick at the basket and a cross at the peak.
func _emit_apex_marks(p0: Vector3, v0: Vector3, g: Vector3) -> void:
	var dir := v0.normalized()
	_emit_segment(p0, p0 + dir * 0.28)

	var t_apex: float = maxf(v0.y / maxf(gravity_magnitude, 0.001), 0.0)
	var apex: Vector3 = p0 + v0 * t_apex + 0.5 * g * t_apex * t_apex
	var s := 0.16
	_emit_segment(apex - Vector3(s, 0.0, 0.0), apex + Vector3(s, 0.0, 0.0))
	_emit_segment(apex - Vector3(0.0, s, 0.0), apex + Vector3(0.0, s, 0.0))
	_emit_segment(apex - Vector3(0.0, 0.0, s), apex + Vector3(0.0, 0.0, s))
	# A plumb line down from the peak so its height is readable against the floor.
	_emit_segment(apex, Vector3(apex.x, 0.0, apex.z))


## Only the impact: a ring on the floor where the stone will land.
func _emit_landing_ring(p0: Vector3, v0: Vector3, floor_y: float) -> void:
	var gm: float = maxf(gravity_magnitude, 0.001)
	var h: float = maxf(p0.y - floor_y, 0.0)
	var t_land: float = (v0.y + sqrt(maxf(v0.y * v0.y + 2.0 * gm * h, 0.0))) / gm
	var land := Vector3(p0.x + v0.x * t_land, floor_y, p0.z + v0.z * t_land)

	var radius := 0.35
	var segs := 28
	var prev := Vector3.ZERO
	for i in range(segs + 1):
		var a: float = TAU * float(i) / float(segs)
		var pt := land + Vector3(cos(a) * radius, 0.0, sin(a) * radius)
		if i > 0:
			_emit_segment(prev, pt)
		prev = pt
	# Crosshair inside the ring.
	_emit_segment(land - Vector3(radius, 0.0, 0.0), land + Vector3(radius, 0.0, 0.0))
	_emit_segment(land - Vector3(0.0, 0.0, radius), land + Vector3(0.0, 0.0, radius))


func _update_readout() -> void:
	if _readout_label == null:
		return
	var v0 := _launch_velocity()
	var vx := Vector2(v0.z, 0.0).length()  # horizontal component magnitude
	var vy := v0.y
	# Closed-form range over flat ground (launch ~ at basket height; informative).
	var a := deg_to_rad(_angle_deg)
	var range_flat: float = (_force * _force) * sin(2.0 * a) / maxf(gravity_magnitude, 0.001)
	_readout_label.text = "p(t) = p0 + v0*t + 0.5*g*t^2\nv0=%.1f m/s  angle=%d deg\nvx=%.1f  vy=%.1f  range~%.1f m" % [
		_force, int(round(_angle_deg)), vx, vy, range_flat]


# ═════════════════════════════════════════════════════════════════════════
# FIRE — arm swing + projectile launch
# ═════════════════════════════════════════════════════════════════════════

func _fire() -> void:
	if _is_firing:
		return
	_is_firing = true
	_fire_time = 0.0
	# Pull the arm back before the swing for a wind-up read.
	_rest_angle_offset = deg_to_rad(18.0)
	_apply_angle_to_arm()
	# Hide the cosmetic loaded ball during flight.
	_set_loaded_ball_visible(false)


func _advance_fire_swing(delta: float) -> void:
	_fire_time += delta
	var u: float = clamp(_fire_time / FIRE_SWING_DURATION, 0.0, 1.0)
	# Ease from wound-up (+offset) to release (offset 0) with a snappy curve.
	var eased: float = 1.0 - pow(1.0 - u, 3.0)
	_rest_angle_offset = deg_to_rad(18.0) * (1.0 - eased)
	_apply_angle_to_arm()

	if u >= 1.0:
		_is_firing = false
		_rest_angle_offset = 0.0
		_apply_angle_to_arm()
		_launch_projectile()
		_set_loaded_ball_visible(true)
		_refresh_visuals()


func _launch_projectile() -> void:
	_prune_projectiles()

	var ball := RigidBody3D.new()
	ball.name = "CatapultBall"
	ball.gravity_scale = gravity_magnitude / 9.8  # scale engine gravity to our g
	ball.contact_monitor = true
	ball.max_contacts_reported = 4
	ball.collision_layer = 16   # hazard-ish layer, won't fight world cubes
	ball.collision_mask = 1     # collide with the world/floor (layer 1)

	# Visual
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.07
	sphere.height = 0.14
	mesh.mesh = sphere
	mesh.material_override = _make_material(ball_color, 0.6, 0.5, 0.2)
	ball.add_child(mesh)

	# Collision
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.07
	col.shape = shape
	ball.add_child(col)

	# A small green velocity arrow riding the ball (mirrors turret bullet overlay).
	var ball_vel_arrow := _create_arrow("BallVelocity", velocity_arrow_color)
	ball.add_child(ball_vel_arrow)
	ball.set_meta("vel_arrow", ball_vel_arrow)

	# Place at basket (in container/local space) and give it the launch velocity.
	var spawn_local := _basket_local_position()
	_projectile_container.add_child(ball)
	ball.transform = Transform3D(Basis.IDENTITY, spawn_local)

	# Convert local launch velocity to world (rotation only — velocity is a free
	# vector, so we apply the basis, not the origin translation).
	var v0_local := _launch_velocity()
	var v0_world := global_transform.basis * v0_local
	ball.linear_velocity = v0_world

	fired.emit(v0_world)

	# Lifetime cleanup so projectiles don't accumulate.
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = projectile_lifetime
	ball.add_child(timer)
	timer.timeout.connect(ball.queue_free)
	timer.start()

	# Orient the riding arrow along the launch velocity once. The arrow stays
	# attached to the body and rotates with it during flight — acceptable for a
	# direction indicator without needing a per-projectile script.
	_orient_ball_arrow(ball, v0_world)


func _orient_ball_arrow(ball: RigidBody3D, v_world: Vector3) -> void:
	if not is_instance_valid(ball):
		return
	if not ball.has_meta("vel_arrow"):
		return
	var arrow: Node3D = ball.get_meta("vel_arrow")
	if arrow == null or not is_instance_valid(arrow):
		return
	# Arrow lives in ball-local space; express the velocity direction locally.
	var local_dir: Vector3 = ball.global_transform.basis.inverse() * v_world
	var dir: Vector3 = local_dir.normalized() * clampf(v_world.length() * 0.06, 0.15, 0.6)
	_position_arrow(arrow, Vector3.ZERO, dir)


## Remove the oldest live projectiles if we exceed the cap.
func _prune_projectiles() -> void:
	if _projectile_container == null:
		return
	var balls := _projectile_container.get_children()
	while balls.size() >= max_live_projectiles and balls.size() > 0:
		var oldest = balls[0]
		balls.remove_at(0)
		if is_instance_valid(oldest):
			oldest.queue_free()


func _set_loaded_ball_visible(v: bool) -> void:
	if _basket == null:
		return
	var loaded := _basket.get_node_or_null("LoadedBall")
	if loaded:
		loaded.visible = v


# ═════════════════════════════════════════════════════════════════════════
# UTILITIES
# ═════════════════════════════════════════════════════════════════════════

func _make_material(color: Color, emission_energy: float = 0.0,
		roughness: float = 0.6, metallic: float = 0.2) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_energy
	return mat


func _make_label(text: String, color: Color, font_size: int = 22) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.outline_size = max(2, font_size / 6)
	label.outline_modulate = Color.BLACK
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.0012
	label.no_depth_test = false
	return label


# ═════════════════════════════════════════════════════════════════════════
# GRID CONFIG
# ═════════════════════════════════════════════════════════════════════════

## Accept overrides from the map/grid system. Safe to call before or after _ready.
func apply_grid_config(config: Dictionary) -> void:
	if config.has("gravity"):
		gravity_magnitude = float(config["gravity"])
	if config.has("gravity_magnitude"):
		gravity_magnitude = float(config["gravity_magnitude"])
	if config.has("angle") or config.has("default_angle"):
		var a = config.get("angle", config.get("default_angle", default_angle_deg))
		default_angle_deg = float(a)
		_angle_deg = clamp(default_angle_deg, min_angle_deg, max_angle_deg)
	if config.has("force") or config.has("default_force"):
		var f = config.get("force", config.get("default_force", default_force))
		default_force = float(f)
		_force = clamp(default_force, min_force, max_force)
	if config.has("min_force"):
		min_force = float(config["min_force"])
	if config.has("max_force"):
		max_force = float(config["max_force"])
	if config.has("min_angle"):
		min_angle_deg = float(config["min_angle"])
	if config.has("max_angle"):
		max_angle_deg = float(config["max_angle"])
	if config.has("ball_color") and config["ball_color"] is Color:
		ball_color = config["ball_color"]
	if config.has("frame_color") and config["frame_color"] is Color:
		frame_color = config["frame_color"]
	if config.has("velocity_color") and config["velocity_color"] is Color:
		velocity_arrow_color = config["velocity_color"]
	if config.has("gravity_color") and config["gravity_color"] is Color:
		gravity_arrow_color = config["gravity_color"]
	if config.has("trajectory_color") and config["trajectory_color"] is Color:
		trajectory_color = config["trajectory_color"]

	# DNA axes. Only accept a value we actually know; an unknown string would
	# silently fall through to the default branch and publish a lie.
	if config.has("foresight"):
		var f: String = str(config["foresight"])
		if f in ["parabola", "apex", "landing", "none"]:
			foresight = f
	if config.has("vectors"):
		var vmode: String = str(config["vectors"])
		if vmode in ["sum", "components", "velocity", "gravity"]:
			vectors = vmode
	# `throw` is read after angle/force above, so an explicit #throw: wins over an
	# explicit #angle:/#force: in the same token. Unknown strings are dropped.
	var touched_raw_launch: bool = config.has("angle") or config.has("default_angle")
	if config.has("force") or config.has("default_force"):
		touched_raw_launch = true
	if config.has("throw"):
		var t: String = str(config["throw"])
		if t != throw and (t == "balanced" or THROWS.has(t)):
			throw = t
			_apply_throw()
	elif touched_raw_launch and THROWS.has(throw):
		# A named throw is already in force and this config only moved the raw
		# angle/force defaults; the branches above wrote them into _angle_deg /
		# _force, so put the throw back on top.
		_apply_throw()

	# If already built, push the new values into the live scene. This is a
	# redraw, not a rebuild — no node is freed and none is created unless the
	# `components` value asks for the two extra arrows.
	if is_inside_tree() and _arm_pivot != null:
		if _angle_slider and _angle_slider.has_method("set_range"):
			_angle_slider.set_range(min_angle_deg, max_angle_deg)
		if _force_slider and _force_slider.has_method("set_range"):
			_force_slider.set_range(min_force, max_force)
		if _angle_slider and _angle_slider.has_method("set_normalized_value"):
			_angle_slider.set_normalized_value(
				inverse_lerp(min_angle_deg, max_angle_deg, _angle_deg))
		if _force_slider and _force_slider.has_method("set_normalized_value"):
			_force_slider.set_normalized_value(
				inverse_lerp(min_force, max_force, _force))
		_apply_angle_to_arm()
		_refresh_visuals()
