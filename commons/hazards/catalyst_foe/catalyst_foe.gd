# @identity
# essence: a HazardCreatureBase subclass that the catalyst phase-shifts through 5 personality stages — extends the project's shared personality system with catalyst-specific dispatch
# desire: to embody the unifying enemy principle in VR -- the angry are biome-borne, the catalyst doesn't kill, transformation propagates one notch at a time
# critical_parameter: foe_mode -- locked at FIRST catalyst hit; determines FRIEND peer-conversion behaviour (GOO converts, TRANSPORT pushes, SWARM speeds up, DRAINFRIEND drags peers back)
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
#   - foe_mode (GOO/TRANSPORT/SWARM/DRAINFRIEND) — catalyst-specific
#   - hit_by_catalyst_mode() entry point for catalyst projectile
#   - One-step-per-hit personality arc advancement
#   - FRIEND peer-conversion behavior (override _process_chase)
#   - Per-foe_mode visual badge (wedge / satellites / drain pyramid)
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
# Each catalyst hit walks the creature ONE step along this list. The
# string values match HazardCreatureBase._apply_personality matches.
const PERSONALITY_ARC: Array[String] = [
	"foe", "wary", "neutral", "curious", "friend",
]


# ── Foe Mode ────────────────────────────────────────────────────────
# Locked at the FIRST catalyst hit (the one that takes the creature out
# of "foe"); determines FRIEND peer-conversion behavior at the end of
# the arc. Mirrors the editor's per-sequence enemy kinds.
enum FoeMode { GOO, TRANSPORT, SWARM, DRAINFRIEND }
var foe_mode: FoeMode = FoeMode.GOO

const MODE_BY_ID: Dictionary = {
	"transformation": FoeMode.TRANSPORT,
	"forces":         FoeMode.SWARM,
	"swarm":          FoeMode.SWARM,
	"chaos":          FoeMode.SWARM,
	"cellular":       FoeMode.DRAINFRIEND,
	# everything else → GOO (default)
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


# ── Lifecycle (parent calls these in order from its _ready) ─────────

func _create_materials() -> void:
	# Subtle grey-goo body tint with small per-instance variation so
	# multiple foes spawned from the same vent look distinguishable.
	_custom_mat = StandardMaterial3D.new()
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
	# 0.3m grey-tinted cube — the catalyst-foe's silhouette.
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.3, 0.3)
	_add_mesh(box, _custom_mat)


func _on_ready() -> void:
	add_to_group("catalyst_foe")
	# If apply_grid_config seeded a personality BEFORE _ready (which is
	# the order when the map composer or capture rig calls it right
	# after instantiate), the visuals couldn't apply yet (_custom_mat
	# was null). Re-apply now that materials exist.
	_apply_state_visuals_for_personality(_personality)
	if _personality == "friend":
		_build_friend_badge()


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
		# Step rate per mode (matches editor's stepMul).
		if foe_mode == FoeMode.SWARM:
			chase_speed = chase_speed * 1.4  # faster
		elif foe_mode == FoeMode.DRAINFRIEND:
			chase_speed = chase_speed * 0.85  # slower
	# Update personality via parent (sets behaviour flags).
	set_personality(next_personality)
	personality_changed.emit(prev, next_personality)

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


# ── Override _process_chase for FRIEND peer-conversion ──────────────
# Parent handles foe/wary/neutral/curious chase variants beautifully.
# FRIEND is unique to catalyst_foe — chase nearest non-friend foe.

func _process_chase(delta: float) -> void:
	if _personality == "friend":
		_process_friend_chase(delta)
	else:
		super._process_chase(delta)


func _process_friend_chase(delta: float) -> void:
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
			_:
				# Default (GOO / SWARM / DRAINFRIEND): convert peer
				if _custom_mat != null:
					target.hit_by_catalyst_mode(_custom_mat.albedo_color, _mode_id_for_dispatch())
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
	var best: CatalystFoe = null
	var best_d: float = INF
	for n in get_tree().get_nodes_in_group("catalyst_foe"):
		var f := n as CatalystFoe
		if f == null or f == self or f._personality == "friend":
			continue
		var d: float = f.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = f
	return best


func _mode_id_for_dispatch() -> String:
	match foe_mode:
		FoeMode.TRANSPORT:   return "transformation"
		FoeMode.SWARM:       return "swarm"
		FoeMode.DRAINFRIEND: return "cellular"
		_:                   return "primitives"


func _friend_hue_for_mode(m: FoeMode) -> Color:
	match m:
		FoeMode.GOO:         return Color(0.30, 0.78, 0.42)   # mint green
		FoeMode.TRANSPORT:   return Color(0.20, 0.55, 0.95)   # sky blue
		FoeMode.SWARM:       return Color(0.95, 0.50, 0.18)   # warm orange
		FoeMode.DRAINFRIEND: return Color(0.65, 0.30, 0.85)   # violet
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


# ── Hit visuals ─────────────────────────────────────────────────────

func _spawn_hit_burst(burst_color: Color) -> void:
	var burst := GPUParticles3D.new()
	burst.amount = 24
	burst.lifetime = 0.6
	burst.one_shot = true
	burst.explosiveness = 0.95
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 1.5
	pmat.initial_velocity_max = 3.5
	pmat.gravity = Vector3(0, -1.5, 0)
	pmat.scale_min = 0.05
	pmat.scale_max = 0.12
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


func _spawn_light_pulse(light_color: Color) -> void:
	var light := OmniLight3D.new()
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
	var prev: String = v._personality
	var idx: int = PERSONALITY_ARC.find(prev)
	if idx > 0:
		v.set_personality(PERSONALITY_ARC[idx - 1])
		v._apply_state_visuals_for_personality(v._personality)
		v.personality_changed.emit(prev, v._personality)


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
	}
	if config.has("foe_mode"):
		var fm_str: String = String(config.get("foe_mode", "")).to_lower()
		if FOE_MODE_BY_NAME.has(fm_str):
			foe_mode = FOE_MODE_BY_NAME[fm_str]

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
	return true
