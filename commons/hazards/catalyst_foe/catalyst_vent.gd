# @identity
# essence: vent(rate, wave_size) -> [CatalystFoe ...] -- a corruption seam in the biome that emits foes
# desire: to be the spawn source of the catalyst tower-defense game in VR -- a place the angry come from, visible from far away
# critical_parameter: emit_interval_s + wave_size -- how fast and how many foes; once wave is spent, the vent goes quiet
# triggers: _physics_process() ticks the timer; emits one CatalystFoe on schedule until wave_size is reached; player can transform foes after they leave the vent
# emerges: a column of grey orbs marching one cell at a time toward the player -- the tower-defense rhythm
# needs: CatalystFoe scene [has at sibling]; world ref to add foes to [has via parent]; tall pillar visual so the vent reads at any camera angle [has]
# relationships: mirrors the e:RATE:WAVE token in /editor; the third-person catalyst loop in VR; pairs with catalyst_foe
# truth: the vent is not malicious -- it is the biome leaking; the angry are made of the same biome the player walks on.

# catalyst_vent.gd
# Spawn point for biome-borne foes. Periodically emits CatalystFoe
# bodies up to wave_size, then goes quiet. The visual is a tall grey
# pillar so authors can see vent placement from any camera angle.
extends Node3D

# Verbose emit logging. Off by default — flip on locally when diagnosing
# vent rate / wave size / spawn position issues.
const DEBUG_LOG: bool = false
class_name CatalystVent

const FOE_SCENE := preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")

# ── Tunables ─────────────────────────────────────────────────────────
# All four can be overridden per-placement via apply_grid_config / token
# config. See README for the full grammar.
@export var emit_interval_s: float = 2.0    # seconds between emissions
@export var wave_size: int = 5               # max foes this vent emits
@export var start_delay_s: float = 5.0       # warmup AFTER catalyst is armed
@export var require_catalyst_armed: bool = true  # block emissions until player has the bracelet
@export var pillar_height: float = 4.0       # visual only

var _emitted: int = 0
var _timer: float = 0.0          # accumulates dt
var _started: bool = false       # flips true once start_delay elapses
var _live_count: int = 0


func _ready() -> void:
	add_to_group("catalyst_vent")
	_build_visual()


func _build_visual() -> void:
	# Tall translucent grey pillar — visible from any angle, reads as
	# "this is where the angry come from".
	var pillar := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.18
	cyl.bottom_radius = 0.30
	cyl.height = pillar_height
	pillar.mesh = cyl
	pillar.position = Vector3(0, pillar_height * 0.5, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.61, 0.64, 0.69, 0.30)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	pillar.material_override = mat
	add_child(pillar)
	# Halo at base
	var halo := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.34
	torus.outer_radius = 0.46
	halo.mesh = torus
	halo.position = Vector3(0, 0.04, 0)
	var halo_mat := StandardMaterial3D.new()
	halo_mat.albedo_color = Color(0.61, 0.64, 0.69, 0.55)
	halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo.material_override = halo_mat
	add_child(halo)
	# Dark orb at cube top
	var orb := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.36
	sphere.height = 0.72
	orb.mesh = sphere
	orb.position = Vector3(0, 0.45, 0)
	var orb_mat := StandardMaterial3D.new()
	orb_mat.albedo_color = Color(0.10, 0.11, 0.14)
	orb_mat.emission_enabled = true
	orb_mat.emission = Color(0.63, 0.65, 0.69)
	orb_mat.emission_energy_multiplier = 0.55
	orb.material_override = orb_mat
	add_child(orb)


func _physics_process(delta: float) -> void:
	if _emitted >= wave_size:
		return
	# Wait until the player has actually picked up the catalyst before
	# starting the warmup. The catalyst body adds itself to group
	# "catalyst" and sets _absorbed=true on grab. Until then, the
	# warmup timer doesn't even tick — vent stays silent.
	if not _started and require_catalyst_armed and not _is_catalyst_armed():
		return
	_timer += delta
	# Warmup — first emission waits for start_delay_s (after the
	# bracelet is armed), subsequent ones wait for emit_interval_s.
	if not _started:
		if _timer < start_delay_s:
			return
		_started = true
		_timer = 0.0
		_emit_one()
		return
	if _timer < emit_interval_s:
		return
	_timer = 0.0
	_emit_one()


# Returns true if any BecomingCatalyst body is in absorbed state.
# Implemented as a scene-tree lookup (no autoload dependency) so it
# works in test scenes too.
func _is_catalyst_armed() -> bool:
	for n in get_tree().get_nodes_in_group("catalyst"):
		if n.get("_absorbed") == true:
			return true
	return false


func _emit_one() -> void:
	# Cast via Node3D rather than CatalystFoe so this script parses
	# in isolation (class_name lookup isn't always available during
	# headless --check-only). At runtime the instantiated node IS a
	# CatalystFoe — its hit_by_projectile() / state machine still fire.
	var instance: Node = FOE_SCENE.instantiate()
	if instance == null:
		print("[CatalystVent] FAIL: foe scene returned null")
		return
	var foe: Node3D = instance as Node3D
	if foe == null:
		instance.queue_free()
		return
	# Insert into the parent map's tree, not as our own child — so the
	# foe survives if the vent is removed (rare, but cleaner).
	var parent: Node = get_parent()
	if parent == null:
		foe.queue_free()
		return
	parent.add_child(foe)
	# Spawn at the vent's footprint, just above the floor.
	foe.global_position = global_position + Vector3(0, 0.4, 0)
	_emitted += 1
	_live_count += 1
	foe.tree_exited.connect(_on_foe_exited)
	if DEBUG_LOG:
		print("[CatalystVent] emitted foe %d/%d at %s (vent at %s)" % [
			_emitted, wave_size, foe.global_position, global_position])


func _on_foe_exited() -> void:
	_live_count = max(0, _live_count - 1)


# ── Grid integration ─────────────────────────────────────────────────
func apply_grid_config(config_data: Dictionary) -> void:
	var rate := float(config_data.get("emit_interval_s", emit_interval_s))
	if rate > 0.0:
		emit_interval_s = rate
	var wave := int(config_data.get("wave_size", wave_size))
	if wave > 0:
		wave_size = wave
	# start_delay_s: warmup pause before the FIRST emission. Counts
	# only AFTER the catalyst is picked up (unless require_catalyst_armed
	# is false). Accept 0 (immediate after pickup).
	var delay := float(config_data.get("start_delay_s", start_delay_s))
	if delay >= 0.0:
		start_delay_s = delay
	# require_catalyst_armed: when true, the vent stays silent until
	# the player picks up the bracelet. Set to false for maps where
	# catalyst is optional / not yet introduced.
	if config_data.has("require_catalyst_armed"):
		require_catalyst_armed = bool(config_data.get("require_catalyst_armed"))


# Diagnostic helpers ----------------------------------------------------
func get_remaining() -> int:
	return max(0, wave_size - _emitted)


func get_live_count() -> int:
	return _live_count
