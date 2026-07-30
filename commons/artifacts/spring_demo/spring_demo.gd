# spring_demo.gd
# Interactive Spring-Mass System demonstration
# Shows F = -kx (Hooke's Law) with physics simulation
# Sliders control Spring Constant (k), Mass, Damping
extends Node3D

class_name SpringDemo

## STAGE-2 DNA PROMOTION (2026-07-29). This artifact exposed only three NodePaths,
## so the sweep found NO TURNABLE KNOBS and declined it. Its own truth line says
## "Every oscillation in nature eventually damps — the question is how: ringing,
## critical, or sluggish" — and the shipped constants made exactly one of those three
## answers reachable. With k=10 and m=1, critical damping is c_crit = 2*sqrt(km) =
## 6.32, while the damping slider tops out at 2.0. The demo could only ever ring; the
## other two regimes it names were unreachable from inside itself.
##
## Two axes, both defaulting to the shipped behaviour exactly:
##
##   regime  which damped regime the demo OPENS in    ringing · underdamped · critical · overdamped
##   trace   whether the motion leaves a record       off · phase · wave
##
## regime works in damping RATIO (zeta = c / c_crit), not in raw c, so the regime
## survives a change of k or m — and when it is set it widens the damping slider's
## range so the state is holdable by hand instead of only settable from a map token.
## regime=ringing is a no-op and is the default, so the 7 existing placements keep
## c = 0.2 and their unchanged slider range of 0..2.
##
## trace renders the phase-space trail this script has ALWAYS collected into
## trail_points and never drawn — 300 samples of (x, v) accumulated every physics
## frame and thrown away. trace=phase draws the orbit that spirals into the origin;
## trace=wave draws x(t) trailing back in Z. trace=off is the default and builds no
## mesh at all, so nothing existing gains a child node.
##
## Usage in map_data.json:
##   "spring_demo#regime:critical"
##   "spring_demo#regime:overdamped#trace:phase"

## Slider paths

# @identity
# essence: m*a + c*v + k*x = 0 — damped harmonic oscillator with mass, spring, damper
# desire: Pull a mass on a spring with VR sliders and watch it oscillate, overdamp, or critically damp
# critical_parameter: damping_c — determines whether oscillation is underdamped, critical, or overdamped
# triggers: slider adjustment changes k, m, c in real-time; pull_and_release() sets initial displacement
# emerges: the three regimes of damped oscillation become physically intuitive through parameter control
# needs: VR sliders for k, m, c [has], pull interaction [has]
# relationships: depends on second-order ODE integration; contrasts with control_pendulum (spring vs gravity restoring force); unlocks damped oscillation regimes
# truth: Every oscillation in nature eventually damps — the question is how: ringing, critical, or sluggish.

@export var stiffness_slider_path: NodePath = "ControlPanel/StiffnessSlider"
@export var mass_slider_path: NodePath = "ControlPanel/MassSlider"
@export var damping_slider_path: NodePath = "ControlPanel/DampingSlider"

## --- DNA (stage 2, promoted 2026-07-29) ---

## Which regime of the damped oscillator the demo opens in, expressed as a damping
## RATIO so it survives changes to k and m. "ringing" leaves damping_c at its shipped
## 0.2 and touches nothing — that is the default.
@export_enum("ringing", "underdamped", "critical", "overdamped") var regime: String = "ringing"

## Whether the motion leaves a visible record. "off" is the shipped behaviour: the
## trail is collected and never drawn.
@export_enum("off", "phase", "wave") var trace: String = "off"

## zeta = c / c_crit for each named regime. "ringing" is absent on purpose: it means
## "leave the constant alone".
const REGIME_ZETA := {
	"underdamped": 0.30,
	"critical": 1.0,
	"overdamped": 2.2,
}

const TRACE_X := 0.9          # phase plot sits to the right of the mass
const TRACE_W := 0.28         # half-extent of the phase plot axes
const PHASE_X_SCALE := 0.45   # metres per unit displacement
const PHASE_V_SCALE := 0.14   # metres per unit velocity
const WAVE_STEP := 0.004      # metres of Z per stored sample

## Visual elements
@onready var mass_node: MeshInstance3D = $Mass
@onready var spring_mesh: MeshInstance3D = $SpringMesh
@onready var anchor: MeshInstance3D = $Anchor
@onready var formula_label: Label3D = $FormulaLabel
@onready var values_label: Label3D = $ValuesLabel
@onready var force_arrow: Node3D = $ForceArrow

## Sliders
var stiffness_slider
var mass_slider
var damping_slider

## Physics parameters
var spring_k: float = 10.0      # Spring constant (N/m)
var mass: float = 1.0           # Mass (kg)
var damping_c: float = 0.2      # Damping coefficient

## The damping slider's range. Shipped as 0..2 — which cannot reach c_crit=6.32 at the
## default k and m, so the demo could never be walked into critical damping by hand.
## regime widens this; regime=ringing leaves it exactly as it shipped.
var damping_min: float = 0.0
var damping_max: float = 2.0

## State
var position_y: float = 0.0     # Displacement from equilibrium
var velocity_y: float = 0.0     # Velocity
var rest_position: float = 0.0  # Equilibrium position
var initial_displacement: float = 0.5

## Spring visual
var spring_coils: int = 12
var spring_radius: float = 0.05

## Trail for phase space visualization
var trail_points: Array[Vector2] = []  # (position, velocity)
const MAX_TRAIL = 300

## Built lazily, and only when trace != "off".
var _trace_mesh: MeshInstance3D = null
var _built: bool = false

signal parameters_changed(k: float, m: float, c: float)

func _ready() -> void:
	_setup_sliders()
	_apply_regime()
	_rebuild_trace()
	_reset_simulation()
	_built = true

func _setup_sliders() -> void:
	stiffness_slider = get_node_or_null(stiffness_slider_path)
	if stiffness_slider:
		stiffness_slider.set_range(1.0, 50.0)
		stiffness_slider.set_param_name("k")
		stiffness_slider.set_normalized_value(0.2)
		stiffness_slider.slider_moved.connect(_on_stiffness_changed)
	
	mass_slider = get_node_or_null(mass_slider_path)
	if mass_slider:
		mass_slider.set_range(0.1, 5.0)
		mass_slider.set_param_name("MASS")
		mass_slider.set_normalized_value(0.2)
		mass_slider.slider_moved.connect(_on_mass_changed)
	
	damping_slider = get_node_or_null(damping_slider_path)
	if damping_slider:
		damping_slider.set_range(damping_min, damping_max)
		damping_slider.set_param_name("DAMP")
		damping_slider.set_normalized_value(0.1)
		damping_slider.slider_moved.connect(_on_damping_changed)


## regime → damping_c, in ratio terms. "ringing" is not in the table, so this returns
## having touched nothing: the shipped c = 0.2 and slider range 0..2 survive intact.
func _apply_regime() -> void:
	if not REGIME_ZETA.has(regime):
		return
	var zeta: float = float(REGIME_ZETA[regime])
	var c_crit: float = 2.0 * sqrt(spring_k * mass)
	damping_c = zeta * c_crit
	# The shipped slider stopped at 2.0, well short of c_crit. Once a regime is named,
	# open the range far enough that the whole regime space is reachable by hand.
	damping_max = max(2.0, c_crit * 2.5)
	if damping_slider:
		damping_slider.set_range(damping_min, damping_max)
		damping_slider.set_normalized_value(clamp(damping_c / max(damping_max, 0.0001), 0.0, 1.0))
	parameters_changed.emit(spring_k, mass, damping_c)

func _reset_simulation() -> void:
	position_y = initial_displacement
	velocity_y = 0.0
	trail_points.clear()

func _physics_process(delta: float) -> void:
	# Hooke's Law: F = -kx
	# With damping: F = -kx - cv
	# Newton: a = F/m
	
	var spring_force = -spring_k * position_y
	var damping_force = -damping_c * velocity_y
	var total_force = spring_force + damping_force
	var acceleration = total_force / mass
	
	# Euler integration (simple but stable enough for demo)
	velocity_y += acceleration * delta
	position_y += velocity_y * delta
	
	# Update visuals
	_update_mass_position()
	_update_spring_visual()
	_update_force_arrow(spring_force)
	_update_labels(spring_force, acceleration)
	_update_trail()

func _update_mass_position() -> void:
	if mass_node:
		mass_node.position.y = rest_position + position_y
		# Scale mass visual based on mass parameter
		var scale_factor = 0.5 + mass * 0.3
		mass_node.scale = Vector3.ONE * scale_factor

func _update_spring_visual() -> void:
	if not spring_mesh:
		return
	
	var mesh = ImmediateMesh.new()
	
	var anchor_y = 0.5  # Top anchor position
	var mass_y = rest_position + position_y
	var spring_length = anchor_y - mass_y
	
	# Need at least 2 points
	if spring_coils < 1:
		spring_mesh.mesh = mesh
		return
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	# Generate coil points
	var points_per_coil = 8
	var total_points = spring_coils * points_per_coil
	
	for i in range(total_points + 1):
		var t = float(i) / total_points
		var angle = t * spring_coils * TAU
		var y = anchor_y - t * spring_length
		var x = sin(angle) * spring_radius
		var z = cos(angle) * spring_radius
		
		# Color based on tension
		var tension = abs(position_y) / initial_displacement
		var color = Color(0.5 + tension * 0.5, 0.5, 0.5 - tension * 0.3)
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(Vector3(x, y, z))
	
	mesh.surface_end()
	spring_mesh.mesh = mesh

func _update_force_arrow(force: float) -> void:
	if not force_arrow:
		return
	
	# Arrow points in direction of force
	var arrow_scale = abs(force) * 0.05
	force_arrow.scale = Vector3(arrow_scale, arrow_scale, arrow_scale)
	force_arrow.position.y = rest_position + position_y
	
	# Flip arrow based on force direction
	if force > 0:
		force_arrow.rotation.z = 0
	else:
		force_arrow.rotation.z = PI

func _update_labels(force: float, accel: float) -> void:
	if formula_label:
		formula_label.text = "F = -kx - cv"
	
	if values_label:
		var omega = sqrt(spring_k / mass) if mass > 0 else 0
		var period = TAU / omega if omega > 0 else 0
		values_label.text = "k=%.1f  m=%.2f  c=%.2f\nx=%.3f  v=%.3f\nF=%.2f  T=%.2fs" % [
			spring_k, mass, damping_c, position_y, velocity_y, force, period
		]

func _update_trail() -> void:
	# Store phase space point (position vs velocity)
	trail_points.append(Vector2(position_y, velocity_y))
	if trail_points.size() > MAX_TRAIL:
		trail_points.pop_front()
	if _trace_mesh != null:
		_draw_trace()


## Create or destroy the trace mesh. trace=off builds nothing, so an unconfigured
## placement gains no child node at all.
func _rebuild_trace() -> void:
	if _trace_mesh != null and is_instance_valid(_trace_mesh):
		_trace_mesh.queue_free()
	_trace_mesh = null
	if trace == "off":
		return
	var mi := MeshInstance3D.new()
	mi.name = "TraceMesh"
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	add_child(mi)
	_trace_mesh = mi


## The record the trail has always kept and never shown.
## phase — the (x, v) orbit: an ellipse for a lossless spring, a spiral into the
##         origin once c > 0, a plain curve with no loop at all when overdamped.
## wave  — x(t) trailing back in Z, the shape a pen on moving paper would draw.
func _draw_trace() -> void:
	var n: int = trail_points.size()
	var mesh := ImmediateMesh.new()
	if n < 2:
		_trace_mesh.mesh = mesh
		return

	if trace == "phase":
		mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		mesh.surface_set_color(Color(0.35, 0.40, 0.48))
		mesh.surface_add_vertex(Vector3(TRACE_X - TRACE_W, rest_position, 0.0))
		mesh.surface_add_vertex(Vector3(TRACE_X + TRACE_W, rest_position, 0.0))
		mesh.surface_add_vertex(Vector3(TRACE_X, rest_position - TRACE_W, 0.0))
		mesh.surface_add_vertex(Vector3(TRACE_X, rest_position + TRACE_W, 0.0))
		mesh.surface_end()

	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(n):
		var p: Vector2 = trail_points[i]
		var age: float = float(i) / float(n - 1)
		mesh.surface_set_color(Color(0.30 + age * 0.65, 0.35 + age * 0.45, 0.95, 1.0))
		if trace == "phase":
			mesh.surface_add_vertex(Vector3(
				TRACE_X + p.x * PHASE_X_SCALE,
				rest_position + p.y * PHASE_V_SCALE,
				0.0))
		else:
			mesh.surface_add_vertex(Vector3(
				0.0,
				rest_position + p.x,
				-float(n - 1 - i) * WAVE_STEP))
	mesh.surface_end()
	_trace_mesh.mesh = mesh

# Slider callbacks

func _on_stiffness_changed(_value) -> void:
	if stiffness_slider:
		spring_k = lerp(1.0, 50.0, stiffness_slider.get_normalized_value())
		parameters_changed.emit(spring_k, mass, damping_c)

func _on_mass_changed(_value) -> void:
	if mass_slider:
		mass = lerp(0.1, 5.0, mass_slider.get_normalized_value())
		parameters_changed.emit(spring_k, mass, damping_c)

func _on_damping_changed(_value) -> void:
	if damping_slider:
		damping_c = lerp(damping_min, damping_max, damping_slider.get_normalized_value())
		parameters_changed.emit(spring_k, mass, damping_c)

# Public API

func reset() -> void:
	_reset_simulation()

func pull_and_release(displacement: float = 0.5) -> void:
	position_y = displacement
	velocity_y = 0.0
	trail_points.clear()

func get_natural_frequency() -> float:
	return sqrt(spring_k / mass) / TAU if mass > 0 else 0

func get_period() -> float:
	var omega = sqrt(spring_k / mass) if mass > 0 else 0
	return TAU / omega if omega > 0 else 0

func is_underdamped() -> bool:
	# Critical damping: c_crit = 2*sqrt(k*m)
	var c_crit = 2.0 * sqrt(spring_k * mass)
	return damping_c < c_crit

func apply_grid_config(config_data: Dictionary):
	# The grid calls this DEFERRED, i.e. after _ready has already built once, so any
	# reaction has to be guarded: rebuild only what actually changed, and only when
	# there is something built to rebuild.
	var was_regime: String = regime
	var was_trace: String = trace
	for key in config_data:
		if key in self:
			set(key, config_data[key])
	if not _built:
		return
	if regime != was_regime:
		_apply_regime()
		_reset_simulation()
	if trace != was_trace:
		_rebuild_trace()
