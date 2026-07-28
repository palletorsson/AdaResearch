extends Node3D
class_name ViscousFluidBlob

# @identity
# essence: a jelly cube on a bare plinth with a plate that presses it twice — once over four seconds, once in a seventh of a second — and the same material yields to the first and stops the second dead
# desire: to put the non-Newtonian claim in the motion instead of the caption; a still photograph of cornflour and water is just a bowl, and the sentence "it hardens when you hit it" is only believable at speed
# critical_parameter: thicken_gain — how far the constraint stiffness climbs with strain rate. At zero this is ordinary viscous jelly and the fast strike sinks straight through; at full it is a solid for exactly as long as you are quick
# triggers: _process measures mean particle speed each frame, maps it onto sim.stiffness and constraint_passes before stepping, then parks the plate on whatever height the blob managed to hold — so the plate's own position is the readout
# emerges: viscosity stops being a number and becomes a negotiation about timing. Nothing about the material changed between the two presses except how fast you asked
# needs: soft_body_shapes.make_jelly_box + soft_body_sim.gd [present — Verlet particles, all 28 pair springs]; to_node3d for the render [present]; a plinth with no tray and no lip, because the dressing room specifies posture pedestal
# relationships: the fast half of viscous_bench's argument — that bench turns stiffness down until soft becomes fluid and leaves it there; this one moves stiffness with the strain rate and shows the crossover happening in both directions
# truth: shear thickening is not a property of the substance. It is a property of the question, and the substance answers slowly.
# @qfep_term: Threshold — a material that changes category depending on how fast it is addressed.

## Pedestal artifact, 1x1x1. A low-stiffness, high-damping jelly box driven by
## the project's Verlet simulator, standing on a bare plinth. A press plate runs
## a slow-then-fast cycle; effective stiffness is recomputed from strain rate
## each frame, so the blob flows under the slow press and refuses the fast one.

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")
const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"

# --- geometry -------------------------------------------------------------
const PLINTH_W := 0.34
const PLINTH_TOP := 0.48
const PARTICLE_R := 0.085
const PLATE_W := 0.36
const PLATE_THICK := 0.03
## How much of the plate's overlap is transferred to a particle in one frame.
## Below 1.0 the plate pushes rather than teleports, so the springs get a say.
const PLATE_GRIP := 0.55

# --- the cycle, in seconds ------------------------------------------------
const CYCLE := 9.0
const SLOW_START := 1.0
const SLOW_END := 5.0
const SLOW_LIFT := 6.0
const FAST_START := 6.9
const FAST_END := 7.05
const FAST_HOLD := 7.45

# --- knobs ----------------------------------------------------------------
## Edge of the jelly box, in metres.
@export var blob_size: float = 0.26
## Constraint stiffness at rest. Low enough that the box does not hold its shape.
@export var base_stiffness: float = 0.10
## Constraint stiffness at full strain rate. This is the shear-thickened solid.
@export var thick_stiffness: float = 0.94
## How far stiffness is allowed to climb, 0..1. At 0 the artifact is honest
## viscous jelly and the fast strike goes straight through it.
@export var thicken_gain: float = 1.0
## Mean particle speed (m/s) that counts as "full rate". Above this, solid.
@export var rate_reference: float = 0.55
## Verlet velocity retention. 1.0 is lossless; 0.86 loses 14% of the velocity
## every step, which is what makes it settle slowly instead of springing.
@export var damping: float = 0.86
## Weakened gravity — a viscous body under 9.8 splatters before it reads.
@export var gravity_y: float = -3.2
@export var blob_color: Color = Color(0.94, 0.66, 0.20)

var _sim = null
var _blob_root: Node3D = null
var _particle_mm: MultiMesh = null
var _wire_mesh: ImmediateMesh = null
var _wire_mat: StandardMaterial3D = null
var _plate: MeshInstance3D = null
var _readout: Label3D = null

var _t: float = 0.0
var _plate_y: float = 0.0
var _rate: float = 0.0
var _stiff: float = 0.0
var _built := false
var _created: Array[Node] = []


func _ready() -> void:
	_build_all()
	_built = true
	set_process(true)


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

func _own(n: Node) -> Node:
	_created.append(n)
	add_child(n)
	return n


func _build_all() -> void:
	_build_plinth()
	_build_blob()
	_build_plate()
	_build_readout()
	_plate_y = _hover_y()


## A plinth and nothing else. No tray, no lip, no bench top — the dressing room
## calls this posture pedestal, and a tray would make it a demonstration bench.
func _build_plinth() -> void:
	var column := MeshInstance3D.new()
	column.name = "Plinth"
	var box := BoxMesh.new()
	box.size = Vector3(PLINTH_W, PLINTH_TOP, PLINTH_W)
	column.mesh = box
	column.position = Vector3(0.0, PLINTH_TOP * 0.5, 0.0)
	column.material_override = _grid_material(Color(0.19, 0.20, 0.24), Color(0.40, 0.45, 0.55), 0.4)
	_own(column)

	var cap := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(PLINTH_W + 0.05, 0.025, PLINTH_W + 0.05)
	cap.mesh = cm
	cap.position = Vector3(0.0, PLINTH_TOP - 0.0125, 0.0)
	cap.material_override = _grid_material(Color(0.26, 0.27, 0.31), Color(0.55, 0.60, 0.70), 0.6)
	_own(cap)


## The jelly box, straight from the project's factory: 8 corner particles, all
## 28 pair springs, stiffness turned right down. Pre-settled so the artifact is
## already a slumped blob when the room first sees it, not a tidy cube.
func _build_blob() -> void:
	var size: float = clampf(blob_size, 0.14, 0.4)
	_sim = SBShapes.make_jelly_box(size, base_stiffness, Vector3(0.0, PLINTH_TOP, 0.0))
	_sim.gravity = Vector3(0.0, gravity_y, 0.0)
	_sim.damping = clampf(damping, 0.6, 0.999)
	_sim.floor_y = PLINTH_TOP + PARTICLE_R
	_sim.constraint_passes = 4
	for _i in 90:
		_sim.step()

	_blob_root = SBShapes.to_node3d(_sim, {
		"color": [blob_color.r, blob_color.g, blob_color.b],
		"show_wires": true,
		"wire_color": [0.55, 0.30, 0.06],
		"roughness": 0.2,
		"particle_radius": PARTICLE_R,
	})
	_own(_blob_root)
	_capture_render_handles()
	_refresh_render()


## to_node3d hands back a plain Node3D; find the pieces by type rather than by
## index, so a change in the renderer's child order cannot silently stop this.
func _capture_render_handles() -> void:
	_particle_mm = null
	_wire_mesh = null
	for child in _blob_root.get_children():
		if child is MultiMeshInstance3D:
			_particle_mm = (child as MultiMeshInstance3D).multimesh
			var pm := StandardMaterial3D.new()
			pm.albedo_color = blob_color
			pm.roughness = 0.18
			pm.metallic = 0.15
			pm.emission_enabled = true
			pm.emission = blob_color
			pm.emission_energy_multiplier = 0.35
			(child as MultiMeshInstance3D).material_override = pm
		elif child is MeshInstance3D:
			# The spring wires. Rebuilt every frame — the renderer bakes them
			# once, which would leave the struts standing where the blob was.
			_wire_mesh = ImmediateMesh.new()
			(child as MeshInstance3D).mesh = _wire_mesh
			_wire_mat = StandardMaterial3D.new()
			_wire_mat.albedo_color = Color(0.62, 0.34, 0.08)
			_wire_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


func _build_plate() -> void:
	_plate = MeshInstance3D.new()
	_plate.name = "PressPlate"
	var box := BoxMesh.new()
	box.size = Vector3(PLATE_W, PLATE_THICK, PLATE_W)
	_plate.mesh = box
	_plate.material_override = _grid_material(Color(0.46, 0.50, 0.58), Color(0.75, 0.85, 1.0), 1.2)
	_own(_plate)


func _build_readout() -> void:
	_readout = Label3D.new()
	_readout.text = "RATE 0.00 m/s    STIFFNESS 0.10"
	_readout.font_size = 20
	_readout.outline_size = 5
	_readout.modulate = Color(0.95, 0.86, 0.66)
	_readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_readout.position = Vector3(0.0, 1.14, 0.0)
	_own(_readout)

	var claim := Label3D.new()
	claim.text = "press slowly and it flows — strike it and it is a solid"
	claim.font_size = 14
	claim.outline_size = 4
	claim.modulate = Color(0.72, 0.78, 0.90)
	claim.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	claim.position = Vector3(0.0, 1.02, 0.0)
	_own(claim)


# ═══════════════════════════════════════════════════════════════════
# THE NEGOTIATION
# ═══════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _sim == null:
		return
	var dt: float = clampf(delta, 0.004, 0.05)
	_t = fmod(_t + dt, CYCLE)

	var target: float = _plate_target()
	_press(target)

	# Strain rate FIRST, from the displacement the last step actually produced,
	# then stiffness from the rate. The material is asked how fast it is being
	# deformed and answers before the next step is solved — which is the whole
	# mechanism, and it is one line of feedback, not a special case for "fast".
	_rate = _strain_rate(dt)
	var f: float = clampf(_rate / maxf(rate_reference, 0.01), 0.0, 1.0) * clampf(thicken_gain, 0.0, 1.0)
	_stiff = base_stiffness + (thick_stiffness - base_stiffness) * f
	_sim.stiffness = _stiff
	_sim.constraint_passes = 2 + int(round(6.0 * f))
	_sim.step()

	# The plate rides on whatever the blob managed to hold. Under the slow press
	# the top follows it down; under the strike the top barely moves and the
	# plate is stopped in mid-air with nothing but timing holding it up.
	_plate_y = maxf(target, _blob_top() + PLATE_THICK * 0.5 + 0.004)
	_plate.position = Vector3(0.0, _plate_y, 0.0)

	_refresh_render()
	if _readout != null:
		_readout.text = "RATE %.2f m/s    STIFFNESS %.2f" % [_rate, _stiff]


## The drive. Both presses go to exactly the same depth; only the duration
## differs — four seconds against fifteen hundredths.
func _plate_target() -> float:
	var hover: float = _hover_y()
	var deep: float = PLINTH_TOP + 0.11
	if _t < SLOW_START:
		return hover
	if _t < SLOW_END:
		var a: float = (_t - SLOW_START) / (SLOW_END - SLOW_START)
		return hover + (deep - hover) * a
	if _t < SLOW_LIFT:
		var b: float = (_t - SLOW_END) / (SLOW_LIFT - SLOW_END)
		return deep + (hover - deep) * b
	if _t < FAST_START:
		return hover
	if _t < FAST_END:
		var c: float = (_t - FAST_START) / (FAST_END - FAST_START)
		return hover + (deep - hover) * c
	if _t < FAST_HOLD:
		return deep
	var d: float = (_t - FAST_HOLD) / maxf(CYCLE - FAST_HOLD, 0.01)
	return deep + (hover - deep) * d


func _hover_y() -> float:
	return PLINTH_TOP + clampf(blob_size, 0.14, 0.4) * 1.5 + PARTICLE_R + 0.05


## Push, do not teleport. Every particle poking through the plate is moved down
## by a fraction of the overlap, and the constraint solver then decides how much
## of that the body accepts.
func _press(plate_center_y: float) -> void:
	var bottom: float = plate_center_y - PLATE_THICK * 0.5
	for i in _sim.positions.size():
		var top: float = _sim.positions[i].y + PARTICLE_R
		if top > bottom:
			_sim.positions[i].y -= (top - bottom) * PLATE_GRIP


## Mean particle speed, from the Verlet displacement of the previous step. This
## is the strain rate the material reads itself by.
func _strain_rate(dt: float) -> float:
	var n: int = _sim.positions.size()
	if n == 0:
		return 0.0
	var total: float = 0.0
	for i in n:
		var d: Vector3 = _sim.positions[i] - _sim.prev_positions[i]
		total += d.length()
	return (total / float(n)) / dt


func _blob_top() -> float:
	var top: float = PLINTH_TOP
	for i in _sim.positions.size():
		var y: float = _sim.positions[i].y + PARTICLE_R
		if y > top:
			top = y
	return top


func _refresh_render() -> void:
	if _particle_mm != null:
		for i in _sim.positions.size():
			var t := Transform3D.IDENTITY
			t.origin = _sim.positions[i]
			_particle_mm.set_instance_transform(i, t)
	if _wire_mesh != null and _wire_mat != null:
		_wire_mesh.clear_surfaces()
		_wire_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _wire_mat)
		for s in _sim.springs:
			_wire_mesh.surface_add_vertex(_sim.positions[int(s[0])])
			_wire_mesh.surface_add_vertex(_sim.positions[int(s[1])])
		_wire_mesh.surface_end()


# ═══════════════════════════════════════════════════════════════════
# MATERIAL / CONFIG
# ═══════════════════════════════════════════════════════════════════

func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("modelOpacity", 1.0)
		m.set_shader_parameter("wireframeOpacity", 1.0)
		m.set_shader_parameter("globalOpacity", 1.0)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.35
	return fallback


func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_sim = null
	_blob_root = null
	_particle_mm = null
	_wire_mesh = null
	_plate = null
	_readout = null
	_t = 0.0
	_build_all()


## Grid config. Keys: "blob_size", "base_stiffness", "thick_stiffness",
## "thicken_gain", "rate_reference", "damping", "gravity_y", "blob_color".
func apply_grid_config(config_data: Dictionary) -> void:
	var before_size: float = blob_size
	var before_base: float = base_stiffness
	var before_thick: float = thick_stiffness
	var before_gain: float = thicken_gain
	var before_damp: float = damping
	var before_grav: float = gravity_y

	if config_data.has("blob_size"):
		blob_size = clampf(float(config_data["blob_size"]), 0.14, 0.4)
	if config_data.has("base_stiffness"):
		base_stiffness = clampf(float(config_data["base_stiffness"]), 0.03, 0.5)
	if config_data.has("thick_stiffness"):
		thick_stiffness = clampf(float(config_data["thick_stiffness"]), 0.2, 0.99)
	if config_data.has("thicken_gain"):
		thicken_gain = clampf(float(config_data["thicken_gain"]), 0.0, 1.0)
	if config_data.has("rate_reference"):
		rate_reference = clampf(float(config_data["rate_reference"]), 0.05, 4.0)
	if config_data.has("damping"):
		damping = clampf(float(config_data["damping"]), 0.6, 0.999)
	if config_data.has("gravity_y"):
		gravity_y = clampf(float(config_data["gravity_y"]), -12.0, -0.2)
	if config_data.has("blob_color") and config_data["blob_color"] is String:
		blob_color = Color(str(config_data["blob_color"]))

	if not _built:
		return
	if (is_equal_approx(blob_size, before_size)
			and is_equal_approx(base_stiffness, before_base)
			and is_equal_approx(thick_stiffness, before_thick)
			and is_equal_approx(thicken_gain, before_gain)
			and is_equal_approx(damping, before_damp)
			and is_equal_approx(gravity_y, before_grav)):
		# rate_reference is read live every frame; nothing structural moved. And a
		# curation pass hands every artifact {"emissive": false} — rebuilding on
		# that would throw its framing away.
		return

	_rebuild_now()
	print("[ViscousFluidBlob] Config applied — size=%.2f, stiffness %.2f..%.2f, gain=%.2f, damping=%.3f" % [
		blob_size, base_stiffness, thick_stiffness, thicken_gain, damping])
