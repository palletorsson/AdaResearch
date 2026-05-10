# @identity
# essence: state(FOE|FRIEND) + position + chase_target -- a biome-borne body that the catalyst phase-shifts
# desire: to embody the unifying enemy principle in VR -- the angry are biome-borne, the catalyst doesn't kill, transformation propagates
# critical_parameter: state -- FOE chases the player (caught = respawn); FRIEND chases nearest FOE and converts on contact (peer infection)
# triggers: hit_by_projectile() -- catalyst contact flips state; _physics_process() walks gridded BFS step every step_period_s; touching player or peer foe fires the contact rule
# emerges: a flock of color walking toward the next angry thing -- the catalyst becomes the world
# needs: collision_layer 2 [has, matches catalyst_projectile contract]; CharacterBody3D [has]; navigation via simple grid step (MVP) [has]; player ref [discovered via group "player"]
# relationships: spawned by catalyst_vent; mirrors the /editor catalyst loop in VR; the bracelet's projectile is the catalyst transformation
# truth: the catalyst doesn't kill -- it phase-shifts; what was alone becomes a flock walking toward the next angry thing.

# catalyst_foe.gd
# Biome-borne foe that the catalyst phase-shifts into a friend.
# State machine: FOE -> FRIEND (irreversible — phase transition).
# - FOE chases the player; on contact, respawns the player.
# - FRIEND chases nearest FOE; on contact, converts the FOE into a friend.
#
# Hit contract: hit_by_catalyst_mode(color, mode_id) + hit_by_projectile(color).
# Uses StaticBody3D rather than CharacterBody3D for reliable projectile
# collision detection (the CharacterBody3D physics body wasn't always
# triggering body_entered on the projectile in headless tests). Movement
# is animated via direct global_position assignment which works fine on
# StaticBody3D.
extends StaticBody3D
class_name CatalystFoe

# Verbose lifecycle / hit logging. Off by default — flip on locally when
# diagnosing transformation dispatch or vent emission.
const DEBUG_LOG: bool = false

# ── State (5-step personality arc) ───────────────────────────────────
# The catalyst doesn't flip a binary switch — it WALKS A CREATURE through
# stages of warming. FOE is hostile; WARY keeps distance and watches;
# NEUTRAL ignores the player and wanders; CURIOUS approaches peacefully
# and may follow; FRIEND chases other foes to convert them. Each catalyst
# hit advances ONE step. Per-sequence map data can also seed the starting
# state via apply_grid_config(initial_state=...).
#
# Mapping to the curriculum's three acts (from doc/CATALYST design):
#   Lab (seq 1-5)      → spawn as FOE
#   Mid-lab (seq 6-8)  → spawn as WARY
#   Nature (seq 9-11)  → spawn as NEUTRAL
#   Nature-end (12-14) → spawn as CURIOUS
#   Emergence (15+)    → spawn as FRIEND
enum FoeState { FOE, WARY, NEUTRAL, CURIOUS, FRIEND }
var state: FoeState = FoeState.FOE

# Cells per second the body advances toward its goal.
@export var step_period_s: float = 0.7
# How close to the goal counts as "contact".
@export var contact_radius: float = 0.6
# Damage inflicted on the player per contact event, expressed as a
# percentage of GameManager.max_player_health (so 10 = 10% = 10 hp).
@export var damage_percent: float = 10.0
# Minimum seconds between damage applications — prevents spam if the
# foe sits on the player for several frames.
@export var damage_cooldown_s: float = 0.6
var _last_damage_t: float = -1e9
# Random hue selected on FRIEND transition (overridden by projectile color if provided).
const FRIEND_HUES: Array[Color] = [
	Color(0.93, 0.28, 0.60),  # pink
	Color(0.09, 0.64, 0.28),  # green
	Color(0.96, 0.62, 0.05),  # amber
	Color(0.15, 0.39, 0.92),  # blue
	Color(0.66, 0.33, 0.97),  # purple
	Color(0.40, 0.64, 0.12),  # lime
]

# ── Visuals ──────────────────────────────────────────────────────────
var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _collision: CollisionShape3D
var _step_timer: float = 0.0

# ── References ───────────────────────────────────────────────────────
var _player_ref: Node3D
var _spawn_pos: Vector3


func _ready() -> void:
	add_to_group("catalyst_foe")
	# Layer 2 — same as catalyst_target. The catalyst projectile mask is
	# 2 (post-2026-05-04), which ignores world cubes (layer 1) to avoid
	# hitting the GridStructureComponent's MultiMesh floor/wall cubes
	# before reaching the foe.
	collision_layer = 2
	collision_mask = 0

	_spawn_pos = global_position
	_build_visual()
	# Collision shape now declared in the .tscn so it exists from frame 0.
	# Only build one in script if the .tscn version is somehow missing.
	_collision = get_node_or_null("CollisionShape3D")
	if _collision == null:
		_build_collision()
	_apply_state_visuals()

	# Find player lazily; we'll re-search if it disappears.
	_player_ref = _find_player()
	if DEBUG_LOG:
		print("[CatalystFoe] spawned at %s; player found: %s%s" % [
			global_position,
			"yes" if _player_ref != null else "no — will wander",
			(" (" + _player_ref.name + " at " + str(_player_ref.global_position) + ")") if _player_ref != null else "",
		])


func _build_visual() -> void:
	# Half-size cube — less spatial dominance, easier to surround a
	# corridor with several without filling the cell.
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.3, 0.3)
	_mesh.mesh = box
	# Each foe gets ITS OWN fresh material with a slightly varied
	# grey-goo tint so when many spawn from the same vent they look
	# distinguishable rather than copy-pasted. The variation is small
	# enough to still read as "the angry, before catalyst" — different
	# shades of the same dark grey rather than fully different colors.
	_mat = StandardMaterial3D.new()
	var hue: float = randf_range(0.0, 1.0)
	var grey_jitter: float = randf_range(0.07, 0.16)
	_mat.albedo_color = Color(grey_jitter, grey_jitter, grey_jitter + 0.02)
	_mat.emission_enabled = true
	# Subtle emission shift — slight blue/purple tint to read as "biome corruption"
	var emis_v: float = randf_range(0.78, 0.88)
	_mat.emission = Color(emis_v, emis_v, emis_v + 0.04)
	_mat.emission_energy_multiplier = randf_range(0.55, 0.85)
	_mat.roughness = randf_range(0.78, 0.92)
	_mesh.material_override = _mat
	add_child(_mesh)


func _build_collision() -> void:
	_collision = CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(0.3, 0.3, 0.3)
	_collision.shape = s
	add_child(_collision)


# ── Catalyst contract ────────────────────────────────────────────────
# Two methods, called by catalyst_projectile in priority order:
#   hit_by_catalyst_mode(color, mode_id)  — rich; per-sequence variants
#   hit_by_projectile(color)              — legacy; what catalyst_target uses
#
# We implement both. The rich form dispatches on mode_id to mirror the
# editor's per-sequence enemy kinds:
#   primitives / wavefunctions / fractal / lsystems → goo (convert)
#   transformation                                 → transport (push peers)
#   forces / swarm / chaos                         → swarm (faster reset)
#   cellular                                       → drainfriend (entropy)
#   chromatic                                      → goo (color = hue)
# Anything else falls through to convert.

# Active behavioral verb. Set at hit time; stays for this foe's lifetime
# so the friend keeps the mode that turned it.
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


func hit_by_projectile(color: Color) -> void:
	# Legacy entry — assume primitives mode (goo).
	if DEBUG_LOG:
		print("[CatalystFoe] hit_by_projectile called, color=%s — routing as 'primitives'" % color)
	hit_by_catalyst_mode(color, "primitives")


func hit_by_catalyst_mode(color: Color, mode_id: String) -> void:
	if DEBUG_LOG:
		print("[CatalystFoe] hit_by_catalyst_mode called: mode_id='%s', current state=%d" % [
			mode_id, state])
	if state == FoeState.FRIEND:
		if DEBUG_LOG:
			print("[CatalystFoe] already FRIEND — ignoring")
		return
	# Advance ONE step along the personality arc, not all the way to FRIEND.
	# This is the queer-relational principle: the catalyst doesn't transform
	# in one blow; it warms a creature one notch at a time. A foe needs 4
	# hits across the curriculum to become a friend.
	var prev_state: FoeState = state
	state = (state + 1) as FoeState
	# Lock in the foe_mode at the FIRST hit so the friend keeps the mode of
	# the catalyst that started its arc.
	if prev_state == FoeState.FOE:
		foe_mode = MODE_BY_ID.get(mode_id, FoeMode.GOO)
	# Update visuals for the new personality state. FRIEND-specific colour
	# (palette / emission burst) is then applied below by the FRIEND path.
	_apply_state_visuals()
	personality_changed.emit(prev_state, state)
	# Stages BEFORE FRIEND get a brief flash but no friend-coloured pop —
	# their visuals are set by _apply_state_visuals above. Only on the
	# FRIEND transition do we run the colour-locking pop + burst below.
	if state != FoeState.FRIEND:
		_spawn_hit_burst(_mat.emission)
		_spawn_light_pulse(_mat.emission)
		return
	# Step rate per mode (matches editor's stepMul).
	if foe_mode == FoeMode.SWARM:
		step_period_s = max(0.3, step_period_s * 0.7)
	elif foe_mode == FoeMode.DRAINFRIEND:
		step_period_s = step_period_s * 1.1
	# Use the projectile's color if the mode supplied one; otherwise
	# pick a random kingdom hue. The catalyst restored colour.
	var c: Color = color
	if c == Color(0, 0, 0, 0):
		c = FRIEND_HUES[randi() % FRIEND_HUES.size()]
	# Guard _mat — if hit fires before _ready (rare; only in tests),
	# defer the visual update until the material exists.
	if _mat != null:
		_mat.albedo_color = c
		_mat.emission = c
		# Big initial flash — punches up to 5x then settles to 1.6x.
		_mat.emission_energy_multiplier = 5.0
		# Animate emission decay alongside the scale pop.
		var emis_tween := create_tween()
		emis_tween.tween_property(_mat, "emission_energy_multiplier", 1.6, 0.6) \
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

		# Squash-stretch transformation pop. Squash flat first (anticipation),
		# overshoot big, settle. Three keyframes via chained tweens.
		var pop := create_tween()
		pop.set_parallel(false)
		# 1) Anticipation squash — flatten to half-height for 0.05s
		pop.tween_property(self, "scale", Vector3(1.4, 0.5, 1.4), 0.05) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# 2) Overshoot — explode up to 1.7x for 0.18s
		pop.tween_property(self, "scale", Vector3(1.7, 1.7, 1.7), 0.18) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		# 3) Settle — back to normal with elastic bounce
		pop.tween_property(self, "scale", Vector3.ONE, 0.35) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

		# Particle burst at the foe's position — colored to match the
		# catalyst that hit it. Lives 0.6s then frees itself.
		_spawn_hit_burst(c)
		# Brief point-light pulse so the moment lights up nearby surfaces.
		_spawn_light_pulse(c)


# ── Movement ─────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	_step_timer += delta
	if _step_timer < step_period_s:
		return
	_step_timer = 0.0

	if not is_instance_valid(_player_ref):
		_player_ref = _find_player()

	# State-specific movement.
	#   FOE      — chase player (current behaviour, with damage on touch)
	#   WARY     — keep distance: flee when player is close, else hold ground
	#   NEUTRAL  — ignore player, wander
	#   CURIOUS  — approach player slowly, no damage on touch
	#   FRIEND   — chase nearest non-friend foe to convert peer
	var goal: Vector3
	var has_goal := false
	var step_mul: float = 1.0  # CURIOUS moves slower; WARY moves faster (alarm)

	if state == FoeState.FOE and is_instance_valid(_player_ref):
		goal = _player_ref.global_position
		has_goal = true
	elif state == FoeState.WARY and is_instance_valid(_player_ref):
		# Flee if the player is too close; otherwise hold ground.
		var dist := global_position.distance_to(_player_ref.global_position)
		var watch_radius: float = 4.0
		if dist < watch_radius:
			# Pick a goal AWAY from the player.
			var away_dir := (global_position - _player_ref.global_position)
			away_dir.y = 0.0
			if away_dir.length() > 0.001:
				goal = global_position + away_dir.normalized() * 2.0
				has_goal = true
				step_mul = 0.85  # quick alert backstep
		# else: just stand still this step
	elif state == FoeState.NEUTRAL:
		# Pure wander, ignore player.
		var dirs: Array[Vector3] = [
			Vector3(1, 0, 0), Vector3(-1, 0, 0),
			Vector3(0, 0, 1), Vector3(0, 0, -1),
		]
		global_position += dirs[randi() % dirs.size()]
		return
	elif state == FoeState.CURIOUS and is_instance_valid(_player_ref):
		goal = _player_ref.global_position
		has_goal = true
		step_mul = 1.4  # slower step (multiplier on period — bigger = slower)
	elif state == FoeState.FRIEND:
		var target := _nearest_other_foe()
		if target != null:
			goal = target.global_position
			has_goal = true

	if not has_goal:
		# WARY at safe distance, or no player — gentle wander.
		var dirs2: Array[Vector3] = [
			Vector3(1, 0, 0), Vector3(-1, 0, 0),
			Vector3(0, 0, 1), Vector3(0, 0, -1),
		]
		global_position += dirs2[randi() % dirs2.size()]
		return

	# Step one cell (1 m) toward the goal along the dominant axis.
	var diff := goal - global_position
	diff.y = 0.0
	if diff.length() < 0.05:
		return
	var step: Vector3
	if abs(diff.x) > abs(diff.z):
		step = Vector3(sign(diff.x), 0.0, 0.0)
	else:
		step = Vector3(0.0, 0.0, sign(diff.z))
	global_position += step
	# Apply step_mul to the next-step delay so CURIOUS lingers, WARY darts.
	if step_mul != 1.0:
		_step_timer = -step_period_s * (step_mul - 1.0)

	# Contact resolution.
	if state == FoeState.FRIEND:
		var t := _nearest_other_foe()
		if t and global_position.distance_to(t.global_position) < contact_radius * 2.0:
			match foe_mode:
				FoeMode.TRANSPORT:
					# Push the foe AWAY from the player by 2 cells along
					# the player→foe vector. Path-clearing instead of
					# conversion. The pushed foe stays a foe.
					if is_instance_valid(_player_ref):
						var away := (t.global_position - _player_ref.global_position)
						away.y = 0
						if away.length() > 0.001:
							away = away.normalized()
							t.global_position += Vector3(round(away.x) * 2.0, 0, round(away.z) * 2.0)
				_:
					# Default (GOO / SWARM / DRAINFRIEND): convert peer.
					t.hit_by_catalyst_mode(_mat.albedo_color, _mode_id_for_dispatch())
	elif state == FoeState.FOE and is_instance_valid(_player_ref):
		if global_position.distance_to(_player_ref.global_position) < contact_radius * 2.0:
			caught_player.emit()
			_apply_damage_to_player()
			# DRAINFRIEND: the foe's catch also drags one friend back to
			# foe — entropy. (Note: only fires when this foe carries the
			# drainfriend mode, which only happens via friend-on-friend
			# inheritance after a cellular projectile.)
			if foe_mode == FoeMode.DRAINFRIEND:
				_drag_one_friend_back()
	elif state == FoeState.CURIOUS and is_instance_valid(_player_ref):
		# CURIOUS approaches but never harms — emits a soft signal so the
		# game can react (small particle, sparkle, etc.) without damage.
		if global_position.distance_to(_player_ref.global_position) < contact_radius * 2.0:
			curious_contact.emit()


# ── Hit visual effects (burst + light flash) ────────────────────────

# A short-lived particle burst at the foe's position. Color matches
# the catalyst mode that hit. Self-frees after lifetime.
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
	# Tiny sphere mesh for each particle
	var sphere := SphereMesh.new()
	sphere.radius = 0.04
	sphere.height = 0.08
	burst.draw_pass_1 = sphere
	# Self-luminous so the burst reads bright on dark backgrounds
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = burst_color
	bmat.emission_enabled = true
	bmat.emission = burst_color
	bmat.emission_energy_multiplier = 3.0
	burst.material_override = bmat
	add_child(burst)
	burst.emitting = true
	# Cleanup after the particles finish
	var cleanup := get_tree().create_timer(burst.lifetime + 0.2)
	cleanup.timeout.connect(burst.queue_free)


# Brief point-light pulse — the moment of catalyst transformation
# illuminates nearby cubes for 0.4s.
func _spawn_light_pulse(light_color: Color) -> void:
	var light := OmniLight3D.new()
	light.light_color = light_color
	light.light_energy = 4.0
	light.omni_range = 2.5
	light.omni_attenuation = 2.0
	add_child(light)
	# Decay tween on the light's energy
	var t := create_tween()
	t.tween_property(light, "light_energy", 0.0, 0.4) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.tween_callback(light.queue_free)


# ── Damage ───────────────────────────────────────────────────────────
# Applies damage_percent% of max player health via GameManager. The
# autoload exposes get_health() / set_health() / max_player_health and
# already emits health_updated + player_damaged signals + damage beep.
# Cooldowns prevent spam when the foe sits on the player.
func _apply_damage_to_player() -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_damage_t < damage_cooldown_s:
		return
	_last_damage_t = now
	var gm := _resolve_game_manager()
	if gm == null:
		print("[CatalystFoe] no GameManager autoload — damage skipped")
		return
	var max_hp: float = float(gm.get("max_player_health"))
	if max_hp <= 0.0:
		max_hp = 100.0
	var dmg: float = max_hp * damage_percent * 0.01
	var current: float = float(gm.call("get_health"))
	gm.call("set_health", current - dmg)
	print("[CatalystFoe] dealt %.1f damage to player (hp %.1f -> %.1f)"
		% [dmg, current, current - dmg])


func _resolve_game_manager() -> Node:
	# GameManager is registered as an autoload — fetch via the root.
	var root := get_tree().root
	if root == null:
		return null
	return root.get_node_or_null("GameManager")


# Picks a mode_id string for dispatching converted peers. Mirrors the
# enum back to the string form CatalystProjectile uses.
func _mode_id_for_dispatch() -> String:
	match foe_mode:
		FoeMode.TRANSPORT:   return "transformation"
		FoeMode.SWARM:       return "swarm"
		FoeMode.DRAINFRIEND: return "cellular"
		_:                   return "primitives"


# Reverts one friend (or near-friend) in the world by ONE step on the
# personality arc — drainfriend entropy. Picks a random non-FOE creature
# and walks it back: FRIEND → CURIOUS, CURIOUS → NEUTRAL, etc. Mirrors
# the original behaviour but with the same one-step rhythm as forward
# transformation. The catalyst gives ground evenly in both directions.
func _drag_one_friend_back() -> void:
	var candidates: Array[CatalystFoe] = []
	for n in get_tree().get_nodes_in_group("catalyst_foe"):
		var f := n as CatalystFoe
		if f and f != self and f.state != FoeState.FOE:
			candidates.append(f)
	if candidates.is_empty():
		return
	var v := candidates[randi() % candidates.size()]
	var prev: FoeState = v.state
	v.state = (v.state - 1) as FoeState
	v._apply_state_visuals()
	v.personality_changed.emit(prev, v.state)


# ── Helpers ──────────────────────────────────────────────────────────
func _find_player() -> Node3D:
	# Try common groups other hazards use.
	for g in ["player", "vr_player", "player_body", "xr_origin"]:
		var nodes := get_tree().get_nodes_in_group(g)
		if nodes.size() > 0:
			return nodes[0] as Node3D
	# Fallback: scan the whole tree for nodes named like XR / player.
	var root := get_tree().current_scene
	if root != null:
		var found := _scan_tree_for_player(root)
		if found != null:
			return found
	return null


func _scan_tree_for_player(node: Node) -> Node3D:
	var nm: String = node.name.to_lower()
	if nm.contains("xrorigin") or nm.contains("xr_origin") \
			or nm == "player" or nm.contains("playerbody"):
		var n3 := node as Node3D
		if n3 != null:
			return n3
	for c in node.get_children():
		var found := _scan_tree_for_player(c)
		if found != null:
			return found
	return null


func _nearest_other_foe() -> CatalystFoe:
	var best: CatalystFoe = null
	var best_d: float = INF
	for n in get_tree().get_nodes_in_group("catalyst_foe"):
		var f := n as CatalystFoe
		if f == null or f == self:
			continue
		if f.state == FoeState.FRIEND:
			continue
		var d: float = f.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = f
	return best


func _apply_state_visuals() -> void:
	# Each state has a distinct palette so the personality arc is legible
	# at a glance. The hue progression is: cold-grey → alarm-red →
	# neutral-tan → warm-amber → vivid-friend-hue. Emission energy rises
	# as the creature warms.
	if _mat == null:
		return
	match state:
		FoeState.FOE:
			# Cold biome-corrupt grey — the creature before catalysis
			_mat.albedo_color = Color(0.10, 0.11, 0.14)
			_mat.emission = Color(0.82, 0.83, 0.87)
			_mat.emission_energy_multiplier = 0.7
		FoeState.WARY:
			# Alert red — alarmed, watching, defensive
			_mat.albedo_color = Color(0.55, 0.18, 0.16)
			_mat.emission = Color(0.92, 0.32, 0.20)
			_mat.emission_energy_multiplier = 1.1
		FoeState.NEUTRAL:
			# Earth-tan — disinterested, just being
			_mat.albedo_color = Color(0.52, 0.45, 0.32)
			_mat.emission = Color(0.85, 0.78, 0.60)
			_mat.emission_energy_multiplier = 0.9
		FoeState.CURIOUS:
			# Warm amber-yellow — approaching, soft glow
			_mat.albedo_color = Color(0.92, 0.72, 0.28)
			_mat.emission = Color(0.98, 0.82, 0.42)
			_mat.emission_energy_multiplier = 1.4
		FoeState.FRIEND:
			# FRIEND keeps whatever colour the catalyst gave it (set in
			# hit_by_catalyst_mode). If not set, default to friendly green.
			if _mat.emission_energy_multiplier < 1.0:
				_mat.albedo_color = Color(0.30, 0.78, 0.42)
				_mat.emission = Color(0.42, 0.94, 0.56)
				_mat.emission_energy_multiplier = 1.6


# ── Signals ──────────────────────────────────────────────────────────
signal caught_player
signal curious_contact  # CURIOUS state touched the player (no damage)
signal personality_changed(from_state: FoeState, to_state: FoeState)


# ── Grid integration ─────────────────────────────────────────────────
# Map composer entry point. Lets the foe respect any per-cell config
# from the artifact placement (rotation, scale, etc.).
func apply_grid_config(config_data: Dictionary) -> void:
	var step := float(config_data.get("step_period_s", step_period_s))
	if step > 0.0:
		step_period_s = step
	var dp := float(config_data.get("damage_percent", damage_percent))
	if dp >= 0.0:
		damage_percent = dp
	var dc := float(config_data.get("damage_cooldown_s", damage_cooldown_s))
	if dc > 0.0:
		damage_cooldown_s = dc
	# initial_state accepts: foe, wary, neutral, curious, friend
	# Each map can seed foes at a personality stage matching its sequence
	# in the curriculum (Lab=FOE, Mid-lab=WARY, Nature=NEUTRAL,
	# Nature-end=CURIOUS, Emergence=FRIEND).
	var initial_state: String = String(config_data.get("initial_state", "foe")).to_lower()
	var STATE_BY_NAME: Dictionary = {
		"foe":     FoeState.FOE,
		"wary":    FoeState.WARY,
		"neutral": FoeState.NEUTRAL,
		"curious": FoeState.CURIOUS,
		"friend":  FoeState.FRIEND,
	}
	if STATE_BY_NAME.has(initial_state):
		var target_state: FoeState = STATE_BY_NAME[initial_state]
		# Set state directly without firing personality_changed (this is
		# initial seeding, not a catalyst hit).
		state = target_state
		# If seeded as FRIEND, also pick a hue + lock a foe_mode (default GOO).
		if state == FoeState.FRIEND and _mat != null:
			var hue: Color = FRIEND_HUES[randi() % FRIEND_HUES.size()]
			_mat.albedo_color = hue
			_mat.emission = hue
			_mat.emission_energy_multiplier = 1.6
		else:
			_apply_state_visuals()
