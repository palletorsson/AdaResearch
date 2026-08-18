# @identity
# essence: place in any map -> orb gesture system becomes active for that map
# desire: a single artifact that bootstraps the orb test slice — no autoload changes, no scene edits required
# critical_parameter: spawn_creatures (Array of HazardCreatureBase subclass paths to spawn around the rig)
# triggers: _ready instantiates detector under XROrigin, orb at scene root, optionally spawns creatures
# emerges: a self-contained capsule for the slice — drop into a map and the new verb works
# needs: OrbGestureDetector + CatalystOrb [has]; XR rig present in scene [runtime assumption]
# relationships: glue between OrbGestureDetector and CatalystOrb; spawner for test creatures
# truth: a test fixture, not production wiring — promote to staging-level autoload once the verb is felt-right.

# OrbTestRig.gd
# A single artifact that bootstraps the orb gesture slice when placed in
# a map. Instantiates OrbGestureDetector under the XR rig, instantiates
# CatalystOrb at the scene root, wires the signals, optionally spawns a
# small set of test creatures around itself.
#
# This is test-scaffolding. For production, the detector + orb get
# wired in at the staging scene level. Until the verb is felt-right,
# the rig keeps the slice self-contained.

extends Node3D
class_name OrbTestRig

# ── Configurable ────────────────────────────────────────────────────────
@export var auto_spawn_creatures: bool = true
@export var creature_scenes: Array[String] = [
	"res://commons/hazards/catalyst_foe/catalyst_foe.tscn",
	"res://commons/hazards/fractal_hydra/fractal_hydra.tscn",
	"res://commons/hazards/gradient_hunter/gradient_hunter.tscn",
]
@export var creature_radius: float = 3.0
@export var verbose: bool = true

# ── Internal ────────────────────────────────────────────────────────────
# Loose-typed to avoid class_name resolution races at script-load time
# (smoke tests can load this file before the global type table is built).
var _detector: Node3D = null
var _orb: Node3D = null
var _xr_origin: Node3D = null


func _ready() -> void:
	add_to_group("orb_test_rig")
	call_deferred("_bootstrap")


func _bootstrap() -> void:
	_xr_origin = _find_xr_origin()
	if _xr_origin == null:
		if verbose:
			print("[OrbTestRig] no XROrigin3D found yet — retrying in 0.5 s")
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().create_timer(0.5).timeout
		_xr_origin = _find_xr_origin()
		if _xr_origin == null:
			push_warning("[OrbTestRig] no XROrigin3D; orb gesture system not active")
			return

	# 1. Detector — attached to XROrigin so controllers are siblings
	var detector_scene: PackedScene = load("res://commons/hazards/becoming_catalyst/orb_gesture_detector.tscn")
	if detector_scene == null:
		push_error("[OrbTestRig] could not load orb_gesture_detector.tscn")
		return
	_detector = detector_scene.instantiate()
	_xr_origin.add_child(_detector)

	# 2. Orb — child of self so it lives with the map, not the rig
	var orb_scene: PackedScene = load("res://commons/hazards/becoming_catalyst/catalyst_orb.tscn")
	if orb_scene == null:
		push_error("[OrbTestRig] could not load catalyst_orb.tscn")
		return
	_orb = orb_scene.instantiate()
	add_child(_orb)

	# 3. Wire signals
	_detector.orb_formed.connect(_on_orb_formed)
	_detector.orb_state_tick.connect(_on_orb_state_tick)
	_detector.orb_dissolved.connect(_on_orb_dissolved)
	_detector.hand_cooldown_started.connect(_on_hand_cooldown_started)
	_detector.hand_cooldown_finished.connect(_on_hand_cooldown_finished)

	# 4. Optionally spawn creatures
	if auto_spawn_creatures:
		_spawn_test_creatures()

	if verbose:
		print("[OrbTestRig] active — detector under %s, orb under %s" % [_xr_origin.name, name])


func _on_orb_formed(mode: String, origin: Vector3, direction: Vector3, two_handed: bool) -> void:
	if _orb:
		_orb.form(mode, origin, direction, two_handed)
	if verbose:
		print("[OrbTestRig] orb formed: mode=%s, two_handed=%s" % [mode, two_handed])


func _on_orb_state_tick(mode: String, origin: Vector3, direction: Vector3, cone_length: float, two_handed: bool) -> void:
	if _orb:
		_orb.update_state(mode, origin, direction, cone_length, two_handed)


func _on_orb_dissolved() -> void:
	if _orb:
		_orb.dissolve()


func _on_hand_cooldown_started(hand: String) -> void:
	if verbose:
		print("[OrbTestRig] %s hand cooldown" % hand)
	# Bracelet stone dim wiring goes here once the bracelet exposes a
	# luminance API. For the slice, the cooldown is felt via gesture
	# failure (the orb simply does not form on that hand).


func _on_hand_cooldown_finished(hand: String) -> void:
	if verbose:
		print("[OrbTestRig] %s hand recovered" % hand)


# ── Creature spawning ───────────────────────────────────────────────────

func _spawn_test_creatures() -> void:
	var n: int = creature_scenes.size()
	if n == 0:
		return
	for i in range(n):
		var path: String = creature_scenes[i]
		var scene: PackedScene = load(path)
		if scene == null:
			push_warning("[OrbTestRig] could not load creature %s" % path)
			continue
		var creature: Node3D = scene.instantiate()
		var angle: float = TAU * (float(i) / float(n))
		var offset: Vector3 = Vector3(cos(angle) * creature_radius, 0.5, sin(angle) * creature_radius)
		creature.position = offset
		# Stop them wandering for the test — apply_grid_config keeps them in frame.
		if creature.has_method("apply_grid_config"):
			creature.call("apply_grid_config", {
				"speed": 0.0,
				"chase_speed": 0.0,
				"detection_radius": 0.0,
			})
		add_child(creature)


# ── XR rig finder ───────────────────────────────────────────────────────

func _find_xr_origin() -> Node3D:
	var root: Node = get_tree().root
	return _find_first_of_class(root, "XROrigin3D")


static func _find_first_of_class(node: Node, type_name: String) -> Node3D:
	if node.get_class() == type_name:
		return node
	for c in node.get_children():
		var r := _find_first_of_class(c, type_name)
		if r != null:
			return r
	return null


# ── apply_grid_config (so the artifact registry can place it) ──────────

func apply_grid_config(config: Dictionary) -> void:
	if config.has("auto_spawn_creatures"):
		auto_spawn_creatures = bool(config["auto_spawn_creatures"])
	if config.has("creature_radius"):
		creature_radius = float(config["creature_radius"])
	if config.has("verbose"):
		verbose = bool(config["verbose"])
