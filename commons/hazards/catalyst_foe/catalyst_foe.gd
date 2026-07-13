# @identity
# essence: a HazardCreatureBase subclass that the catalyst phase-shifts through 5 personality stages — extends the project's shared personality system with catalyst-specific dispatch
# desire: to embody the unifying enemy principle in VR -- the angry are biome-borne, the catalyst doesn't kill, transformation propagates one notch at a time
# critical_parameter: foe_mode -- locked at FIRST catalyst hit; determines FRIEND peer-conversion behaviour (GOO converts, TRANSPORT pushes, SWARM speeds up, DRAINFRIEND drags peers back, WAVE slow-pulses, FRACTAL split-converts, CHROMA/BRANCH convert with distinct hue+badge)
# triggers: hit_by_catalyst_mode(color, mode_id) advances personality one step along the arc; HazardManager + soft_stages.json drive sequence-aware initial personality
# emerges: a flock of color walking toward the next angry thing — the catalyst becomes the world, one curriculum sequence at a time
# needs: HazardCreatureBase parent [has, provides _personality + behavior flags + apply_grid_config + soft_stages.json wiring]; collision_layer 2 [has, in .tscn]; CharacterBody3D root [has, inherited from parent]
# relationships: extends HazardCreatureBase (43 sibling subclasses); spawned by catalyst_vent; tickled by catalyst_projectile; sequence personality from HazardManager.get_hazard_personality("catalyst_foe"); soft_stages.json carries personality_shift per spine sequence
# truth: the catalyst doesn't kill — it phase-shifts; what was alone becomes a flock walking toward the next angry thing.

# catalyst_foe.gd
# Catalyst-specific subclass of HazardCreatureBase. The shared parent
# class provides:
#   - _personality (foe/wary/neutral/curious/friend) + behavior flags
#   - _apply_personality(): wires _can_chase, _flee_from_player, etc.
#   - _query_hazard_manager(): auto-applies sequence-aware personality
#     from soft_stages.json's `personality_shift` table
#   - move_and_slide()-based continuous movement
#   - apply_grid_config()/configure() for tuning
#   - take_damage / _apply_damage / _handle_contact_damage
#
# This subclass adds:
#   - foe_mode (GOO/TRANSPORT/SWARM/DRAINFRIEND/CHROMA/WAVE/FRACTAL/BRANCH)
#   - hit_by_catalyst_mode() entry point for catalyst projectile
#   - One-step-per-hit personality arc advancement
#   - FRIEND peer-conversion behavior (override _process_chase)
#   - Per-lineage FRIEND powers (_process_friend_power dispatch):
#     shield orbit+absorb (primitives), escort ring+shove (swarm),
#     calmer timed slow-pulse (waveform), splitter clone (fractal),
#     replicator arc-nudge (cellular), porter void platform
#     (transformation), bridger tendril call (branching)
#   - Per-foe_mode visual badge (wedge / satellites / drain pyramid /
#     stacked cubes / sine spheres / nested boxes / trunk+twig)
#   - hit-burst particle + light pulse on transformation
extends HazardCreatureBase
class_name CatalystFoe

const DEBUG_LOG: bool = false

# ── Catalyst-specific signals ───────────────────────────────────────
# Parent provides enemy_destroyed; we add catalyst-specific events.
signal caught_player
signal curious_contact
signal personality_changed(from_personality: String, to_personality: String)


# ── Personality arc ─────────────────────────────────────────────────
# Inherited from HazardCreatureBase as of 2026-05-11 (moved up so all
# subclasses can be walked along the arc by the catalyst orb's
# receive_catalyst_field). See hazard_creature_base.gd.


# ── Foe Mode ────────────────────────────────────────────────────────
# Locked at the FIRST catalyst hit (the one that takes the creature out
# of "foe"); determines FRIEND peer-conversion behavior at the end of
# the arc. Mirrors the editor's per-sequence enemy kinds.
enum FoeMode { GOO, TRANSPORT, SWARM, DRAINFRIEND, CHROMA, WAVE, FRACTAL, BRANCH }
var foe_mode: FoeMode = FoeMode.GOO

# The exact mode_id that locked this creature's lineage (first catalyst hit).
# Still finer-grained than foe_mode (unmapped mode_ids default to GOO) and
# each grants a distinct friend power. Carried through peer conversions so a
# chain started by one mode stays that mode's lineage.
var _locked_mode_id: String = "primitives"

const MODE_BY_ID: Dictionary = {
	"transformation": FoeMode.TRANSPORT,
	"forces":         FoeMode.SWARM,
	"swarm":          FoeMode.SWARM,
	"chaos":          FoeMode.SWARM,
	"cellular":       FoeMode.DRAINFRIEND,
	"chromatic":      FoeMode.CHROMA,
	"waveform":       FoeMode.WAVE,
	"fractal":        FoeMode.FRACTAL,
	"branching":      FoeMode.BRANCH,
	# everything else (incl. "primitives") → GOO (default)
}


# ── Visual ──────────────────────────────────────────────────────────
const FRIEND_HUES: Array[Color] = [
	Color(0.93, 0.28, 0.60),  # pink
	Color(0.09, 0.64, 0.28),  # green
	Color(0.96, 0.62, 0.05),  # amber
	Color(0.15, 0.39, 0.92),  # blue
	Color(0.66, 0.33, 0.97),  # purple
	Color(0.40, 0.64, 0.12),  # lime
]

# The catalyst-foe's primary mesh material (set in _create_materials).
# Distinct from the per-mode badge material.
var _custom_mat: StandardMaterial3D
var _badge: Node3D
# Set true when apply_grid_config explicitly seeds an initial_state.
# Suppresses the parent's deferred HazardManager query so the seeded
# personality wins over the curriculum default. Maps without a seed
# fall back to HazardManager's sequence-aware personality.
var _personality_seeded: bool = false


# ── Friend-power state ──────────────────────────────────────────────
# Per-lineage powers for settled FRIENDs — every field below is inert
# (never read) unless the matching _locked_mode_id is active.

# SHIELD (primitives): 10s per-friend absorb cooldown, seconds clock.
const SHIELD_COOLDOWN_S: float = 10.0
var _shield_ready_at: float = 0.0

# CALMER (waveform): pulse every 2.5s, slow lasts 2s (restore in base).
const CALMER_PULSE_INTERVAL_S: float = 2.5
const CALMER_SLOW_DURATION_S: float = 2.0
var _calmer_pulse_timer: float = 0.0

# PORTER (transformation): walk to a void edge and park as a platform.
enum PorterState { IDLE, WALKING, PARKED }
var _porter_state: PorterState = PorterState.IDLE
var _porter_goal: Vector3 = Vector3.ZERO
var _porter_park_until: float = 0.0
var _porter_scan_timer: float = 0.0
var _porter_platform: StaticBody3D = null

# BRIDGER (branching): tendril helper contract (may land after this file).
const BRIDGER_TENDRIL_PATH: String = "res://commons/hazards/catalyst_foe/bridger_tendril.gd"
var _bridger_scan_timer: float = 0.0
var _bridger_next_grow: float = 0.0
var _tendril_script = null
var _tendril_checked: bool = false


# ── Critter morphology ──────────────────────────────────────────────
# ONE evolving pink critter: legacy grey cube before color, then a
# hovering mote → air-serpent (wavefunctions) → 8-legged octapod
# (randomness) → doubled waves (CA) → grand (fractals+). Stage resolves
# from HazardManager.get_current_stage_order() unless a map/vent seeds
# `critter_stage` via apply_grid_config. Flight and the snake-wave are
# VISUAL (mesh root offsets) — collision and pathing stay grounded so
# the catalyst-projectile and contact contracts are untouched.

const CritterMorphology := preload("res://commons/hazards/catalyst_foe/critter_morphology.gd")
var _critter_stage_order: float = -1.0   # apply_grid_config override; -1 = ask HazardManager
var _critter_stage_cache: Dictionary = {}
var _critter_refs: Dictionary = {}       # {"legs": [...], "eyes": [...]} from morphology build
var _critter_time: float = 0.0
var _blown_up: bool = false


func _critter_stage() -> Dictionary:
	if _critter_stage_cache.is_empty():
		var order: float = _critter_stage_order
		if order < 0.0:
			var hm: Node = get_node_or_null("/root/HazardManager")
			if hm != null and hm.has_method("get_current_stage_order"):
				order = float(hm.get_current_stage_order())
			else:
				order = 0.0
		_critter_stage_cache = CritterMorphology.stage_for(order)
	return _critter_stage_cache


func _critter_active() -> bool:
	return String(_critter_stage().get("name", "cube")) != "cube"


# ── Lifecycle (parent calls these in order from its _ready) ─────────

func _create_materials() -> void:
	_custom_mat = StandardMaterial3D.new()
	if _critter_active():
		# The pink critter — small per-instance hue wobble keeps a wave
		# of siblings distinguishable without leaving pink.
		var wobble: float = randf_range(-0.04, 0.04)
		_custom_mat.albedo_color = Color(0.93 + wobble, 0.28, 0.60 - wobble)
		_custom_mat.emission_enabled = true
		_custom_mat.emission = CritterMorphology.PINK_GLOW
		_custom_mat.emission_energy_multiplier = randf_range(0.5, 0.7)
		_custom_mat.roughness = 0.55
		return
	# Legacy grey-goo cube tint with small per-instance variation so
	# multiple foes spawned from the same vent look distinguishable.
	var grey_jitter: float = randf_range(0.07, 0.16)
	_custom_mat.albedo_color = Color(grey_jitter, grey_jitter, grey_jitter + 0.02)
	_custom_mat.emission_enabled = true
	var emis_v: float = randf_range(0.78, 0.88)
	_custom_mat.emission = Color(emis_v, emis_v, emis_v + 0.04)
	_custom_mat.emission_energy_multiplier = randf_range(0.55, 0.85)
	_custom_mat.roughness = randf_range(0.78, 0.92)


func _build_collision() -> void:
	# Override parent's default sphere with a 0.3m box that matches the
	# .tscn definition. The .tscn already declares collision_layer=2,
	# collision_mask=0 (catalyst_target's contract: layer 2 to be hit
	# by catalyst projectiles, no mask so we don't push world cubes).
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.3, 0.3, 0.3)
	col.shape = shape
	add_child(col)


func _build_mesh() -> void:
	var stage: Dictionary = _critter_stage()
	if String(stage.get("name", "cube")) == "cube":
		# Pre-color world (soft_stages order <= 4): the legacy grey lab cube.
		var box := BoxMesh.new()
		box.size = Vector3(0.3, 0.3, 0.3)
		_add_mesh(box, _custom_mat)
		return
	# After color: the pink critter, staged by curriculum order.
	_critter_refs = CritterMorphology.build(_mesh_root, _custom_mat, stage)


## Critter life: hover-bob, air-serpent weave, leg gait, chaos twitch.
## All offsets live on _mesh_root — physics stays grounded.
func _process_visual(delta: float) -> void:
	if _mesh_root == null or not _critter_active() or _blown_up:
		return
	_critter_time += delta
	var stage: Dictionary = _critter_stage()
	var t: float = _critter_time
	var offset := Vector3.ZERO
	if bool(stage.get("flying", false)):
		offset.y = float(stage.get("hover", 0.0)) + sin(t * 2.2) * 0.06
	if bool(stage.get("wave", false)) and velocity.length_squared() > 0.01:
		# Wavefunctions: it swims through the air like a snake — lateral
		# weave perpendicular to facing plus a vertical ripple.
		offset.x += sin(t * 3.4) * 0.22
		offset.y += sin(t * 5.1) * 0.12
	var jitter: float = float(stage.get("jitter", 0.0))
	if jitter > 0.0:
		offset.x += sin(t * 13.7) * 0.03 * jitter
		offset.z += cos(t * 11.3) * 0.03 * jitter
	_mesh_root.position = offset
	# (Legs walk themselves — the GaitRig plants and steps in world space.)
	# Googly eyes track the player: rotate each eye so its pupil (+Z child)
	# faces the player's head. Full-range tracking — the googly IS the charm.
	if is_instance_valid(_player_node):
		var look_target: Vector3 = _player_node.global_position + Vector3(0, 1.0, 0)
		for e in _critter_refs.get("eyes", []):
			if e is Node3D and is_instance_valid(e) and (e as Node3D).is_inside_tree():
				var eye := e as Node3D
				var to_p: Vector3 = look_target - eye.global_position
				if to_p.length() > 0.05 and absf(to_p.normalized().y) < 0.95:
					eye.look_at(look_target, Vector3.UP)
					eye.rotate_object_local(Vector3.UP, PI)  # look_at aims -Z; pupil sits at +Z


# ── Comic words ─────────────────────────────────────────────────────
# Impact language: a billboarded word fires on every catalyst hit and a
# bigger one on the pop. Randomized text + color, back-ease punch-in,
# drift up and fade. Words parent to the MAP (not the foe) so a BOOM!
# outlives the body that shouted it.

const HIT_WORDS: Array[String] = ["POP!", "WOW!", "BOING!", "EEP!", "ZING!", "OOF!"]
const BOOM_WORDS: Array[String] = ["BOOM!", "POW!", "BAM!", "KABOOM!", "SPLAT!", "WOW!"]
const COMIC_COLORS: Array[Color] = [
	Color(1.0, 0.85, 0.20),  # comic yellow
	Color(0.95, 0.30, 0.55), # hot pink
	Color(0.40, 0.90, 1.00), # pop cyan
	Color(1.0, 1.0, 1.0),    # flat white
]


func _spawn_comic_word(words: Array, size: float) -> void:
	if not _critter_active():
		return
	var host: Node = get_parent()
	if host == null:
		return
	var label := Label3D.new()
	label.text = words[randi() % words.size()]
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 220
	label.pixel_size = 0.0016 * size
	label.outline_size = 56
	label.modulate = COMIC_COLORS[randi() % COMIC_COLORS.size()]
	label.outline_modulate = Color(0.08, 0.06, 0.12)
	host.add_child(label)
	var seen: Vector3 = _mesh_root.position if _mesh_root != null else Vector3.ZERO
	label.global_position = global_position + seen \
		+ Vector3(randf_range(-0.15, 0.15), 0.28, randf_range(-0.15, 0.15))
	label.scale = Vector3.ONE * 0.15
	var tw := label.create_tween()
	tw.tween_property(label, "scale", Vector3.ONE, 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y + 0.35, 0.55)
	tw.tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.25)
	tw.chain().tween_callback(label.queue_free)


## The critter pops: a cute pink detonation. Damage was already applied by
## the contact path — the blow-up is the exit. One per life.
func _blow_up() -> void:
	if _blown_up:
		return
	_blown_up = true
	var burst_color: Color = CritterMorphology.PINK_GLOW
	# Burst where the body is SEEN (flying stages hover the mesh above the node).
	var at: Vector3 = _mesh_root.position if _mesh_root != null else Vector3.ZERO
	_spawn_hit_burst(burst_color, at, 2.0)
	_spawn_light_pulse(burst_color, at)
	_spawn_confetti(at)
	_spawn_comic_word(BOOM_WORDS, 1.8)
	# Balloon-pop shell: an expanding unlit pink sphere that reads at any
	# distance — the moment the cute thing stops being there.
	var pop := MeshInstance3D.new()
	var pm := SphereMesh.new()
	pm.radius = 0.22
	pm.height = 0.44
	pop.mesh = pm
	var pop_mat := StandardMaterial3D.new()
	pop_mat.albedo_color = Color(burst_color.r, burst_color.g, burst_color.b, 0.85)
	pop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pop.material_override = pop_mat
	pop.position = at
	add_child(pop)
	var pop_tween := create_tween()
	pop_tween.set_parallel(true)
	pop_tween.tween_property(pop, "scale", Vector3.ONE * 4.5, 0.35) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(pop_mat, "albedo_color:a", 0.0, 0.35)
	pop_tween.chain().tween_callback(pop.queue_free)


## Spinning pink-family confetti quads — the celebratory half of the pop.
## (Richer particle features borrowed from the codebase's developed
## examples: hue variation, per-particle spin, billboard-particles mode.)
func _spawn_confetti(offset: Vector3) -> void:
	var confetti := GPUParticles3D.new()
	confetti.position = offset
	confetti.amount = 40
	confetti.lifetime = 1.1
	confetti.one_shot = true
	confetti.explosiveness = 1.0
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 1.8
	pmat.initial_velocity_max = 4.2
	pmat.gravity = Vector3(0, -3.5, 0)
	pmat.scale_min = 0.5
	pmat.scale_max = 1.4
	pmat.angle_min = 0.0
	pmat.angle_max = 360.0
	pmat.angular_velocity_min = -360.0
	pmat.angular_velocity_max = 360.0
	pmat.hue_variation_min = -0.12
	pmat.hue_variation_max = 0.12
	pmat.color = Color(1.0, 0.62, 0.80)
	confetti.process_material = pmat
	var quad := QuadMesh.new()
	quad.size = Vector2(0.05, 0.05)
	confetti.draw_pass_1 = quad
	var qmat := StandardMaterial3D.new()
	qmat.vertex_color_use_as_albedo = true
	qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	confetti.material_override = qmat
	add_child(confetti)
	confetti.emitting = true
	var cleanup := get_tree().create_timer(confetti.lifetime + 0.3)
	cleanup.timeout.connect(confetti.queue_free)
	if _mesh_root != null:
		_mesh_root.visible = false
	contact_damage = 0.0
	for child in get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).set_deferred("disabled", true)
	_set_state(BaseState.DEAD)


## Rebuild body after a late critter_stage seed (config after _ready).
func _rebuild_critter_visuals() -> void:
	if _mesh_root == null:
		return
	for child in _mesh_root.get_children():
		child.queue_free()
	_mesh_root.scale = Vector3.ONE
	_critter_refs = {}
	_create_materials()
	_build_mesh()
	_apply_state_visuals_for_personality(_personality)
	if _personality == "friend":
		_build_friend_badge()


func _on_ready() -> void:
	add_to_group("catalyst_foe")
	# If apply_grid_config seeded a personality BEFORE _ready (which is
	# the order when the map composer or capture rig calls it right
	# after instantiate), the visuals couldn't apply yet (_custom_mat
	# was null). Re-apply now that materials exist.
	_apply_state_visuals_for_personality(_personality)
	if _personality == "friend":
		_build_friend_badge()


# ── Friend-power frame hook ─────────────────────────────────────────
# One clean entry: the base state machine runs as usual, then a settled
# FRIEND dispatches its lineage power. A PORTER that is walking to its
# gap or parked as a platform bypasses the state machine entirely.

func _physics_process(delta: float) -> void:
	if _personality == "friend" and _porter_state != PorterState.IDLE:
		_porter_physics(delta)
		return
	super._physics_process(delta)
	if _personality == "friend":
		_process_friend_power(delta)


func _process_friend_power(delta: float) -> void:
	# Per-lineage dispatch — a no-op for lineages without a frame power.
	# (SHIELD orbit + ESCORT movement live in _process_friend_chase;
	# SPLITTER + REPLICATOR fire from their event paths.)
	match _locked_mode_id:
		"swarm":
			_escort_shove_tick()
		"waveform":
			_calmer_tick(delta)
		"transformation":
			_porter_tick(delta)
		"branching":
			_bridger_tick(delta)
		_:
			pass


# ── Catalyst hit contract ───────────────────────────────────────────
# These are the unique catalyst-specific entry points called by
# catalyst_projectile.gd.

func hit_by_projectile(color: Color) -> void:
	# Legacy entry — assume primitives mode (goo).
	if DEBUG_LOG:
		print("[CatalystFoe] hit_by_projectile(%s) → primitives mode" % color)
	hit_by_catalyst_mode(color, "primitives")


func hit_by_catalyst_mode(color: Color, mode_id: String) -> void:
	if DEBUG_LOG:
		print("[CatalystFoe] hit_by_catalyst_mode mode_id='%s', personality='%s'" % [
			mode_id, _personality])
	if _personality == "friend":
		return  # already friend
	# Advance ONE step along the arc, not all the way to friend.
	var prev: String = _personality
	var idx: int = PERSONALITY_ARC.find(prev)
	if idx < 0:
		idx = 0
	var next_personality: String = PERSONALITY_ARC[min(idx + 1, PERSONALITY_ARC.size() - 1)]
	# Lock the foe_mode at the FIRST hit.
	if prev == "foe":
		foe_mode = MODE_BY_ID.get(mode_id, FoeMode.GOO)
		_locked_mode_id = mode_id
		# Step rate per mode (matches editor's stepMul).
		if foe_mode == FoeMode.SWARM:
			chase_speed = chase_speed * 1.4  # faster
		elif foe_mode == FoeMode.DRAINFRIEND:
			chase_speed = chase_speed * 0.85  # slower
	# Update personality via parent (sets behaviour flags).
	set_personality(next_personality)
	personality_changed.emit(prev, next_personality)
	# Comic impact word on every catalyst hit (critter stages only).
	_spawn_comic_word(HIT_WORDS, 0.8)

	# The moment of alignment: the first FRIEND of a mode-lineage grants the
	# player that lineage's lasting power (CatalystCapabilityManager dedupes).
	if next_personality == "friend":
		_grant_friend_power()

	# Visual flash on transition.
	if next_personality == "friend":
		# Big pop — the moment of becoming.
		var c: Color = color
		if c == Color(0, 0, 0, 0):
			c = _friend_hue_for_mode(foe_mode)
		if _custom_mat != null:
			_custom_mat.albedo_color = c
			_custom_mat.emission = c
			_custom_mat.emission_energy_multiplier = 5.0
			var emis_tween := create_tween()
			emis_tween.tween_property(_custom_mat, "emission_energy_multiplier", 1.6, 0.6) \
				.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			# Squash-stretch transformation pop.
			var pop := create_tween()
			pop.tween_property(self, "scale", Vector3(1.4, 0.5, 1.4), 0.05) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			pop.tween_property(self, "scale", Vector3(1.7, 1.7, 1.7), 0.18) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			pop.tween_property(self, "scale", Vector3.ONE, 0.35) \
				.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			_build_friend_badge()
			_spawn_hit_burst(c)
			_spawn_light_pulse(c)
	else:
		# Subtle flash on intermediate transitions.
		_apply_state_visuals_for_personality(next_personality)
		if _custom_mat != null:
			_spawn_hit_burst(_custom_mat.emission)


# ── Per-personality visual signature ────────────────────────────────
# Applied alongside parent's _apply_personality (which only sets
# behaviour flags). The colour progression is what makes the arc
# legible at a glance.

func _apply_state_visuals_for_personality(p: String) -> void:
	if _custom_mat == null:
		return
	# The critter stays PINK through the hostile half of the arc — the cute
	# thing is the dangerous thing. Only the emission tint carries the arc
	# until FRIEND takes the lineage hue (below, shared with the cube).
	if _critter_active() and p != "friend":
		_custom_mat.albedo_color = CritterMorphology.PINK_BODY
		match p:
			"foe":
				_custom_mat.emission = CritterMorphology.PINK_GLOW
				_custom_mat.emission_energy_multiplier = 0.9
				CritterMorphology.set_blob_tint(_critter_refs, CritterMorphology.PINK_BODY, 1.1)
			"wary":
				_custom_mat.emission = Color(0.95, 0.35, 0.30)
				_custom_mat.emission_energy_multiplier = 1.1
				CritterMorphology.set_blob_tint(_critter_refs, Color(0.90, 0.30, 0.38), 1.3)
			"neutral":
				_custom_mat.emission = Color(0.90, 0.68, 0.62)
				_custom_mat.emission_energy_multiplier = 0.8
				CritterMorphology.set_blob_tint(_critter_refs, Color(0.88, 0.55, 0.62), 0.9)
			"curious":
				_custom_mat.emission = Color(1.0, 0.75, 0.45)
				_custom_mat.emission_energy_multiplier = 1.3
				CritterMorphology.set_blob_tint(_critter_refs, Color(0.98, 0.55, 0.55), 1.4)
		return
	match p:
		"foe":
			_custom_mat.albedo_color = Color(0.10, 0.11, 0.14)
			_custom_mat.emission = Color(0.82, 0.83, 0.87)
			_custom_mat.emission_energy_multiplier = 0.7
		"wary":
			_custom_mat.albedo_color = Color(0.55, 0.18, 0.16)
			_custom_mat.emission = Color(0.92, 0.32, 0.20)
			_custom_mat.emission_energy_multiplier = 1.1
		"neutral":
			_custom_mat.albedo_color = Color(0.52, 0.45, 0.32)
			_custom_mat.emission = Color(0.85, 0.78, 0.60)
			_custom_mat.emission_energy_multiplier = 0.9
		"curious":
			_custom_mat.albedo_color = Color(0.92, 0.72, 0.28)
			_custom_mat.emission = Color(0.98, 0.82, 0.42)
			_custom_mat.emission_energy_multiplier = 1.4
		"friend":
			# Hue from foe_mode (set in hit_by_catalyst_mode for catalyst-driven
			# transitions, or here for direct seeding).
			var hue: Color = _friend_hue_for_mode(foe_mode)
			_custom_mat.albedo_color = hue
			_custom_mat.emission = hue
			_custom_mat.emission_energy_multiplier = 1.6
			CritterMorphology.set_blob_tint(_critter_refs, hue, 1.6)


# ── Override _process_chase for FRIEND peer-conversion ──────────────
# Parent handles foe/wary/neutral/curious chase variants beautifully.
# FRIEND is unique to catalyst_foe — chase nearest non-friend foe.

func _process_chase(delta: float) -> void:
	if _personality == "friend":
		_process_friend_chase(delta)
	else:
		super._process_chase(delta)


func _process_friend_chase(delta: float) -> void:
	# Lineage movement overrides — SHIELD orbits the player, ESCORT holds
	# a formation slot. Every other lineage keeps peer-conversion chase.
	if _locked_mode_id == "primitives":
		_process_shield_orbit(delta)
		return
	if _locked_mode_id == "swarm":
		_process_escort_movement(delta)
		return
	var target: CatalystFoe = _nearest_non_friend()
	if target == null:
		velocity = velocity.move_toward(Vector3.ZERO, 0.2)
		return
	var to_target: Vector3 = target.global_position - global_position
	to_target.y = 0.0
	var dist: float = to_target.length()
	var contact_radius: float = 0.6
	if dist < contact_radius * 2.0:
		# Contact — dispatch per foe_mode
		match foe_mode:
			FoeMode.TRANSPORT:
				# Push peer AWAY from player by ~2m, keep them as foe
				if is_instance_valid(_player_node):
					var away: Vector3 = target.global_position - _player_node.global_position
					away.y = 0
					if away.length() > 0.001:
						away = away.normalized()
						target.global_position += Vector3(round(away.x) * 2.0, 0, round(away.z) * 2.0)
			FoeMode.WAVE:
				# Convert peer + slow pulse: every other non-friend foe
				# within 3m gets a TIMED slow (the wave dampens, then the
				# base class restores the remembered speed — never permanent).
				if _custom_mat != null:
					target.hit_by_catalyst_mode(_custom_mat.albedo_color, _mode_id_for_dispatch())
				for n in get_tree().get_nodes_in_group("catalyst_foe"):
					var f := n as CatalystFoe
					if f == null or f == self or f._personality == "friend":
						continue
					if f.global_position.distance_to(global_position) <= 3.0:
						_apply_timed_slow(f)
			FoeMode.FRACTAL:
				# Split conversion: the second-nearest non-friend foe also
				# advances one arc step (the conversion recurses).
				if _custom_mat != null:
					target.hit_by_catalyst_mode(_custom_mat.albedo_color, _mode_id_for_dispatch())
					var second: CatalystFoe = _nearest_non_friend_excluding(target)
					if second != null:
						second.hit_by_catalyst_mode(_custom_mat.albedo_color, _mode_id_for_dispatch())
			_:
				# Default (GOO / SWARM / DRAINFRIEND / CHROMA / BRANCH): convert peer
				if _custom_mat != null:
					target.hit_by_catalyst_mode(_custom_mat.albedo_color, _mode_id_for_dispatch())
					# REPLICATOR (cellular lineage): each conversion also
					# advances the next-nearest non-friend one arc step.
					if _locked_mode_id == "cellular":
						var neighbor: CatalystFoe = _nearest_non_friend_excluding(target)
						if neighbor != null:
							neighbor.hit_by_catalyst_mode(_custom_mat.albedo_color, _mode_id_for_dispatch())
	else:
		# Move toward target
		if dist > 0.01:
			var dir: Vector3 = to_target.normalized()
			var sp: float = chase_speed * _approach_speed_factor
			velocity.x = dir.x * sp
			velocity.z = dir.z * sp
			_face_direction(dir, delta * 3.0)
	velocity.y = 0.0


# ── Helpers ─────────────────────────────────────────────────────────

func _nearest_non_friend() -> CatalystFoe:
	return _nearest_non_friend_to(global_position)


func _nearest_non_friend_to(pos: Vector3) -> CatalystFoe:
	var best: CatalystFoe = null
	var best_d: float = INF
	for n in get_tree().get_nodes_in_group("catalyst_foe"):
		var f := n as CatalystFoe
		if f == null or f == self or f._personality == "friend":
			continue
		var d: float = f.global_position.distance_to(pos)
		if d < best_d:
			best_d = d
			best = f
	return best


func _nearest_non_friend_excluding(exclude: CatalystFoe) -> CatalystFoe:
	# Nearest non-friend foe that is NOT `exclude` — FRACTAL's split target
	# and REPLICATOR's (cellular) arc-nudge target.
	var best: CatalystFoe = null
	var best_d: float = INF
	for n in get_tree().get_nodes_in_group("catalyst_foe"):
		var f := n as CatalystFoe
		if f == null or f == self or f == exclude or f._personality == "friend":
			continue
		var d: float = f.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = f
	return best


func _now_s() -> float:
	return float(Time.get_ticks_msec()) * 0.001


func _mode_id_for_dispatch() -> String:
	# Peer conversions carry the exact lineage mode, not just the coarse kind —
	# a chromatic-born chain keeps granting/painting chromatic.
	return _locked_mode_id


## Canonical mode_id for a FoeMode — used when a map seeds foe_mode directly
## (apply_grid_config) so _locked_mode_id stays consistent with the kind.
static func _canonical_mode_for(m: FoeMode) -> String:
	match m:
		FoeMode.TRANSPORT:   return "transformation"
		FoeMode.SWARM:       return "swarm"
		FoeMode.DRAINFRIEND: return "cellular"
		FoeMode.CHROMA:      return "chromatic"
		FoeMode.WAVE:        return "waveform"
		FoeMode.FRACTAL:     return "fractal"
		FoeMode.BRANCH:      return "branching"
		_:                   return "primitives"


## Report this creature's alignment to the capability manager. The first
## conversion of a mode-lineage becomes a lasting player power.
func _grant_friend_power() -> void:
	var mgr: Node = get_node_or_null("/root/CatalystCapabilityManager")
	if mgr != null and mgr.has_method("grant_friend_power"):
		mgr.grant_friend_power(_locked_mode_id)


func _friend_hue_for_mode(m: FoeMode) -> Color:
	match m:
		FoeMode.GOO:         return Color(0.30, 0.78, 0.42)   # mint green
		FoeMode.TRANSPORT:   return Color(0.20, 0.55, 0.95)   # sky blue
		FoeMode.SWARM:       return Color(0.95, 0.50, 0.18)   # warm orange
		FoeMode.DRAINFRIEND: return Color(0.65, 0.30, 0.85)   # violet
		FoeMode.CHROMA:      return Color(0.93, 0.28, 0.60)   # magenta (rainbow-adjacent)
		FoeMode.WAVE:        return Color(0.18, 0.80, 0.90)   # cyan
		FoeMode.FRACTAL:     return Color(0.10, 0.55, 0.52)   # deep teal
		FoeMode.BRANCH:      return Color(0.40, 0.64, 0.12)   # leaf green
		_: return Color(0.30, 0.78, 0.42)


# ── Friend badge per foe_mode ───────────────────────────────────────
# Only FRIENDs get badges (the badge IS the friend signature).

func _build_friend_badge() -> void:
	if _badge != null and is_instance_valid(_badge):
		_badge.queue_free()
		_badge = null
	if _personality != "friend":
		return
	if foe_mode == FoeMode.GOO:
		return  # GOO is the default — no badge
	_badge = Node3D.new()
	_badge.name = "FriendBadge"
	add_child(_badge)
	var bm := StandardMaterial3D.new()
	bm.albedo_color = _custom_mat.albedo_color if _custom_mat else Color.WHITE
	bm.emission_enabled = true
	bm.emission = _custom_mat.emission if _custom_mat else Color.WHITE
	bm.emission_energy_multiplier = 2.0
	if foe_mode == FoeMode.TRANSPORT:
		# Wedge on top — directional shove indicator
		var wedge := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.18, 0.10, 0.20)
		wedge.mesh = pm
		wedge.material_override = bm
		wedge.position = Vector3(0, 0.22, 0)
		_badge.add_child(wedge)
	elif foe_mode == FoeMode.SWARM:
		# 3 satellite cubes statically positioned at 120° around the body
		for i in range(3):
			var sat := MeshInstance3D.new()
			var sm := BoxMesh.new()
			sm.size = Vector3(0.10, 0.10, 0.10)
			sat.mesh = sm
			sat.material_override = bm
			var ang: float = (i * TAU) / 3.0
			sat.position = Vector3(cos(ang) * 0.30, 0.10, sin(ang) * 0.30)
			_badge.add_child(sat)
	elif foe_mode == FoeMode.DRAINFRIEND:
		# Downward-pointing pyramid — drain
		var drain := MeshInstance3D.new()
		var dm := PrismMesh.new()
		dm.size = Vector3(0.18, 0.18, 0.18)
		drain.mesh = dm
		drain.material_override = bm
		drain.position = Vector3(0, -0.20, 0)
		drain.rotation = Vector3(PI, 0, 0)
		_badge.add_child(drain)
	elif foe_mode == FoeMode.CHROMA:
		# Two stacked tinted cubes — chromatic layering
		var tints: Array[Color] = [Color(0.93, 0.28, 0.60), Color(0.35, 0.75, 0.95)]
		for i in range(2):
			var cube := MeshInstance3D.new()
			var cm := BoxMesh.new()
			cm.size = Vector3(0.12, 0.06, 0.12)
			cube.mesh = cm
			var tm := StandardMaterial3D.new()
			tm.albedo_color = tints[i]
			tm.emission_enabled = true
			tm.emission = tints[i]
			tm.emission_energy_multiplier = 2.0
			cube.material_override = tm
			cube.position = Vector3(0, 0.20 + i * 0.08, 0)
			_badge.add_child(cube)
	elif foe_mode == FoeMode.WAVE:
		# 3 small spheres in a sine offset — the wave crest
		for i in range(3):
			var crest := MeshInstance3D.new()
			var wm := SphereMesh.new()
			wm.radius = 0.05
			wm.height = 0.10
			crest.mesh = wm
			crest.material_override = bm
			crest.position = Vector3((i - 1) * 0.14, 0.24 + sin(i * TAU / 3.0) * 0.05, 0)
			_badge.add_child(crest)
	elif foe_mode == FoeMode.FRACTAL:
		# 2 nested boxes at different scales — self-similarity
		var outer := MeshInstance3D.new()
		var om := BoxMesh.new()
		om.size = Vector3(0.16, 0.16, 0.16)
		outer.mesh = om
		outer.material_override = bm
		outer.position = Vector3(0, 0.24, 0)
		_badge.add_child(outer)
		var inner := MeshInstance3D.new()
		var im := BoxMesh.new()
		im.size = Vector3(0.10, 0.10, 0.10)
		inner.mesh = im
		inner.material_override = bm
		inner.position = Vector3(0, 0.24, 0)
		inner.rotation = Vector3(PI / 4.0, PI / 4.0, 0)  # corners poke through the outer faces
		_badge.add_child(inner)
	elif foe_mode == FoeMode.BRANCH:
		# Thin vertical cylinder + tilted twig — the branching stem
		var trunk := MeshInstance3D.new()
		var trm := CylinderMesh.new()
		trm.top_radius = 0.02
		trm.bottom_radius = 0.02
		trm.height = 0.18
		trunk.mesh = trm
		trunk.material_override = bm
		trunk.position = Vector3(0, 0.26, 0)
		_badge.add_child(trunk)
		var twig := MeshInstance3D.new()
		var twm := CylinderMesh.new()
		twm.top_radius = 0.015
		twm.bottom_radius = 0.015
		twm.height = 0.12
		twig.mesh = twm
		twig.material_override = bm
		twig.position = Vector3(0.05, 0.30, 0)
		twig.rotation = Vector3(0, 0, -PI / 5.0)
		_badge.add_child(twig)


# ── Hit visuals ─────────────────────────────────────────────────────

func _spawn_hit_burst(burst_color: Color, offset: Vector3 = Vector3.ZERO, boost: float = 1.0) -> void:
	var burst := GPUParticles3D.new()
	burst.position = offset
	burst.amount = int(24 * boost)
	burst.lifetime = 0.6
	burst.one_shot = true
	burst.explosiveness = 0.95
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 1.5 * boost
	pmat.initial_velocity_max = 3.5 * boost
	pmat.gravity = Vector3(0, -1.5, 0)
	pmat.scale_min = 0.05 * boost
	pmat.scale_max = 0.12 * boost
	pmat.color = burst_color
	burst.process_material = pmat
	var sphere := SphereMesh.new()
	sphere.radius = 0.04
	sphere.height = 0.08
	burst.draw_pass_1 = sphere
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = burst_color
	bmat.emission_enabled = true
	bmat.emission = burst_color
	bmat.emission_energy_multiplier = 3.0
	burst.material_override = bmat
	add_child(burst)
	burst.emitting = true
	var cleanup := get_tree().create_timer(burst.lifetime + 0.2)
	cleanup.timeout.connect(burst.queue_free)


func _spawn_light_pulse(light_color: Color, offset: Vector3 = Vector3.ZERO) -> void:
	var light := OmniLight3D.new()
	light.position = offset
	light.light_color = light_color
	light.light_energy = 4.0
	light.omni_range = 2.5
	light.omni_attenuation = 2.0
	add_child(light)
	var t := create_tween()
	t.tween_property(light, "light_energy", 0.0, 0.4) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.tween_callback(light.queue_free)


# ── Drainfriend entropy: drag a peer back one step on FOE catch ─────
# Called from somewhere (parent's contact damage handler triggers
# caught_player; this is bound elsewhere). Walks one non-foe creature
# back ONE step along the personality arc.

func drag_one_friend_back() -> void:
	var candidates: Array[CatalystFoe] = []
	for n in get_tree().get_nodes_in_group("catalyst_foe"):
		var f := n as CatalystFoe
		if f and f != self and f._personality != "foe":
			candidates.append(f)
	if candidates.is_empty():
		return
	var v: CatalystFoe = candidates[randi() % candidates.size()]
	# SPLITTER (fractal lineage): a fractal FRIEND refuses the drag — it
	# spawns one clone of itself instead of stepping back (max 2 clones).
	if v._personality == "friend" and v._locked_mode_id == "fractal":
		v._splitter_spawn_clone()
		return
	var prev: String = v._personality
	var idx: int = PERSONALITY_ARC.find(prev)
	if idx > 0:
		v.set_personality(PERSONALITY_ARC[idx - 1])
		v._apply_state_visuals_for_personality(v._personality)
		v.personality_changed.emit(prev, v._personality)


# ── SHIELD (primitives lineage) ─────────────────────────────────────
# The friend orbits the player (curious-orbit pattern, tighter ring) and
# can absorb one incoming hit every SHIELD_COOLDOWN_S. The manager-side
# damage path (FriendPowerGuard.try_absorb) calls absorb_hit().

func _process_shield_orbit(delta: float) -> void:
	# Curious-orbit movement at ~2.5m — the shield stays close.
	if not is_instance_valid(_player_node):
		velocity = velocity.move_toward(Vector3.ZERO, 0.2)
		return
	var to_player: Vector3 = _player_node.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()
	if dist < 0.01:
		velocity = velocity.move_toward(Vector3.ZERO, 0.2)
		return
	var orbit_dist := 2.5
	var orbit_speed: float = patrol_speed * _approach_speed_factor
	if dist > orbit_dist + 1.0:
		# Move toward orbit radius
		var move_dir := to_player.normalized()
		velocity.x = move_dir.x * orbit_speed
		velocity.z = move_dir.z * orbit_speed
		_face_direction(move_dir, delta * 3.0)
	elif dist < orbit_dist - 1.0:
		# Too close, back off
		var away_dir := -to_player.normalized()
		velocity.x = away_dir.x * orbit_speed * 0.5
		velocity.z = away_dir.z * orbit_speed * 0.5
	else:
		# Orbit: perpendicular movement
		var perp := Vector3(-to_player.normalized().z, 0, to_player.normalized().x)
		velocity.x = perp.x * orbit_speed
		velocity.z = perp.z * orbit_speed
		_face_direction(to_player.normalized(), delta * 2.0)
	velocity.y = 0.0


## Called from the player damage path. True = this friend ate the hit and
## starts its 10s cooldown; false = not a settled shield friend, or still
## recharging (the caller keeps scanning / lets the damage through).
func absorb_hit() -> bool:
	if _personality != "friend" or _locked_mode_id != "primitives":
		return false
	var now: float = _now_s()
	if now < _shield_ready_at:
		return false
	_shield_ready_at = now + SHIELD_COOLDOWN_S
	_flash_shield_absorb()
	return true


func _flash_shield_absorb() -> void:
	# White pop on absorb, then dimmed emission for the cooldown window.
	if _custom_mat == null:
		return
	_custom_mat.albedo_color = Color.WHITE
	_custom_mat.emission = Color.WHITE
	_custom_mat.emission_energy_multiplier = 5.0
	var t := create_tween()
	t.tween_property(_custom_mat, "emission_energy_multiplier", 0.35, 0.5) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.tween_interval(SHIELD_COOLDOWN_S - 0.5)
	t.tween_callback(_apply_state_visuals_for_personality.bind(_personality))


# ── ESCORT (swarm lineage) ──────────────────────────────────────────
# Friends hold fixed angular slots on a 1.5m ring between the player and
# the nearest foe. A foe that touches an escort friend is shoved 2m
# directly away from the player (reverse-TRANSPORT).

func _process_escort_movement(delta: float) -> void:
	if not is_instance_valid(_player_node):
		velocity = velocity.move_toward(Vector3.ZERO, 0.2)
		return
	var ppos: Vector3 = _player_node.global_position
	# Ring faces the nearest threat; fall back to world-forward when calm.
	var base_dir: Vector3 = Vector3.FORWARD
	var threat: CatalystFoe = _nearest_non_friend_to(ppos)
	if threat != null:
		var to_threat: Vector3 = threat.global_position - ppos
		to_threat.y = 0.0
		if to_threat.length() > 0.01:
			base_dir = to_threat.normalized()
	# Fixed slot by order in the group — no clumping.
	var idx: int = 0
	var total: int = 0
	for n in get_tree().get_nodes_in_group("catalyst_foe"):
		var f := n as CatalystFoe
		if f == null or f._personality != "friend" or f._locked_mode_id != "swarm":
			continue
		if f == self:
			idx = total
		total += 1
	var slot_offset: float = (float(idx) - float(total - 1) * 0.5) * 0.7
	var slot: Vector3 = ppos + base_dir.rotated(Vector3.UP, slot_offset) * 1.5
	var to_slot: Vector3 = slot - global_position
	to_slot.y = 0.0
	if to_slot.length() > 0.2:
		var dir: Vector3 = to_slot.normalized()
		var sp: float = chase_speed * _approach_speed_factor
		velocity.x = dir.x * sp
		velocity.z = dir.z * sp
		_face_direction(base_dir, delta * 3.0)
	else:
		velocity.x = velocity.x * 0.8
		velocity.z = velocity.z * 0.8
		_face_direction(base_dir, delta * 2.0)
	velocity.y = 0.0


func _escort_shove_tick() -> void:
	# Contact check — any non-friend foe touching this escort friend gets
	# shoved 2m away from the player (same code shape as TRANSPORT's push).
	if not is_instance_valid(_player_node):
		return
	for n in get_tree().get_nodes_in_group("catalyst_foe"):
		var f := n as CatalystFoe
		if f == null or f == self or f._personality == "friend":
			continue
		if f.global_position.distance_to(global_position) > 0.6:
			continue
		var away: Vector3 = f.global_position - _player_node.global_position
		away.y = 0
		if away.length() > 0.001:
			away = away.normalized()
			f.global_position += Vector3(round(away.x) * 2.0, 0, round(away.z) * 2.0)


# ── CALMER (waveform lineage) ───────────────────────────────────────
# Pulses every CALMER_PULSE_INTERVAL_S: non-friend foes within 3m get
# chase_speed halved for CALMER_SLOW_DURATION_S, then restored to their
# remembered base (metas; restore lives in HazardCreatureBase so it can
# never become permanent). Repeat pulses never stack below 25% of base.

func _calmer_tick(delta: float) -> void:
	_calmer_pulse_timer += delta
	if _calmer_pulse_timer < CALMER_PULSE_INTERVAL_S:
		return
	_calmer_pulse_timer = 0.0
	_pulse_calm()


func _pulse_calm() -> void:
	for n in get_tree().get_nodes_in_group("catalyst_foe"):
		var f := n as CatalystFoe
		if f == null or f == self or f._personality == "friend":
			continue
		if f.global_position.distance_to(global_position) <= 3.0:
			_apply_timed_slow(f)


func _apply_timed_slow(f: HazardCreatureBase) -> void:
	if f == null or not is_instance_valid(f):
		return
	if not f.has_meta("calmer_base_speed"):
		f.set_meta("calmer_base_speed", f.chase_speed)
	var base_speed: float = float(f.get_meta("calmer_base_speed"))
	f.chase_speed = max(base_speed * 0.25, f.chase_speed * 0.5)
	f.set_meta("calmer_slow_until", _now_s() + CALMER_SLOW_DURATION_S)


# ── SPLITTER (fractal lineage) ──────────────────────────────────────
# Invoked from drag_one_friend_back's victim handling: instead of
# stepping back, the fractal friend spawns ONE clone of itself (same
# scene, seeded friend/fractal) at a 1m offset. Max 2 clones per
# original, tracked via the "splitter_clones" meta.

func _splitter_spawn_clone() -> void:
	var clone_count: int = 0
	if has_meta("splitter_clones"):
		clone_count = int(get_meta("splitter_clones"))
	if clone_count >= 2:
		return
	var path: String = scene_file_path
	if path.is_empty():
		path = "res://commons/hazards/catalyst_foe/catalyst_foe.tscn"
	if not ResourceLoader.exists(path):
		return
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return
	var parent: Node = get_parent()
	if parent == null:
		return
	var clone: Node = packed.instantiate()
	parent.add_child(clone)
	if clone is Node3D:
		(clone as Node3D).global_position = global_position + Vector3(1.0, 0.0, 0.0)
	if clone.has_method("apply_grid_config"):
		clone.apply_grid_config({"initial_state": "friend", "foe_mode": "fractal"})
	set_meta("splitter_clones", clone_count + 1)


# ── PORTER (transformation lineage) ─────────────────────────────────
# When the player stands near a void edge (no floor 1.2m ahead) and this
# friend is within 4m, it walks to the gap and PARKS: movement off, a
# 1x0.2x1 StaticBody3D platform on world layer 1, group "path_passable".
# Un-parks after 20s or when the player moves >6m away. Only one parked
# porter at a time (group "porter_parked").

func _porter_tick(delta: float) -> void:
	# IDLE-side scan only — WALKING/PARKED run through _porter_physics.
	_porter_scan_timer -= delta
	if _porter_scan_timer > 0.0:
		return
	_porter_scan_timer = 0.3
	if not is_instance_valid(_player_node):
		return
	if global_position.distance_to(_player_node.global_position) > 4.0:
		return
	if not get_tree().get_nodes_in_group("porter_parked").is_empty():
		return  # one parked porter at a time
	var gap: Vector3 = _find_void_gap_ahead_of_player()
	if gap == Vector3.INF:
		return
	_porter_goal = gap
	_porter_state = PorterState.WALKING


## Probe 1.2m in front of the player at floor height with a downward
## space-state ray. Returns the gap position, or Vector3.INF when there
## is floor (no gap) or the probe cannot run.
func _find_void_gap_ahead_of_player() -> Vector3:
	if not is_instance_valid(_player_node) or not is_inside_tree():
		return Vector3.INF
	var fwd: Vector3 = -_player_node.global_transform.basis.z
	fwd.y = 0.0
	if fwd.length() < 0.01:
		return Vector3.INF
	fwd = fwd.normalized()
	var ppos: Vector3 = _player_node.global_position
	var probe: Vector3 = ppos + fwd * 1.2
	var world := get_world_3d()
	if world == null:
		return Vector3.INF
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(probe.x, ppos.y + 0.5, probe.z),
		Vector3(probe.x, ppos.y - 0.5, probe.z),
		1)  # world layer only
	var hit: Dictionary = world.direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		return Vector3.INF  # floor present — no gap
	return Vector3(probe.x, ppos.y, probe.z)


func _porter_physics(delta: float) -> void:
	# Replaces the base state machine while walking to the gap / parked.
	if _porter_state == PorterState.WALKING:
		if not is_instance_valid(_player_node) \
				or global_position.distance_to(_player_node.global_position) > 8.0:
			_porter_state = PorterState.IDLE
			return
		var to_goal: Vector3 = _porter_goal - global_position
		to_goal.y = 0.0
		if to_goal.length() <= 0.25:
			_porter_park()
			return
		var dir: Vector3 = to_goal.normalized()
		velocity.x = dir.x * chase_speed
		velocity.z = dir.z * chase_speed
		velocity.y = 0.0
		_face_direction(dir, delta * 3.0)
		move_and_slide()
	elif _porter_state == PorterState.PARKED:
		velocity = Vector3.ZERO
		var player_far: bool = not is_instance_valid(_player_node) \
			or global_position.distance_to(_player_node.global_position) > 6.0
		if _now_s() >= _porter_park_until or player_far:
			_porter_unpark()


func _porter_park() -> void:
	_porter_state = PorterState.PARKED
	_porter_park_until = _now_s() + 20.0
	global_position = Vector3(_porter_goal.x, global_position.y, _porter_goal.z)
	velocity = Vector3.ZERO
	add_to_group("porter_parked")
	add_to_group("path_passable")
	# Walkable platform: 1 x 0.2 x 1 box on world layer 1, top level with
	# this creature's base (body is a 0.3m cube centered at origin).
	_porter_platform = StaticBody3D.new()
	_porter_platform.name = "PorterPlatform"
	_porter_platform.collision_layer = 1
	_porter_platform.collision_mask = 0
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, 0.2, 1.0)
	col.shape = box
	_porter_platform.add_child(col)
	add_child(_porter_platform)
	_porter_platform.position = Vector3(0, -0.25, 0)


func _porter_unpark() -> void:
	_porter_state = PorterState.IDLE
	_porter_scan_timer = 1.0  # brief refractory before re-parking
	if is_in_group("porter_parked"):
		remove_from_group("porter_parked")
	if is_in_group("path_passable"):
		remove_from_group("path_passable")
	if _porter_platform != null and is_instance_valid(_porter_platform):
		_porter_platform.queue_free()
	_porter_platform = null


# ── BRIDGER (branching lineage) ─────────────────────────────────────
# When the player stands within 3m of a DangerZone (group "danger_zone")
# and this friend is within 5m of the player, call the tendril helper.
# At most once per 5s per friend. The helper file may land after this
# one — load is gated on ResourceLoader.exists so this always compiles.

func _bridger_tick(delta: float) -> void:
	_bridger_scan_timer -= delta
	if _bridger_scan_timer > 0.0:
		return
	_bridger_scan_timer = 0.5
	var now: float = _now_s()
	if now < _bridger_next_grow:
		return
	if not is_instance_valid(_player_node):
		return
	var ppos: Vector3 = _player_node.global_position
	if global_position.distance_to(ppos) > 5.0:
		return
	var near_zone: bool = false
	for z in get_tree().get_nodes_in_group("danger_zone"):
		if z is Node3D and (z as Node3D).global_position.distance_to(ppos) <= 3.0:
			near_zone = true
			break
	if not near_zone:
		return
	var tendril = _get_tendril_script()
	if tendril == null:
		return
	tendril.call("try_grow", get_tree(), global_position, ppos)
	_bridger_next_grow = now + 5.0


func _get_tendril_script():
	# Contract (owned by another agent):
	#   static func try_grow(tree: SceneTree, friend_pos: Vector3,
	#       player_pos: Vector3) -> bool
	if not _tendril_checked:
		_tendril_checked = true
		if ResourceLoader.exists(BRIDGER_TENDRIL_PATH):
			_tendril_script = load(BRIDGER_TENDRIL_PATH)
	return _tendril_script


# ── Configuration extension ─────────────────────────────────────────
# Parent's apply_grid_config calls configure() (health/speed/damage).
# We add catalyst-specific keys: initial_state (personality seed)
# and foe_mode (friend kind seed).

func apply_grid_config(config: Dictionary) -> void:
	super.apply_grid_config(config)

	# foe_mode seed — only meaningful when seeded as FRIEND, but lock
	# it any time so subsequent catalyst hits respect the request.
	var FOE_MODE_BY_NAME: Dictionary = {
		"goo":         FoeMode.GOO,
		"transport":   FoeMode.TRANSPORT,
		"swarm":       FoeMode.SWARM,
		"drainfriend": FoeMode.DRAINFRIEND,
		"chroma":      FoeMode.CHROMA,
		"wave":        FoeMode.WAVE,
		"fractal":     FoeMode.FRACTAL,
		"branch":      FoeMode.BRANCH,
	}
	if config.has("foe_mode"):
		var fm_str: String = String(config.get("foe_mode", "")).to_lower()
		if FOE_MODE_BY_NAME.has(fm_str):
			foe_mode = FOE_MODE_BY_NAME[fm_str]
			_locked_mode_id = _canonical_mode_for(foe_mode)
		elif MODE_BY_ID.has(fm_str) or fm_str == "primitives":
			# Exact lineage ids are accepted too ("chaos", "waveform",
			# "cellular", ...) so seeded friends in test maps carry the
			# precise lineage their power gates on.
			foe_mode = MODE_BY_ID.get(fm_str, FoeMode.GOO)
			_locked_mode_id = fm_str

	# critter_stage — soft_stages order override for the evolving pink
	# critter (maps/vents pin a stage; unseeded foes ask HazardManager).
	if config.has("critter_stage"):
		_critter_stage_order = float(config.get("critter_stage", -1.0))
		_critter_stage_cache = {}
		if _mesh_root != null:
			_rebuild_critter_visuals()

	# initial_state — personality seed. Parent's set_personality fires
	# behaviour-flag dispatch; we add visual sync. Sets _personality_seeded
	# so the deferred HazardManager query doesn't override.
	if config.has("initial_state"):
		var initial: String = String(config.get("initial_state", "foe")).to_lower()
		if initial in PERSONALITY_ARC:
			set_personality(initial)
			_apply_state_visuals_for_personality(initial)
			if initial == "friend":
				_build_friend_badge()
			_personality_seeded = true


# Override parent's deferred HazardManager query so a seeded personality
# wins over the curriculum default.
func _query_hazard_manager() -> void:
	if _personality_seeded:
		return
	super._query_hazard_manager()


# Override parent's set_personality to also update visuals.
func set_personality(personality: String) -> void:
	super.set_personality(personality)
	_apply_state_visuals_for_personality(personality)


# ── Override contact damage: use existing GameManager flow ──────────
# Parent's damage routing is via collision; we keep the existing
# direct GameManager.set_health() flow plus the caught_player signal
# and DRAINFRIEND drag-back hook.

func _try_damage_target(target: Object) -> bool:
	# Only FOEs (current personality "foe") deal contact damage.
	# Parent's _can_damage flag already gates this in _handle_contact_damage,
	# but we also emit caught_player + run drainfriend entropy here.
	if not super._try_damage_target(target):
		return false
	caught_player.emit()
	if foe_mode == FoeMode.DRAINFRIEND:
		drag_one_friend_back()
	# The pink critter is a balloon: landing its hit costs its life.
	if _personality == "foe" and bool(_critter_stage().get("pop", false)):
		_blow_up()
	return true
