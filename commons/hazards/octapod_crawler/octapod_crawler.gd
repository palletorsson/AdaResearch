# @identity
# essence: IK_chain(8_legs) -> surface_walk(any_geometry) -- procedural eight-legged surface crawler
# desire: eight legs finding surfaces -- walls, ceilings, floors -- body follows feet, feet follow world
# critical_parameter: IK target positions per leg -- each foot plants on nearest surface; pure procedural IK
# triggers: continuous surface sampling; foot placement via IK; body orientation follows foot normals
# emerges: the gait IS the geometry -- eight-leg redundancy dissolves the gait problem entirely
# needs: CharacterBody3D [has]; procedural IK [has]; surface detection [has]; multi-surface walk [has]; VR interaction [missing]
# relationships: parent of all leg critters (1-6 are subsets); contrasts with miura_crawler (legs vs folding)
# truth: locomotion is not a feature -- it is the first argument a body makes about its space.

# OctapodCrawler.gd
# Procedural 8-legged wall-crawling creature — headcrab meets octopus.
# The game's first enemy critter. Built entirely from code.
# Starts as an EGG-PLANT (organic pod) — is it a plant? An egg? Food? Danger?
# The categories aren't fixed until the relationship resolves.
# Hatches when disturbed or when the player gets too close.
# Q-FEP: hostile because it's surprised by you. Befriend it later in the lab.
extends CharacterBody3D
class_name OctapodCrawler

# ── States ─────────────────────────────────────────────────────────────────
enum State {
	DORMANT,    # Egg-plant pod — looks like harmless organic growth
	HATCHING,   # Shell cracks, legs unfurl, eyes light up
	IDLE,
	PATROL,
	DETECT,
	CHASE,
	LEAP,
	STUNNED,
	DEAD
}

# ── Configuration ──────────────────────────────────────────────────────────
@export_group("Combat")
@export var max_health: float = 30.0
@export var contact_damage: float = 8.0
@export var leap_damage: float = 15.0
@export var contact_cooldown: float = 0.8
@export var detection_radius: float = 8.0
@export var disengage_radius: float = 14.0
@export var leap_range: float = 3.5
@export var leap_speed: float = 8.0

@export_group("Movement")
@export var patrol_speed: float = 1.5
@export var chase_speed: float = 3.5
@export var turn_speed: float = 4.0

@export_group("Timing")
@export var detect_pause: float = 0.6
@export var patrol_direction_change: float = 3.0
@export var stun_duration: float = 1.5
@export var dead_cleanup_time: float = 3.0
@export var idle_duration: float = 2.0

@export_group("Body")
@export var body_radius: float = 0.22
@export var body_height: float = 0.12
@export var leg_count: int = 8
@export var leg_length: float = 0.35
@export var eye_count: int = 4
@export var body_hover_height: float = 0.35  ## Body center height above ground surface

## IK: All bone/spring/FABRIK config lives in octapod_ik.tscn
## (6 bones, 0.12 spacing, spring_length=1.5, dual FABRIK chains).
## FABRIK3D targets SpringArm3D foot markers directly — no step gait.

# --- DNA (promoted 2026-08-04, stage 2) ------------------------------------------------
# Everything this creature exposed was a rate, a radius or a duration — invisible to a still.
# The one decision that is entirely visible, and that the header comment states as the whole
# point ("is it a plant? An egg? Food? Danger? The categories aren't fixed until the
# relationship resolves"), was hard-coded inside _build_egg_plant(): a mossy-green pod with
# five sepals and six warts. That is a claim about what the thing wants you to think it is.
#
# guise — the category the dormant creature presents. "pod" is the shipped disguise, colour
#   for colour and count for count. "stone" reads mineral (grey, squat, no leaves, warty) —
#   scenery, not life. "fruit" reads edible (glossy red-purple, a tight three-leaf calyx, no
#   warts) — an invitation. "husk" reads already-dead (dry tan, flared spent sepals) — a thing
#   that has already hatched, so there is nothing left to fear. "bare" refuses mimicry
#   entirely: no pod at all, the eight-legged animal standing in the open from the first frame.
#   Only the last one changes the state machine, and only because there is no shell to wait in.
#
# NOT promoted: leg_count and the gait. Both are real, and both are invisible here — the legs
# are hidden for as long as the default guise is intact, so a leg axis swept against the
# default fixture returns four identical photographs of an egg, and gait is time-domain
# besides. See the registry note.
@export_enum("pod", "stone", "fruit", "husk", "bare") var guise: String = "pod"
@export var pod_seed: int = 0  ## 0 = the shipped randomized wart scatter; non-zero pins it for a still

@export_group("Dormant")
@export var start_dormant: bool = true  ## Start as egg-plant pod
@export var hatch_radius: float = 2.5  ## Player distance to trigger hatching
@export var hatch_time: float = 1.8    ## Seconds for hatching animation
@export var hatch_on_damage: bool = true  ## Hatch when damaged while dormant
@export var dormant_sway_speed: float = 0.8  ## Gentle organic sway

# ── State ──────────────────────────────────────────────────────────────────
var _health: float = 0.0
var _state: State = State.IDLE
var _state_time: float = 0.0
var _contact_timer: float = 0.0
var _patrol_timer: float = 0.0
var _patrol_direction: Vector3 = Vector3.FORWARD
var _rng := RandomNumberGenerator.new()
# (reserved for future writhing animation)

# Player tracking
var _player_node: Node3D = null

# ── Visual nodes ───────────────────────────────────────────────────────────
var _body_root: Node3D = null
var _body_mesh: MeshInstance3D = null
var _eye_meshes: Array[MeshInstance3D] = []

# ── IK leg system (octapod_ik.tscn — full .tscn like beast_demo) ──────────
# The entire IK rig (8 legs + 8 SpringArm3Ds) lives in octapod_ik.tscn.
# FABRIK3D targets SpringArm3D child Marker3Ds directly (no intermediary).
# Each Skeleton3D gets a skinned MeshInstance3D — GPU skinning deforms the mesh
# automatically as FABRIK3D solves. No manual bone-pose mesh positioning needed.
var _ik_rig: Node3D = null                         # The instanced octapod_ik.tscn root
var _ik_skeletons: Array[Skeleton3D] = []          # Skeleton3D per leg (from .tscn)
var _ik_foot_targets: Array[Marker3D] = []         # FootTarget Marker3D per leg (SpringArm3D children)
var _ik_legs: Array[Node3D] = []                   # IK_leg_N containers (for visibility toggle)
var _ik_active: bool = true                        # IK solving enabled

# Materials
var _body_material: StandardMaterial3D = null
var _eye_material: StandardMaterial3D = null
var _leg_material: StandardMaterial3D = null

# Dormant egg-plant visuals
var _egg_root: Node3D = null       # Container for egg-plant meshes
var _egg_mesh: MeshInstance3D = null  # Main bulbous pod
var _egg_material: StandardMaterial3D = null
var _leaf_meshes: Array[MeshInstance3D] = []
var _leaf_material: StandardMaterial3D = null
var _hatch_progress: float = 0.0   # 0→1 during HATCHING
var _octapod_built: bool = false   # guards the guise rebuild — _ready has run once

# ── Signals ────────────────────────────────────────────────────────────────
signal enemy_destroyed(enemy: Node3D)
signal player_detected()
signal hatched()  # Emitted when egg-plant breaks open

# ═══════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_rng.randomize()
	_health = max_health

	_create_materials()
	_build_body()
	_build_legs()
	_build_eyes()
	_build_collision()
	_build_egg_plant()

	_find_player()
	add_to_group("enemy")
	add_to_group("critter")

	_octapod_built = true

	# guise "bare" has no shell to wait inside, so it can never be dormant.
	# Every other guise takes the shipped branch untouched.
	if start_dormant and guise != "bare":
		_set_state(State.DORMANT)
		_show_egg_plant(true)
		_show_creature(false)
		_ik_active = false
		_set_fabrik_active(false)  # FABRIK3D defaults active in .tscn — disable for dormant
		print("[OctapodCrawler] Dormant egg-plant at %s" % [global_position])
	else:
		_show_egg_plant(false)
		_show_creature(true)
		_ik_active = true
		_set_fabrik_active(true)
		_set_state(State.IDLE)
		print("[OctapodCrawler] Ready at %s — HP: %.0f" % [global_position, _health])

func _physics_process(delta: float) -> void:
	_state_time += delta
	_contact_timer = max(0.0, _contact_timer - delta)

	if not is_instance_valid(_player_node):
		_find_player()

	match _state:
		State.DORMANT:
			_process_dormant(delta)
		State.HATCHING:
			_process_hatching(delta)
		State.IDLE:
			_process_idle(delta)
		State.PATROL:
			_process_patrol(delta)
		State.DETECT:
			_process_detect(delta)
		State.CHASE:
			_process_chase(delta)
		State.LEAP:
			_process_leap(delta)
		State.STUNNED:
			_process_stunned(delta)
		State.DEAD:
			_process_dead(delta)

	# ── Movement — beast_demo technique ───────────────────────────────────
	# Body sits at body_hover_height. Movement = position += direction * speed.
	# IK legs + SpringArm3Ds are children → they follow automatically.
	# No CharacterBody3D physics for normal movement.
	# LEAP is the only exception (ballistic arc via move_and_slide).
	if _state == State.LEAP:
		velocity.y -= 9.8 * delta
		move_and_slide()

	# Active states: combat
	if _state != State.DEAD and _state != State.DORMANT and _state != State.HATCHING:
		_handle_contact_damage()

# ═══════════════════════════════════════════════════════════════════════════
# STATE MACHINE
# ═══════════════════════════════════════════════════════════════════════════

func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	_state_time = 0.0

func _process_idle(delta: float) -> void:
	# Breathing animation
	if _body_mesh:
		var breath: float = 1.0 + 0.03 * sin(_state_time * 2.0)
		_body_mesh.scale = Vector3(breath, 1.0, breath)

	# Check for player
	var dist: float = _get_distance_to_player()
	if dist <= detection_radius:
		_set_state(State.DETECT)
		return

	# After idle time, start patrolling
	if _state_time >= idle_duration:
		_patrol_direction = _random_horizontal_direction()
		_set_state(State.PATROL)

func _process_patrol(delta: float) -> void:
	# Beast_demo technique: position += direction * speed * delta
	_face_direction(_patrol_direction, delta)
	position += -basis.z * patrol_speed * delta

	# Change direction periodically
	_patrol_timer += delta
	if _patrol_timer >= patrol_direction_change:
		_patrol_timer = 0.0
		_patrol_direction = _random_horizontal_direction()

	# Check for player
	var dist: float = _get_distance_to_player()
	if dist <= detection_radius:
		_set_state(State.DETECT)

func _process_detect(delta: float) -> void:
	# Face player, stand still
	if is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - global_position
		to_player.y = 0.0
		if to_player.length_squared() > 0.001:
			_face_direction(to_player.normalized(), delta)

	# Eyes glow brighter during detection
	_set_eye_glow(2.0 + sin(_state_time * 8.0) * 1.0)

	if _state_time >= detect_pause:
		player_detected.emit()
		_set_state(State.CHASE)

func _process_chase(delta: float) -> void:
	if not is_instance_valid(_player_node):
		_set_state(State.PATROL)
		return

	var to_player: Vector3 = _player_node.global_position - global_position
	var dist: float = to_player.length()

	# Disengage if too far
	if dist > disengage_radius:
		_set_eye_glow(1.0)
		_set_state(State.PATROL)
		return

	# Leap if close enough
	if dist <= leap_range:
		_set_state(State.LEAP)
		return

	# Beast_demo technique: face target, position += forward * speed
	to_player.y = 0.0
	if to_player.length_squared() > 0.001:
		_face_direction(to_player.normalized(), delta)
	position += -basis.z * chase_speed * delta

	_set_eye_glow(2.5)

func _process_leap(_delta: float) -> void:
	if _state_time < 0.05:
		# Launch — this is the ONE state that uses CharacterBody3D physics
		if is_instance_valid(_player_node):
			var to_player: Vector3 = _player_node.global_position - global_position
			to_player.y = max(to_player.y, 0.5)
			velocity = to_player.normalized() * leap_speed
		return

	# Gravity handled in _physics_process via move_and_slide

	# If landed or timed out, snap back to hover height and resume chase
	if _state_time > 1.5 or (_state_time > 0.2 and is_on_floor()):
		velocity = Vector3.ZERO
		# Snap back to hover height (beast_demo technique: fixed Y)
		position.y = body_hover_height
		_set_state(State.CHASE)

func _process_stunned(_delta: float) -> void:
	# Stand still during stun (no position changes)

	# Disable FABRIK3D — legs freeze in last pose during stun
	if _ik_active:
		_ik_active = false
		_set_fabrik_active(false)

	# Visual feedback — flash and twitch
	if _body_mesh:
		var flash: float = abs(sin(_state_time * 15.0))
		_body_material.emission_energy_multiplier = 0.5 + flash * 2.0

	if _state_time >= stun_duration:
		_body_material.emission_energy_multiplier = 0.4
		_ik_active = true
		_set_fabrik_active(true)
		_set_state(State.CHASE)

func _process_dead(_delta: float) -> void:
	# Curl legs inward via foot targets (FABRIK3D auto-solves, skinned mesh deforms)
	_curl_legs(_state_time / dead_cleanup_time)

	# Fade out body
	var fade: float = max(0.0, 1.0 - _state_time / dead_cleanup_time)
	if _body_material:
		_body_material.albedo_color.a = fade
		_body_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if _leg_material:
		_leg_material.albedo_color.a = fade
		_leg_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	if _state_time >= dead_cleanup_time:
		queue_free()

# ═══════════════════════════════════════════════════════════════════════════
# DORMANT / HATCHING
# ═══════════════════════════════════════════════════════════════════════════

func _process_dormant(delta: float) -> void:
	velocity = Vector3.ZERO

	# Gentle organic sway — looks alive but plant-like
	if _egg_root:
		var sway_x: float = sin(_state_time * dormant_sway_speed) * 0.02
		var sway_z: float = cos(_state_time * dormant_sway_speed * 0.7) * 0.015
		_egg_root.rotation.x = sway_x
		_egg_root.rotation.z = sway_z

	# Subtle pulse on the egg material (bioluminescent throb)
	if _egg_material:
		var pulse: float = 0.15 + 0.1 * sin(_state_time * 1.5)
		_egg_material.emission_energy_multiplier = pulse

	# Check if player is close enough to trigger hatching
	var dist: float = _get_distance_to_player()
	if dist <= hatch_radius:
		_begin_hatching()

func _process_hatching(delta: float) -> void:
	velocity = Vector3.ZERO
	_hatch_progress = clamp(_state_time / hatch_time, 0.0, 1.0)

	# Phase 1 (0.0–0.3): Pod trembles, cracks appear (emission flares)
	if _hatch_progress < 0.3:
		var tremor: float = _hatch_progress / 0.3
		if _egg_root:
			_egg_root.rotation.x = sin(_state_time * 25.0) * 0.04 * tremor
			_egg_root.rotation.z = cos(_state_time * 30.0) * 0.03 * tremor
		if _egg_material:
			_egg_material.emission_energy_multiplier = 0.3 + tremor * 1.5

	# Phase 2 (0.3–0.7): Shell splits open, legs start to emerge
	elif _hatch_progress < 0.7:
		var emerge: float = (_hatch_progress - 0.3) / 0.4  # 0→1
		# Fade out egg shell
		if _egg_material:
			_egg_material.albedo_color.a = 1.0 - emerge * 0.8
			_egg_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_egg_material.emission_energy_multiplier = 2.0 - emerge
		# Scale down egg
		if _egg_mesh:
			var egg_scale: float = 1.0 - emerge * 0.6
			_egg_mesh.scale = Vector3(egg_scale, egg_scale, egg_scale)
		# Fade in leaves peeling away
		for leaf in _leaf_meshes:
			leaf.rotation.x = -emerge * PI * 0.4
			leaf.scale.y = 1.0 - emerge * 0.5
		# Start showing creature body
		if emerge > 0.3:
			_show_creature(true)
			var creature_alpha: float = (emerge - 0.3) / 0.7
			if _body_material:
				_body_material.albedo_color.a = creature_alpha
				_body_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Phase 3 (0.7–1.0): Legs unfurl, eyes light up, shell gone
	else:
		var unfurl: float = (_hatch_progress - 0.7) / 0.3  # 0→1
		# Eyes light up
		_set_eye_glow(unfurl * 1.5)
		# Body fully opaque
		if _body_material:
			_body_material.albedo_color.a = 1.0
			_body_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		# Legs extend outward (FABRIK3D auto-solves, skinned mesh deforms)
		_unfurl_legs(unfurl)

	# Hatching complete
	if _hatch_progress >= 1.0:
		_finish_hatching()

func _begin_hatching() -> void:
	_set_state(State.HATCHING)
	_hatch_progress = 0.0
	print("[OctapodCrawler] Hatching! Player detected nearby")

func _finish_hatching() -> void:
	# Remove egg-plant visuals
	_show_egg_plant(false)

	# Ensure creature is fully visible and opaque
	_show_creature(true)
	if _body_material:
		_body_material.albedo_color.a = 1.0
		_body_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	_set_eye_glow(1.5)

	# IK is already enabled from unfurl — normal leg control takes over
	_ik_active = true

	hatched.emit()
	_set_state(State.DETECT)
	print("[OctapodCrawler] Hatched! Transitioning to active")

func _unfurl_legs(progress: float) -> void:
	## During hatching phase 3: lerp foot targets outward from body center.
	## FABRIK3D auto-solves as each foot_target Marker3D moves.
	if progress < 0.1:
		return
	_ik_active = true
	_set_fabrik_active(true)
	var body_pos: Vector3 = global_position
	var curl_center: Vector3 = body_pos + Vector3.UP * body_radius * 0.3
	for i in range(leg_count):
		if i >= _ik_foot_targets.size():
			continue
		var angle: float = TAU * float(i) / float(leg_count)
		var rest_foot: Vector3 = body_pos + Vector3(
			cos(angle) * (body_radius + leg_length * 0.6),
			-leg_length * 0.8,
			sin(angle) * (body_radius + leg_length * 0.6)
		)
		var target_pos: Vector3 = curl_center.lerp(rest_foot, progress)
		_ik_foot_targets[i].global_position = target_pos

func _show_egg_plant(visible_state: bool) -> void:
	if _egg_root:
		_egg_root.visible = visible_state

func _show_creature(visible_state: bool) -> void:
	if _body_root:
		_body_root.visible = visible_state
	# Show/hide entire IK rig (legs, SpringArm3Ds, magnets — everything)
	if is_instance_valid(_ik_rig):
		_ik_rig.visible = visible_state
	# Toggle IK solving
	_ik_active = visible_state
	_set_fabrik_active(visible_state)

# ═══════════════════════════════════════════════════════════════════════════
# EGG-PLANT CONSTRUCTION
# ═══════════════════════════════════════════════════════════════════════════

## GUISE_POD is the shipped disguise, value for value — the literals that used to sit
## inline in _build_egg_plant(). The other three are the alternative claims.
const GUISE_POD: Dictionary = {
	"albedo": Color(0.28, 0.35, 0.22),   # dark mossy green
	"roughness": 0.8,
	"glow": true,
	"pod_scale": Vector3(1.0, 1.3, 1.0), # taller than wide, like an egg
	"leaf_count": 5,
	"leaf_tilt": -0.3,
	"leaf_size": 1.0,
	"bump_count": 6,
	"bump_scale": 1.0,
}

const GUISE_STONE: Dictionary = {
	"albedo": Color(0.44, 0.43, 0.40),   # dry grey mineral
	"roughness": 0.95,
	"glow": false,
	"pod_scale": Vector3(1.18, 0.82, 1.08),  # squat, boulder-like
	"leaf_count": 0,                     # nothing living about it
	"leaf_tilt": -0.3,
	"leaf_size": 1.0,
	"bump_count": 11,
	"bump_scale": 1.7,
}

const GUISE_FRUIT: Dictionary = {
	"albedo": Color(0.46, 0.08, 0.24),   # ripe red-purple
	"roughness": 0.22,                   # waxy, glossy
	"glow": true,
	"pod_scale": Vector3(1.02, 1.34, 1.02),
	"leaf_count": 3,
	"leaf_tilt": -0.95,                  # a tight calyx hugging the top
	"leaf_size": 0.6,
	"bump_count": 0,                     # smooth skin — edible
	"bump_scale": 1.0,
}

const GUISE_HUSK: Dictionary = {
	"albedo": Color(0.58, 0.50, 0.34),   # dried tan
	"roughness": 0.97,
	"glow": false,
	"pod_scale": Vector3(0.9, 1.22, 0.9),  # shrunken
	"leaf_count": 7,
	"leaf_tilt": 0.62,                   # spent sepals flared open
	"leaf_size": 1.45,
	"bump_count": 3,
	"bump_scale": 0.8,
}


## What the dormant creature presents itself AS. guise == "pod" returns the shipped
## literal for every key, so the default build is the pre-promotion build.
func _guise_trait(key: String) -> Variant:
	var traits: Dictionary = GUISE_POD
	match guise:
		"stone":
			traits = GUISE_STONE
		"fruit":
			traits = GUISE_FRUIT
		"husk":
			traits = GUISE_HUSK
	if traits.has(key):
		return traits[key]
	return GUISE_POD.get(key, null)


func _build_egg_plant() -> void:
	# "bare" builds no disguise at all — the animal stands in the open.
	if guise == "bare":
		return

	_egg_root = Node3D.new()
	_egg_root.name = "EggPlantRoot"
	add_child(_egg_root)

	# Egg-plant material: muted green-purple organic, like a real eggplant/seed pod
	_egg_material = StandardMaterial3D.new()
	var pod_albedo: Color = _guise_trait("albedo")
	_egg_material.albedo_color = pod_albedo
	_egg_material.roughness = float(_guise_trait("roughness"))
	_egg_material.metallic = 0.0
	_egg_material.emission_enabled = bool(_guise_trait("glow"))
	_egg_material.emission = Color(0.15, 0.25, 0.1)  # Subtle inner glow
	_egg_material.emission_energy_multiplier = 0.15

	# Leaf material: slightly brighter green, veiny
	_leaf_material = StandardMaterial3D.new()
	_leaf_material.albedo_color = Color(0.22, 0.38, 0.15)  # Leaf green
	if guise == "husk":
		_leaf_material.albedo_color = Color(0.52, 0.44, 0.28)  # dry, spent
	elif guise == "fruit":
		_leaf_material.albedo_color = Color(0.17, 0.30, 0.12)  # darker calyx
	_leaf_material.roughness = 0.7
	_leaf_material.metallic = 0.0
	_leaf_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Visible from both sides

	# Main pod — bulbous egg shape (sphere squished vertically, fat)
	_egg_mesh = MeshInstance3D.new()
	_egg_mesh.name = "EggPod"
	var egg_sphere := SphereMesh.new()
	egg_sphere.radius = body_radius * 1.6  # Larger than the creature inside
	egg_sphere.height = body_radius * 3.0
	egg_sphere.radial_segments = 16
	egg_sphere.rings = 12
	_egg_mesh.mesh = egg_sphere
	_egg_mesh.material_override = _egg_material
	var pod_scale: Vector3 = _guise_trait("pod_scale")
	_egg_mesh.scale = pod_scale  # Taller than wide, like an egg
	_egg_mesh.position.y = body_radius * 0.8  # Sit slightly above ground
	_egg_root.add_child(_egg_mesh)

	# Leaf-like sepals around the top — 5 petal structures wrapping the pod
	var leaf_count: int = int(_guise_trait("leaf_count"))
	var leaf_scale: float = float(_guise_trait("leaf_size"))
	var leaf_tilt: float = float(_guise_trait("leaf_tilt"))
	for i in range(leaf_count):
		var angle: float = TAU * float(i) / float(leaf_count)
		var leaf := MeshInstance3D.new()
		leaf.name = "Leaf_%d" % i

		# Each leaf is a flattened box (like a thick petal/sepal)
		var box := BoxMesh.new()
		box.size = Vector3(body_radius * 0.9 * leaf_scale, body_radius * 1.4 * leaf_scale, 0.015)
		leaf.mesh = box
		leaf.material_override = _leaf_material

		# Position: around the top half of the egg, angled outward
		var leaf_radius: float = body_radius * 1.2
		leaf.position = Vector3(
			cos(angle) * leaf_radius,
			body_radius * 1.8,  # Near top of pod
			sin(angle) * leaf_radius
		)
		# Rotate to face outward and tilt up (cupping the egg)
		leaf.rotation.y = -angle
		leaf.rotation.x = leaf_tilt  # Slight inward tilt

		_egg_root.add_child(leaf)
		_leaf_meshes.append(leaf)

	# Small bumps/warts on the pod surface (organic texture)
	# pod_seed = 0 hands back the shipped _rng, randomize()d in _ready — a different
	# scatter every launch. A non-zero seed pins it so the gallery measures the guise
	# and not the wart lottery.
	var pod_rng: RandomNumberGenerator = _rng
	if pod_seed != 0:
		pod_rng = RandomNumberGenerator.new()
		pod_rng.seed = pod_seed
	var bump_count: int = int(_guise_trait("bump_count"))
	var bump_scale: float = float(_guise_trait("bump_scale"))
	for i in range(bump_count):
		var bump_angle: float = pod_rng.randf_range(0, TAU)
		var bump_height: float = pod_rng.randf_range(0.3, 0.8)
		var bump := MeshInstance3D.new()
		bump.name = "Bump_%d" % i
		var bump_sphere := SphereMesh.new()
		bump_sphere.radius = body_radius * pod_rng.randf_range(0.12, 0.2) * bump_scale
		bump_sphere.height = bump_sphere.radius * 2.0
		bump.mesh = bump_sphere
		bump.material_override = _egg_material
		bump.position = Vector3(
			cos(bump_angle) * body_radius * 1.3,
			body_radius * bump_height * 2.5,
			sin(bump_angle) * body_radius * 1.3
		)
		_egg_root.add_child(bump)

# ═══════════════════════════════════════════════════════════════════════════
# SURFACE ALIGNMENT
# ═══════════════════════════════════════════════════════════════════════════

## Beast_demo technique: body stays at fixed Y = body_hover_height.
## No hover raycasting, no _align_to_surface. Just position += to move.
## SpringArm3Ds (children) auto-find ground. FABRIK3D auto-solves to foot targets.

# ═══════════════════════════════════════════════════════════════════════════
# IK LEGS (octapod_ik.tscn — full scene, beast_demo pattern)
# ═══════════════════════════════════════════════════════════════════════════

func _build_legs() -> void:
	## Instance the complete IK rig from octapod_ik.tscn.
	## Everything (8 IK legs, 8 SpringArm3Ds, FABRIK3D, magnets) is pre-configured.
	## FABRIK3D targets SpringArm3D child Marker3Ds directly — like beast_demo.
	var ik_scene: PackedScene = load("res://commons/hazards/octapod_crawler/octapod_ik.tscn")
	_ik_rig = ik_scene.instantiate()
	_ik_rig.name = "IKRig"
	add_child(_ik_rig)

	# Build a shared Skin + ArrayMesh resource (same bone layout for all 8 legs)
	var shared_skin: Skin = _create_leg_skin()
	var shared_mesh: ArrayMesh = _create_leg_arraymesh()

	# Grab references to each leg's skeleton, foot target marker, and container
	for i in range(leg_count):
		var leg_node: Node3D = _ik_rig.get_node("IK_leg_%d" % i)
		var skeleton: Skeleton3D = leg_node.get_node("Armature/Skeleton3D")
		var foot_target: Marker3D = _ik_rig.get_node("SpringArm3D_%d/FootTarget_%d" % [i, i])

		_ik_legs.append(leg_node)
		_ik_skeletons.append(skeleton)
		_ik_foot_targets.append(foot_target)

		# Add a skinned MeshInstance3D to the Skeleton3D — GPU skinning deforms it
		# as FABRIK3D solves. This is the same pattern beast_demo uses.
		var skin_mesh := MeshInstance3D.new()
		skin_mesh.name = "LegSkinMesh_%d" % i
		skin_mesh.mesh = shared_mesh
		skin_mesh.skin = shared_skin
		# skeleton NodePath defaults to ".." which resolves to our parent Skeleton3D
		skin_mesh.material_override = _leg_material
		skeleton.add_child(skin_mesh)

	# Debug: verify FABRIK3D is found and active
	if _ik_skeletons.size() > 0:
		var skel: Skeleton3D = _ik_skeletons[0]
		var fabrik_found: bool = false
		for ci in range(skel.get_child_count()):
			var c: Node = skel.get_child(ci)
			if c is SkeletonModifier3D:
				fabrik_found = true
				print("[OctapodCrawler] FABRIK3D found: %s, active=%s" % [c.name, c.active])
		if not fabrik_found:
			print("[OctapodCrawler] WARNING: No FABRIK3D/SkeletonModifier3D found in skeleton!")
		print("[OctapodCrawler] IK rig loaded: %d legs, %d skeletons, %d foot targets" % [
			_ik_legs.size(), _ik_skeletons.size(), _ik_foot_targets.size()
		])

func _set_fabrik_active(active: bool) -> void:
	## Toggle FABRIK3D solver active state inside each leg's Skeleton3D.
	## FABRIK3D is a SkeletonModifier3D — setting active=false freezes the pose.
	for skeleton in _ik_skeletons:
		if not is_instance_valid(skeleton):
			continue
		for child_idx in range(skeleton.get_child_count()):
			var child: Node = skeleton.get_child(child_idx)
			if child is SkeletonModifier3D:
				child.active = active

func _create_leg_skin() -> Skin:
	## Create a Skin resource matching the octapod_ik.tscn bone chain (6 bones, 0.12 spacing).
	## Each bind pose is the inverse of the bone's rest position — same pattern as beast_demo.
	var skin := Skin.new()
	var bone_count: int = 6
	var spacing: float = 0.12
	skin.set_bind_count(bone_count)
	for i in range(bone_count):
		skin.set_bind_name(i, "Bone" if i == 0 else "Bone.%03d" % i)
		skin.set_bind_bone(i, -1)  # -1 = resolve by name (like beast_demo)
		# Bind pose = inverse of rest position (bone grows in +Y, bind offsets in -Y)
		var y_offset: float = -spacing * float(i)
		skin.set_bind_pose(i, Transform3D(Basis.IDENTITY, Vector3(0, y_offset, 0)))
	return skin

func _create_leg_arraymesh() -> ArrayMesh:
	## Create a tapered tube ArrayMesh with bone weights for GPU skinning.
	## 6 rings of vertices (one per bone), each ring assigned 100% to its bone.
	## This lets FABRIK3D deform the mesh automatically — no manual positioning.
	var bone_count: int = 6
	var spacing: float = 0.12
	var radial_segs: int = 6
	var base_radius: float = 0.025  # Thicker at root
	var tip_radius: float = 0.006   # Thin at tip

	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var bones_arr := PackedInt32Array()  # 4 bone indices per vertex
	var weights_arr := PackedFloat32Array()  # 4 weights per vertex

	# Generate ring vertices — one ring per bone position
	for ring in range(bone_count):
		var y: float = spacing * float(ring)
		var t: float = float(ring) / float(bone_count - 1)
		var radius: float = lerp(base_radius, tip_radius, t)
		for seg in range(radial_segs):
			var angle: float = TAU * float(seg) / float(radial_segs)
			var x: float = cos(angle) * radius
			var z: float = sin(angle) * radius
			verts.append(Vector3(x, y, z))
			normals.append(Vector3(cos(angle), 0, sin(angle)).normalized())
			# Each vertex is 100% weighted to its ring's bone
			bones_arr.append(ring)  # bone index
			bones_arr.append(0)
			bones_arr.append(0)
			bones_arr.append(0)
			weights_arr.append(1.0)
			weights_arr.append(0.0)
			weights_arr.append(0.0)
			weights_arr.append(0.0)

	# Generate triangle indices connecting adjacent rings
	var indices := PackedInt32Array()
	for ring in range(bone_count - 1):
		for seg in range(radial_segs):
			var curr: int = ring * radial_segs + seg
			var next_seg: int = ring * radial_segs + (seg + 1) % radial_segs
			var above: int = (ring + 1) * radial_segs + seg
			var above_next: int = (ring + 1) * radial_segs + (seg + 1) % radial_segs
			# Two triangles per quad
			indices.append(curr)
			indices.append(above)
			indices.append(next_seg)
			indices.append(next_seg)
			indices.append(above)
			indices.append(above_next)

	# Build the ArrayMesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_BONES] = bones_arr
	arrays[Mesh.ARRAY_WEIGHTS] = weights_arr
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _update_legs(_delta: float) -> void:
	## FABRIK3D + GPU skinning handles everything automatically.
	## SpringArm3D auto-targets ground, FABRIK3D solves bone chain,
	## skinned MeshInstance3D deforms via GPU. Nothing to do here.
	pass

func _freeze_legs(frozen: bool) -> void:
	## Toggle IK solving and visibility for dormant/active states.
	_ik_active = not frozen
	_set_fabrik_active(not frozen)
	# Skinned meshes live inside the IK rig — toggling rig visibility covers them
	if is_instance_valid(_ik_rig):
		_ik_rig.visible = not frozen

func _curl_legs(progress: float) -> void:
	## During death: move foot targets toward body center (curling inward).
	## FABRIK3D auto-solves as the foot_target Marker3D moves inward.
	var curl: float = clamp(progress, 0.0, 1.0)
	var body_pos: Vector3 = global_position
	var curl_target: Vector3 = body_pos + Vector3.UP * body_radius * 0.5
	for i in range(_ik_foot_targets.size()):
		var target: Marker3D = _ik_foot_targets[i]
		if is_instance_valid(target):
			target.global_position = target.global_position.lerp(curl_target, curl)

# ═══════════════════════════════════════════════════════════════════════════
# BODY CONSTRUCTION
# ═══════════════════════════════════════════════════════════════════════════

func _build_body() -> void:
	_body_root = Node3D.new()
	_body_root.name = "BodyRoot"
	add_child(_body_root)

	# Central body — flattened ellipsoid
	_body_mesh = MeshInstance3D.new()
	_body_mesh.name = "BodyMesh"
	var sphere := SphereMesh.new()
	sphere.radius = body_radius
	sphere.height = body_height * 2.0
	sphere.radial_segments = 20
	sphere.rings = 10
	_body_mesh.mesh = sphere
	_body_mesh.material_override = _body_material
	# Flatten vertically, slightly elongate forward
	_body_mesh.scale = Vector3(1.0, 0.5, 1.15)
	_body_root.add_child(_body_mesh)

func _build_eyes() -> void:
	var eye_radius: float = 0.022
	var eye_ring_radius: float = body_radius * 0.5
	var eye_height: float = body_height * 0.6

	for i in range(eye_count):
		var angle: float = (-0.3 + 0.6 * float(i) / float(max(eye_count - 1, 1)))
		var x: float = sin(angle) * eye_ring_radius
		var z: float = -cos(angle) * eye_ring_radius  # Front-facing
		var y: float = eye_height

		var eye := MeshInstance3D.new()
		eye.name = "Eye_%d" % i
		var eye_sphere := SphereMesh.new()
		eye_sphere.radius = eye_radius
		eye_sphere.height = eye_radius * 2.0
		eye.mesh = eye_sphere
		eye.material_override = _eye_material
		eye.position = Vector3(x, y, z)
		_body_root.add_child(eye)
		_eye_meshes.append(eye)

func _build_collision() -> void:
	# Small sphere around the body — used for LEAP landing (is_on_floor).
	# Normal movement uses position += (beast_demo technique), not CharacterBody3D floor physics.
	var collision := CollisionShape3D.new()
	collision.name = "BodyCollision"
	var sphere := SphereShape3D.new()
	sphere.radius = body_radius * 0.7
	collision.shape = sphere
	add_child(collision)

func _create_materials() -> void:
	# Body: dark purple-red, fleshy
	_body_material = StandardMaterial3D.new()
	_body_material.albedo_color = Color(0.35, 0.12, 0.18)
	_body_material.roughness = 0.65
	_body_material.metallic = 0.1
	_body_material.emission_enabled = true
	_body_material.emission = Color(0.3, 0.05, 0.1)
	_body_material.emission_energy_multiplier = 0.4

	# Eyes: bioluminescent red
	_eye_material = StandardMaterial3D.new()
	_eye_material.albedo_color = Color(1.0, 0.2, 0.15)
	_eye_material.emission_enabled = true
	_eye_material.emission = Color(1.0, 0.15, 0.1)
	_eye_material.emission_energy_multiplier = 1.5

	# Legs: darker, slightly glossy
	_leg_material = StandardMaterial3D.new()
	_leg_material.albedo_color = Color(0.25, 0.1, 0.14)
	_leg_material.roughness = 0.5
	_leg_material.metallic = 0.15

# ═══════════════════════════════════════════════════════════════════════════
# COMBAT
# ═══════════════════════════════════════════════════════════════════════════

func _handle_contact_damage() -> void:
	if _contact_timer > 0.0:
		return
	if _state == State.DEAD or _state == State.STUNNED:
		return

	# Proximity-based damage — check distance to player (beast_demo technique: position +=, no move_and_slide)
	if not is_instance_valid(_player_node):
		return
	var dist: float = global_position.distance_to(_player_node.global_position)
	var contact_range: float = body_radius + 0.3  # Body radius + player body margin
	if dist > contact_range:
		return

	var damage: float = contact_damage
	if _state == State.LEAP:
		damage = leap_damage

	if _try_damage_target(_player_node, damage):
		_contact_timer = contact_cooldown

func _try_damage_target(target: Object, damage: float) -> bool:
	if target == null:
		return false

	# Check if it's a player
	if target is Node3D:
		var node: Node3D = target as Node3D
		if not _is_player_node(node):
			return false

	# Try damage methods
	if target.has_method("take_damage"):
		target.take_damage(damage)
		return true
	if target.has_method("apply_damage"):
		target.apply_damage(damage)
		return true
	if target.has_method("apply_health_damage"):
		target.apply_health_damage(damage)
		return true

	# Try GameManager
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("apply_health_damage"):
		if target is Node:
			var target_node: Node = target as Node
			if _is_player_node(target_node):
				gm.apply_health_damage(damage)
				return true

	return false

func take_damage(amount: float) -> void:
	_apply_damage(amount)

func apply_damage(amount: float) -> void:
	_apply_damage(amount)

func damage(amount: float) -> void:
	_apply_damage(amount)

func _apply_damage(amount: float) -> void:
	if _state == State.DEAD:
		return

	# Damage while dormant = forced hatch
	if _state == State.DORMANT and hatch_on_damage:
		_begin_hatching()
		# Still take the damage
	if _state == State.HATCHING:
		# Can't be killed mid-hatch, but take some damage
		_health -= max(0.0, amount * 0.5)
		return

	_health -= max(0.0, amount)
	print("[OctapodCrawler] Took %.1f damage — HP: %.1f/%.1f" % [amount, _health, max_health])

	if _health <= 0.0:
		_die()
	else:
		# Stun on significant damage
		if amount >= max_health * 0.3 or _state != State.STUNNED:
			_play_hit_feedback()
		if amount >= max_health * 0.25:
			_set_state(State.STUNNED)

func _die() -> void:
	if _state == State.DEAD:
		return
	_set_state(State.DEAD)
	velocity = Vector3.ZERO
	_set_eye_glow(0.2)
	enemy_destroyed.emit(self)
	print("[OctapodCrawler] Destroyed")

func _play_hit_feedback() -> void:
	if _body_mesh:
		var tween: Tween = create_tween()
		tween.tween_property(_body_mesh, "scale", Vector3(1.15, 0.6, 1.3), 0.06)
		tween.tween_property(_body_mesh, "scale", Vector3(1.0, 0.5, 1.15), 0.1)

# ═══════════════════════════════════════════════════════════════════════════
# EYE GLOW
# ═══════════════════════════════════════════════════════════════════════════

func _set_eye_glow(energy: float) -> void:
	if _eye_material:
		_eye_material.emission_energy_multiplier = energy

# ═══════════════════════════════════════════════════════════════════════════
# UTILITY / DETECTION
# ═══════════════════════════════════════════════════════════════════════════

func _find_player() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		_player_node = null
		return

	var scene_root: Node = tree.current_scene
	if scene_root == null:
		_player_node = null
		return

	# Same detection pattern as ArmadilloDroideka
	var candidates: Array = [
		tree.get_first_node_in_group("player"),
		scene_root.find_child("XROrigin3D", true, false),
		scene_root.find_child("Player", true, false),
		scene_root.find_child("PlayerBody", true, false),
	]

	_player_node = null
	for candidate in candidates:
		if candidate is Node3D:
			_player_node = candidate as Node3D
			break

func _get_distance_to_player() -> float:
	if not is_instance_valid(_player_node):
		return INF
	return global_position.distance_to(_player_node.global_position)

func _is_player_node(node: Node) -> bool:
	if node is Node3D:
		var n3d: Node3D = node as Node3D
		if n3d.is_in_group("player") or n3d.is_in_group("player_body"):
			return true
		var lower: String = n3d.name.to_lower()
		return lower.contains("player") or lower.contains("xrorigin")
	return false

func _face_direction(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	var target_yaw: float = atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)

func _random_horizontal_direction() -> Vector3:
	var angle: float = _rng.randf_range(0, TAU)
	return Vector3(cos(angle), 0, sin(angle))

# ═══════════════════════════════════════════════════════════════════════════
# GRID INTEGRATION
# ═══════════════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	configure(config_data)

func configure(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return

	if config_data.has("health"):
		max_health = _cfg_float(config_data["health"], max_health)
		_health = max_health
	if config_data.has("speed"):
		patrol_speed = _cfg_float(config_data["speed"], patrol_speed)
		chase_speed = patrol_speed * 2.3
	if config_data.has("damage"):
		contact_damage = _cfg_float(config_data["damage"], contact_damage)
	if config_data.has("detection"):
		detection_radius = _cfg_float(config_data["detection"], detection_radius)
	if config_data.has("size"):
		var s: float = _cfg_float(config_data["size"], 1.0)
		body_radius *= s
		body_height *= s
		leg_length *= s
	if config_data.has("aggression"):
		var aggro: float = _cfg_float(config_data["aggression"], 1.0)
		chase_speed *= aggro
		leap_damage *= aggro
		detection_radius *= aggro
	if config_data.has("dormant"):
		start_dormant = str(config_data["dormant"]).to_lower() in ["true", "1", "yes"]
	if config_data.has("hatch_radius"):
		hatch_radius = _cfg_float(config_data["hatch_radius"], hatch_radius)
	if config_data.has("hatch_time"):
		hatch_time = _cfg_float(config_data["hatch_time"], hatch_time)
	if config_data.has("pod_seed"):
		var seed_text: String = str(config_data["pod_seed"]).strip_edges()
		if seed_text.is_valid_int():
			pod_seed = int(seed_text)
	if config_data.has("guise"):
		var want_guise: String = str(config_data["guise"]).strip_edges().to_lower()
		if want_guise in ["pod", "stone", "fruit", "husk", "bare"] and want_guise != guise:
			guise = want_guise
			# Guarded: only after _ready has built once, and only because the value
			# changed. A map that passes no guise key never reaches this line, so the
			# existing placement keeps its shipped pod.
			if _octapod_built:
				_rebuild_guise()

## Swap the disguise on an already-built creature. Only reachable from
## apply_grid_config when the declared value actually changed.
func _rebuild_guise() -> void:
	if is_instance_valid(_egg_root):
		remove_child(_egg_root)
		_egg_root.queue_free()
	_egg_root = null
	_egg_mesh = null
	_egg_material = null
	_leaf_material = null
	_leaf_meshes.clear()

	_build_egg_plant()

	if guise == "bare":
		_show_creature(true)
		if _state == State.DORMANT or _state == State.HATCHING:
			_set_state(State.IDLE)
		return

	if _state == State.DORMANT:
		_show_egg_plant(true)
		_show_creature(false)
	else:
		_show_egg_plant(false)

func _cfg_float(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		return float(value)
	var text: String = str(value).strip_edges()
	if text.is_valid_float():
		return float(text)
	return fallback
