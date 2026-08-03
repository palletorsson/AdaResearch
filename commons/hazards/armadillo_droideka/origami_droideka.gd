# @identity
# essence: inflate(t) = f(state, speed, pulse) — Kresling-inspired shell that breathes between compact wheel and deployed turret
# desire: a folding origami wheel that rolls toward you, inflates to reveal a firing core, then collapses to relocate
# critical_parameter: inflation_fire_bias — how compressed the shell stays during FIRE state, exposing or protecting the core
# triggers: state machine (ROLL→DETECT→DEPLOY→AIM→FIRE→DEAD) drives fold/inflate pose via _apply_fold_pose()
# emerges: split-face dihedral animation creates a breathing, organic quality from rigid box geometry
# needs: inherited armadillo_droideka base [has]; fire_bolt projectile [has]; pleat/split face system [has]
# relationships: extends armadillo_droideka; contrasts with armadillo_eggling (full combat vs contact-only); feeds random_game gauntlet
# truth: Origami is constraint that enables transformation — the same sheet becomes wheel, turret, and shield.

extends "res://commons/hazards/armadillo_droideka/armadillo_droideka.gd"
class_name OrigamiDroideka

@export_group("Origami Inflation")
@export var inflation_enabled: bool = true
@export var inflation_speed: float = 0.12
@export var inflation_amplitude: float = 0.12
@export var inflation_min_scale: float = 0.72
@export var inflation_fire_bias: float = 0.28
@export var inflated_radius_scale: float = 1.24
@export var deflated_radius_scale: float = 0.56
@export var inflated_thickness_scale: float = 0.74
@export var deflated_thickness_scale: float = 0.20
@export var pleat_fold_degrees: float = 68.0
@export var pleat_twist_degrees: float = 34.0
@export var aperture_open_scale: float = 1.0
@export var aperture_closed_scale: float = 0.34
@export var outer_collar_closed_scale: float = 0.78
@export var split_faces_enabled: bool = true
@export var split_closed_dihedral_degrees: float = 56.0
@export var split_open_dihedral_degrees: float = 4.0
@export var split_jitter_degrees: float = 3.2

## AXIS — WARNING: how much the hazard tells you BEFORE it costs you anything.
## Adopted word for word from [[miura_crawler]], [[scissor_stalker]],
## [[kaleidocycle_enemy]] and [[path_block]] — one vocabulary across the hazards,
## so the family measures on one scale instead of five private synonyms.
##
## The droideka is the family's LOUD case, and that is exactly why the axis is
## worth asking here. It is a metre-and-a-half pleated wheel with an orange core
## and eighteen breathing pleats: it is already unmissable, so anything the room
## adds is not information, it is INSTITUTION — somebody decided this thing needed
## a fence, a lamp or a tarpaulin, and the decision is legible.
##
##   none    the wheel alone, unannounced — THE LEGACY BODY, byte for byte. Pale
##           green pleats, an orange collar, a lit core at the hub.
##   stain   a rolled rut in the ground beneath it, running the length of its
##           approach: a long dark track, a darker centre worn into it, and two
##           smears where it slewed. The floor remembers the weight.
##   cage    a bolted post-and-rail crate hugging the wheel's thin axis, plus a
##           filed yellow tag. Somebody catalogued it and fenced it, and it rolls
##           and fires on exactly the same schedule inside the bars.
##   beacon  a lit mast beside the hub with a lamp head and a shade, plus a glowing
##           outline burnt into the floor around the wheel's footprint.
##   shroud  a fitted canvas cover over the whole wheel with a ridged top and two
##           straps. The pleats, the collar and the lit core — everything that read
##           as a machine — go under cloth. It rolls out from under it unchanged.
##
## APPEARANCE ONLY. contact_damage, fire_damage, shots_per_burst, fire_interval,
## roll_speed, detection_radius, max_health, the inflation schedule and the
## collision/hurtbox are byte-identical across all five values. A hazard that hides
## itself is not a gentler hazard.
const WARNING_VALUES: PackedStringArray = ["none", "stain", "cage", "beacon", "shroud"]
@export_enum("none", "stain", "cage", "beacon", "shroud") var warning: String = "none"

## FIXTURE, not an axis. The inherited base calls _rng.randomize() in its _ready, so
## every droideka that has ever spawned drew its DETECT-state sway from a different
## stream. -1 keeps precisely that (randomize as before, unchanged for all 7 live
## placements); any value >= 0 pins the stream so a sweep measures the axis and not
## the noise.
@export var rng_seed: int = -1

var _inner_ring_top: MeshInstance3D = null
var _inner_ring_bottom: MeshInstance3D = null
var _outer_ring_top: MeshInstance3D = null
var _outer_ring_bottom: MeshInstance3D = null
var _split_left_hinges: Array[Node3D] = []
var _split_right_hinges: Array[Node3D] = []

func _ready() -> void:
	max_health = 92.0
	roll_speed = 2.55
	strafe_speed = 1.95
	turn_speed = 6.4
	detection_radius = 11.5
	disengage_radius = 17.0
	shots_per_burst = 4
	fire_interval = 0.31
	fire_speed = 15.5
	fire_damage = 16.0
	contact_damage = 10.0
	contact_damage_cooldown = 0.58

	# 16-20 radial pleats approximates the wheel shown in your reference.
	scute_count = 18
	shell_radius = 0.66
	shell_height = 0.96
	shell_thickness = 0.06
	scute_open_degrees = 84.0
	scute_wave_degrees = 14.0
	ring_open_degrees = 64.0
	core_raise_height = 0.58

	super._ready()
	# Pin the inherited jitter stream only when asked. -1 is the shipped behaviour:
	# the base already randomized it and this line does nothing.
	if rng_seed >= 0:
		_rng.seed = rng_seed
	add_to_group("origami_enemy")
	# WARNING dressing, appended LAST so the collision body, the hurtbox and the shell
	# root keep their child indices. "none" adds nothing at all — the legacy lineage.
	_build_warning()

func _build_visual_rig() -> void:
	var shell_material: StandardMaterial3D = _make_material(
		Color(0.60, 0.90, 0.82, 1.0),
		Color(0.08, 0.28, 0.24, 1.0),
		0.12,
		0.62
	)
	var ring_material: StandardMaterial3D = _make_material(
		Color(0.68, 0.84, 0.78, 1.0),
		Color(0.96, 0.43, 0.14, 1.0),
		0.34,
		0.44
	)
	var core_material: StandardMaterial3D = _make_material(
		Color(0.17, 0.17, 0.2, 1.0),
		Color(1.0, 0.33, 0.08, 1.0),
		0.35,
		0.55
	)

	_shell_root = Node3D.new()
	_shell_root.name = "ShellRoot"
	add_child(_shell_root)

	_create_scutes(shell_material)
	_create_equator_rings(ring_material)
	_create_leg_modules(ring_material)
	_create_core(core_material, ring_material)

func _create_scutes(shell_material: Material) -> void:
	_scute_hinges.clear()
	_split_left_hinges.clear()
	_split_right_hinges.clear()
	var count: int = max(14, scute_count)
	var rib_material: StandardMaterial3D = _make_material(
		Color(0.95, 0.96, 0.92, 1.0),
		Color(0.35, 0.37, 0.30, 1.0),
		0.06,
		0.45
	)

	var inner_mesh: BoxMesh = BoxMesh.new()
	inner_mesh.size = Vector3(shell_radius * 0.54, shell_thickness * 0.40, shell_thickness * 1.45)

	var outer_mesh: BoxMesh = BoxMesh.new()
	outer_mesh.size = Vector3(shell_radius * 0.86, shell_thickness * 0.45, shell_thickness * 1.58)

	var rib_mesh: BoxMesh = BoxMesh.new()
	rib_mesh.size = Vector3(shell_radius * 0.80, shell_thickness * 0.09, shell_thickness * 1.66)
	var split_mesh: BoxMesh = BoxMesh.new()
	split_mesh.size = Vector3(shell_radius * 0.86, shell_thickness * 0.45, shell_thickness * 0.80)

	for i in range(count):
		var orbit: Node3D = Node3D.new()
		orbit.name = "ScuteOrbit_%d" % i
		orbit.rotation_degrees.z = 360.0 * float(i) / float(count)
		_shell_root.add_child(orbit)

		var hinge: Node3D = Node3D.new()
		hinge.name = "ScuteHinge_%d" % i
		orbit.add_child(hinge)

		var inner_panel: MeshInstance3D = MeshInstance3D.new()
		inner_panel.name = "OrigamiInnerPanel"
		inner_panel.mesh = inner_mesh
		inner_panel.material_override = shell_material
		inner_panel.position = Vector3(shell_radius * 0.23, 0.0, 0.0)
		inner_panel.rotation_degrees.z = -3.0
		hinge.add_child(inner_panel)

		if split_faces_enabled:
			var split_root: Node3D = Node3D.new()
			split_root.name = "SplitFaceRoot"
			split_root.position = Vector3(shell_radius * 0.68, 0.0, 0.0)
			split_root.rotation_degrees.z = 2.0
			hinge.add_child(split_root)

			var left_hinge: Node3D = Node3D.new()
			left_hinge.name = "SplitLeftHinge"
			split_root.add_child(left_hinge)

			var right_hinge: Node3D = Node3D.new()
			right_hinge.name = "SplitRightHinge"
			split_root.add_child(right_hinge)

			var left_panel: MeshInstance3D = MeshInstance3D.new()
			left_panel.name = "OrigamiOuterPanelLeft"
			left_panel.mesh = split_mesh
			left_panel.material_override = shell_material
			left_panel.position = Vector3(0.0, 0.0, -split_mesh.size.z * 0.5)
			left_hinge.add_child(left_panel)

			var right_panel: MeshInstance3D = MeshInstance3D.new()
			right_panel.name = "OrigamiOuterPanelRight"
			right_panel.mesh = split_mesh
			right_panel.material_override = shell_material
			right_panel.position = Vector3(0.0, 0.0, split_mesh.size.z * 0.5)
			right_hinge.add_child(right_panel)

			var seam_rib: MeshInstance3D = MeshInstance3D.new()
			seam_rib.name = "OrigamiSeamRib"
			var seam_mesh: BoxMesh = BoxMesh.new()
			seam_mesh.size = Vector3(shell_radius * 0.88, shell_thickness * 0.10, shell_thickness * 0.18)
			seam_rib.mesh = seam_mesh
			seam_rib.material_override = rib_material
			split_root.add_child(seam_rib)

			_split_left_hinges.append(left_hinge)
			_split_right_hinges.append(right_hinge)
		else:
			var outer_panel: MeshInstance3D = MeshInstance3D.new()
			outer_panel.name = "OrigamiOuterPanel"
			outer_panel.mesh = outer_mesh
			outer_panel.material_override = shell_material
			outer_panel.position = Vector3(shell_radius * 0.68, 0.0, 0.0)
			outer_panel.rotation_degrees.z = 2.0
			hinge.add_child(outer_panel)

		var rib: MeshInstance3D = MeshInstance3D.new()
		rib.name = "OrigamiRib"
		rib.mesh = rib_mesh
		rib.material_override = rib_material
		rib.position = Vector3(shell_radius * 0.62, shell_thickness * 0.15, shell_thickness * 0.03)
		hinge.add_child(rib)

		_scute_hinges.append(hinge)

func _create_equator_rings(material: Material) -> void:
	_equator_upper = Node3D.new()
	_equator_upper.name = "EquatorUpper"
	_shell_root.add_child(_equator_upper)

	_equator_lower = Node3D.new()
	_equator_lower.name = "EquatorLower"
	_shell_root.add_child(_equator_lower)

	# Inner aperture ring (hole seen in the wheel reference).
	_inner_ring_top = _create_torus_ring(shell_radius * 0.21, shell_thickness * 0.42, material)
	_inner_ring_bottom = _create_torus_ring(shell_radius * 0.21, shell_thickness * 0.42, material)
	_inner_ring_top.rotation_degrees.x = 90.0
	_inner_ring_bottom.rotation_degrees.x = 90.0
	_equator_upper.add_child(_inner_ring_top)
	_equator_lower.add_child(_inner_ring_bottom)
	_inner_ring_top.position.z = shell_thickness * 0.42
	_inner_ring_bottom.position.z = -shell_thickness * 0.42

	# Outer collar ring to frame pleat ends.
	_outer_ring_top = _create_torus_ring(shell_radius * 0.94, shell_thickness * 0.22, material)
	_outer_ring_bottom = _create_torus_ring(shell_radius * 0.94, shell_thickness * 0.22, material)
	_outer_ring_top.rotation_degrees.x = 90.0
	_outer_ring_bottom.rotation_degrees.x = 90.0
	_equator_upper.add_child(_outer_ring_top)
	_equator_lower.add_child(_outer_ring_bottom)
	_outer_ring_top.position.z = shell_thickness * 0.72
	_outer_ring_bottom.position.z = -shell_thickness * 0.72

func _apply_fold_pose(fold: float) -> void:
	super._apply_fold_pose(fold)

	if _shell_root == null:
		return

	var fold_clamped: float = clamp(fold, 0.0, 1.0)
	var roll_bias: float = 1.0 - fold_clamped
	var planar_speed: float = Vector2(velocity.x, velocity.z).length()
	var speed_ratio: float = clamp(planar_speed / max(roll_speed, 0.01), 0.0, 1.6)
	var load: float = clamp(speed_ratio * 0.16, 0.0, 0.22) * roll_bias

	var target_inflate: float = clamp((1.0 - fold_clamped) * 0.75 + 0.2, 0.0, 1.0)
	match _state:
		State.ROLL:
			target_inflate = max(target_inflate, 0.82)
		State.DETECT:
			target_inflate = clamp(target_inflate, 0.55, 0.72)
		State.DEPLOY:
			target_inflate = clamp(target_inflate, 0.42, 0.66)
		State.AIM, State.FIRE:
			target_inflate = clamp(inflation_fire_bias, 0.05, 0.75)
		State.DEAD:
			target_inflate = 0.12
		_:
			pass

	var pulse: float = 0.0
	if inflation_enabled:
		var phase_speed: float = max(0.02, inflation_speed)
		var raw_pulse: float = sin(_state_time * TAU * phase_speed)
		var pulse_weight: float = clamp(0.35 + roll_bias * 0.65, 0.0, 1.0)
		pulse = raw_pulse * inflation_amplitude * pulse_weight

	var inflate: float = clamp(target_inflate + pulse - load * 0.20, 0.02, 1.0)

	# Inflate/deflate profile: wheel expands radially while thickness collapses/expands.
	var radius_scale: float = lerp(deflated_radius_scale, inflated_radius_scale, inflate)
	var thickness_scale: float = lerp(deflated_thickness_scale, inflated_thickness_scale, inflate)
	radius_scale += load * 0.18
	thickness_scale -= load * 0.22
	thickness_scale = max(inflation_min_scale * 0.25, thickness_scale)
	_shell_root.scale = Vector3(radius_scale, radius_scale, thickness_scale)

	# Offset rings so the center aperture remains visible through compression.
	if _equator_upper:
		_equator_upper.position.z = shell_thickness * (0.42 + (1.0 - inflate) * 0.44)
		_equator_upper.rotation_degrees.x = -lerp(4.0, 24.0, 1.0 - inflate)
	if _equator_lower:
		_equator_lower.position.z = -shell_thickness * (0.42 + (1.0 - inflate) * 0.44)
		_equator_lower.rotation_degrees.x = lerp(4.0, 24.0, 1.0 - inflate)

	var aperture_scale: float = lerp(aperture_closed_scale, aperture_open_scale, inflate)
	if _inner_ring_top:
		_inner_ring_top.scale.x = aperture_scale
		_inner_ring_top.scale.y = aperture_scale
	if _inner_ring_bottom:
		_inner_ring_bottom.scale.x = aperture_scale
		_inner_ring_bottom.scale.y = aperture_scale

	var collar_scale: float = lerp(outer_collar_closed_scale, 1.0, inflate)
	if _outer_ring_top:
		_outer_ring_top.scale.x = collar_scale
		_outer_ring_top.scale.y = collar_scale
	if _outer_ring_bottom:
		_outer_ring_bottom.scale.x = collar_scale
		_outer_ring_bottom.scale.y = collar_scale

	var scute_total: int = _scute_hinges.size()
	for i in range(scute_total):
		var hinge: Node3D = _scute_hinges[i]
		var phase: float = TAU * float(i) / float(max(scute_total, 1))
		var parity: float = 1.0 if (i % 2 == 0) else -1.0
		var accordion: float = lerp(pleat_fold_degrees, 4.0, inflate)
		var twist: float = lerp(pleat_twist_degrees, 6.0, inflate)
		var micro_wave: float = sin(_state_time * 0.8 + phase * 2.0) * 1.9 * (1.0 - inflate)

		hinge.rotation_degrees.y = parity * (accordion + micro_wave)
		hinge.rotation_degrees.x = parity * twist * 0.5
		hinge.rotation_degrees.z = sin(phase + _state_time * 0.21) * (3.5 * (1.0 - inflate))

		var radial_length_scale: float = lerp(0.38, 1.08, inflate)
		var width_scale: float = lerp(0.80, 1.0, inflate)
		var panel_thickness_scale: float = lerp(0.68, 1.0, inflate)
		var split_dihedral: float = lerp(split_closed_dihedral_degrees, split_open_dihedral_degrees, inflate)
		var split_jitter: float = sin(_state_time * 0.52 + phase * 3.0) * split_jitter_degrees * (1.0 - inflate)

		if i < _split_left_hinges.size() and i < _split_right_hinges.size():
			_split_left_hinges[i].rotation_degrees.x = -0.5 * (split_dihedral + split_jitter)
			_split_right_hinges[i].rotation_degrees.x = 0.5 * (split_dihedral + split_jitter)

		for child in hinge.get_children():
			if child is MeshInstance3D:
				var mesh_child: MeshInstance3D = child as MeshInstance3D
				mesh_child.scale.x = radial_length_scale
				mesh_child.scale.y = width_scale
				mesh_child.scale.z = panel_thickness_scale
			elif child is Node3D:
				var node_child: Node3D = child as Node3D
				for grandchild in node_child.get_children():
					if grandchild is MeshInstance3D:
						var mesh_grandchild: MeshInstance3D = grandchild as MeshInstance3D
						mesh_grandchild.scale.x = radial_length_scale
						mesh_grandchild.scale.y = width_scale
						mesh_grandchild.scale.z = panel_thickness_scale

func _rebuild_visual_rig() -> void:
	if _shell_root:
		remove_child(_shell_root)
		_shell_root.queue_free()
		_shell_root = null

	_scute_hinges.clear()
	_leg_hips.clear()
	_leg_knees.clear()
	_split_left_hinges.clear()
	_split_right_hinges.clear()
	_equator_upper = null
	_equator_lower = null
	_core_root = null
	_muzzle = null

	_build_visual_rig()
	_apply_fold_pose(_fold_amount)

func configure(config_data: Dictionary) -> void:
	super.configure(config_data)
	if config_data.is_empty():
		return

	var split_before_config: bool = split_faces_enabled

	if config_data.has("inflate"):
		inflation_enabled = _to_bool(config_data["inflate"], inflation_enabled)
	if config_data.has("inflate_speed"):
		inflation_speed = _to_float(config_data["inflate_speed"], inflation_speed)
	if config_data.has("inflate_amp"):
		inflation_amplitude = _to_float(config_data["inflate_amp"], inflation_amplitude)
	if config_data.has("inflate_min"):
		inflation_min_scale = _to_float(config_data["inflate_min"], inflation_min_scale)
	if config_data.has("inflate_fire_bias"):
		inflation_fire_bias = _to_float(config_data["inflate_fire_bias"], inflation_fire_bias)
	if config_data.has("inflate_radius_max"):
		inflated_radius_scale = _to_float(config_data["inflate_radius_max"], inflated_radius_scale)
	if config_data.has("inflate_radius_min"):
		deflated_radius_scale = _to_float(config_data["inflate_radius_min"], deflated_radius_scale)
	if config_data.has("inflate_thickness_max"):
		inflated_thickness_scale = _to_float(config_data["inflate_thickness_max"], inflated_thickness_scale)
	if config_data.has("inflate_thickness_min"):
		deflated_thickness_scale = _to_float(config_data["inflate_thickness_min"], deflated_thickness_scale)
	if config_data.has("pleat_fold"):
		pleat_fold_degrees = _to_float(config_data["pleat_fold"], pleat_fold_degrees)
	if config_data.has("pleat_twist"):
		pleat_twist_degrees = _to_float(config_data["pleat_twist"], pleat_twist_degrees)
	if config_data.has("aperture_open"):
		aperture_open_scale = _to_float(config_data["aperture_open"], aperture_open_scale)
	if config_data.has("aperture_closed"):
		aperture_closed_scale = _to_float(config_data["aperture_closed"], aperture_closed_scale)
	if config_data.has("collar_closed"):
		outer_collar_closed_scale = _to_float(config_data["collar_closed"], outer_collar_closed_scale)
	if config_data.has("split_faces"):
		split_faces_enabled = _to_bool(config_data["split_faces"], split_faces_enabled)
	if config_data.has("split_closed"):
		split_closed_dihedral_degrees = _to_float(config_data["split_closed"], split_closed_dihedral_degrees)
	if config_data.has("split_open"):
		split_open_dihedral_degrees = _to_float(config_data["split_open"], split_open_dihedral_degrees)
	if config_data.has("split_jitter"):
		split_jitter_degrees = _to_float(config_data["split_jitter"], split_jitter_degrees)

	if split_before_config != split_faces_enabled and _shell_root != null:
		_rebuild_visual_rig()


func apply_grid_config(config_data: Dictionary) -> void:
	## The base routes apply_grid_config straight to configure(), and configure()
	## returns early on an empty dictionary — so the WARNING read cannot live in
	## there or a bare `{}` from the grid would skip the config_warning metadata.
	## Same override shape as [[armadillo_eggling]].
	super.apply_grid_config(config_data)
	_read_warning(config_data)


func _read_warning(config_data: Dictionary) -> void:
	# Read last, from the config dict or the config_<key> metadata the grid stamps on
	# the root, and an unknown word keeps the default rather than blanking the dressing.
	var w: String = ""
	if config_data.has("warning"):
		w = str(config_data["warning"])
	elif has_meta("config_warning"):
		w = str(get_meta("config_warning"))
	w = w.strip_edges().to_lower()
	if WARNING_VALUES.has(w):
		warning = w
	_build_warning()


# ── WARNING ──────────────────────────────────────────────────────────────────
# One axis, five values, the vocabulary shared with [[miura_crawler]],
# [[scissor_stalker]], [[kaleidocycle_enemy]] and [[path_block]]. Every builder below
# adds MeshInstance3D children only — never a collider, never a group the combat code
# reads, never a distance. Deterministic: nothing here draws from the random stream and
# nothing here is animated, so five variants of the same wheel differ only in what
# stands around it.
#
# Sized from the EXPORTS, never from the live inflation: _shell_root.scale breathes
# with the pulse, and dressing that breathed with it would be an animation, not a still.

const WARN_STAIN_OUTER := Color(0.24, 0.19, 0.13)
const WARN_STAIN_CORE := Color(0.09, 0.075, 0.055)
const WARN_BAR := Color(0.52, 0.50, 0.44)
const WARN_TAG := Color(0.86, 0.72, 0.12)
const WARN_MAST := Color(0.38, 0.38, 0.40)
const WARN_LAMP := Color(1.0, 0.62, 0.12)
const WARN_CLOTH := Color(0.40, 0.38, 0.33)
const WARN_STRAP := Color(0.15, 0.14, 0.13)


func _build_warning() -> void:
	## Rebuildable: a map hands its config to apply_grid_config AFTER _ready, so this
	## runs twice. Drop the previous dressing immediately (remove_child before
	## queue_free — the sweep measures the AABB on the very next frame).
	for child in get_children():
		if child.is_in_group("hazard_warning"):
			remove_child(child)
			child.queue_free()
	match warning:
		"stain":
			_warn_stain()
		"cage":
			_warn_cage()
		"beacon":
			_warn_beacon()
		"shroud":
			_warn_shroud()
		_:
			pass


## Half the wheel across its face. The pleat tips reach shell_radius * 0.68 + half a
## panel, scaled by the inflated radius — read from the same exports the shell is built
## from, never hardcoded, so a configured wheel keeps its dressing fitted.
func _warn_reach() -> float:
	return maxf(shell_radius * inflated_radius_scale * 1.15, 0.12)


## Half the wheel through the axle. A droideka is a disc: it is nearly twice as wide as
## it is deep, and the crate and the cover have to be that shape or they read as boxes
## that happen to contain something.
func _warn_depth() -> float:
	return maxf(shell_radius * 0.62, 0.08)


## The floor. The wheel is built centred on the node origin (it rolls about it), so
## the ground is a full radius BELOW the origin — not at y = 0 like a standing hazard.
func _warn_ground() -> float:
	return -_warn_reach()


## STAIN — the notice written on the ground. A rolled rut running the length of its
## approach, a worn darker centre, and two smears where it slewed. The floor keeps the
## record of a thing that has been coming at people for a while.
func _warn_stain() -> void:
	var r: float = _warn_reach()
	var d: float = _warn_depth()
	var y: float = _warn_ground() + 0.008
	_warn_add(Vector3(0, y, 0), Vector3(d * 3.0, 0.012, r * 5.2),
		_warn_mat(WARN_STAIN_OUTER, 1.0, 0.0))
	_warn_add(Vector3(0, y + 0.007, 0), Vector3(d * 1.5, 0.012, r * 4.6),
		_warn_mat(WARN_STAIN_CORE, 1.0, 0.0))
	_warn_add(Vector3(d * 1.35, y + 0.004, r * 1.30), Vector3(d * 1.1, 0.012, r * 1.05),
		_warn_mat(WARN_STAIN_CORE, 1.0, 0.0))
	_warn_add(Vector3(-d * 1.15, y + 0.004, -r * 1.55), Vector3(d * 0.8, 0.012, r * 0.75),
		_warn_mat(WARN_STAIN_CORE, 1.0, 0.0))


## CAGE — the notice as paperwork. Four posts and two rings of rails hugging the thin
## axis, one filed yellow tag. The wheel rolls out of it on the gait it always had.
func _warn_cage() -> void:
	var r: float = _warn_reach()
	var d: float = _warn_depth()
	var bot: float = _warn_ground() - 0.03
	var top: float = _warn_ground() + r * 2.15
	var px: float = r * 1.18
	var pz: float = d * 2.10
	var bar: StandardMaterial3D = _warn_mat(WARN_BAR, 0.45, 0.55)
	var thick: float = maxf(r * 0.09, 0.03)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_warn_add(Vector3(float(sx) * px, (bot + top) * 0.5, float(sz) * pz),
				Vector3(thick, top - bot, thick), bar)
	for ry in [top, bot + (top - bot) * 0.45]:
		var y: float = float(ry)
		for s in [-1.0, 1.0]:
			_warn_add(Vector3(0, y, float(s) * pz),
				Vector3(px * 2.0 + thick, thick * 0.8, thick * 0.8), bar)
			_warn_add(Vector3(float(s) * px, y, 0),
				Vector3(thick * 0.8, thick * 0.8, pz * 2.0 + thick), bar)
	_warn_add(Vector3(px + thick * 0.6, bot + (top - bot) * 0.70, 0),
		Vector3(0.018, r * 0.42, d * 1.10), _warn_mat(WARN_TAG, 0.7, 0.0))


## BEACON — the notice as broadcast. A mast beside the hub with a lamp head under a
## shade, and a lit outline burnt into the floor around the wheel's footprint.
func _warn_beacon() -> void:
	var r: float = _warn_reach()
	var d: float = _warn_depth()
	var bot: float = _warn_ground() - 0.03
	var mast_h: float = r * 2.60
	var mast: StandardMaterial3D = _warn_mat(WARN_MAST, 0.4, 0.6)
	var lamp: StandardMaterial3D = _warn_emissive(WARN_LAMP, 3.2)
	var thick: float = maxf(r * 0.09, 0.03)
	var mx: float = -r * 1.30
	_warn_add(Vector3(mx, bot + mast_h * 0.5, 0), Vector3(thick, mast_h, thick), mast)
	_warn_add(Vector3(mx, bot + mast_h + r * 0.18, 0), Vector3(r * 0.40, r * 0.24, r * 0.40), lamp)
	_warn_add(Vector3(mx, bot + mast_h + r * 0.36, 0), Vector3(r * 0.58, thick * 0.7, r * 0.58), mast)
	for s in [-1.0, 1.0]:
		_warn_add(Vector3(0, bot + 0.012, float(s) * d * 2.4),
			Vector3(r * 2.6, 0.02, thick), lamp)
		_warn_add(Vector3(float(s) * r * 1.30, bot + 0.012, 0),
			Vector3(thick, 0.02, d * 4.8), lamp)


## SHROUD — the notice withheld. A fitted cover over the whole wheel with a ridged top
## and two straps: the pleats, the collar and the lit core all go under cloth, and what
## is left is a covered object of no obvious kind. It rolls out unchanged.
func _warn_shroud() -> void:
	var r: float = _warn_reach()
	var d: float = _warn_depth()
	var g: float = _warn_ground()
	var cloth: StandardMaterial3D = _warn_mat(WARN_CLOTH, 0.95, 0.0)
	var strap: StandardMaterial3D = _warn_mat(WARN_STRAP, 0.85, 0.1)
	var w: float = r * 2.24
	var dep: float = d * 2.70
	var h: float = r * 2.12
	var mid: float = g + h * 0.5
	_warn_add(Vector3(0, g + h, 0), Vector3(w, 0.05, dep), cloth)
	for s in [-1.0, 1.0]:
		_warn_add(Vector3(0, mid, float(s) * dep * 0.5), Vector3(w, h, 0.025), cloth)
		_warn_add(Vector3(float(s) * w * 0.5, mid, 0), Vector3(0.025, h, dep), cloth)
	_warn_add(Vector3(0, g + h + 0.04, 0), Vector3(w * 0.24, 0.06, dep * 0.9), cloth)
	for s in [-1.0, 1.0]:
		_warn_add(Vector3(float(s) * w * 0.26, mid + h * 0.10, 0),
			Vector3(0.05, h * 1.02, dep + 0.016), strap)


func _warn_add(center: Vector3, box_size: Vector3, mat: Material) -> void:
	var bm: BoxMesh = BoxMesh.new()
	bm.size = box_size
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = bm
	mi.material_override = mat
	mi.position = center
	mi.add_to_group("hazard_warning")
	add_child(mi)


func _warn_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _warn_emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m
