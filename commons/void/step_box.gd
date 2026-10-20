extends Node3D
## A one-metre support that reveals one reward when the visitor stands on it.
## Its collider never opens. Reusable by later Randomness lessons: choose once,
## retain the result while the floor sleeps, reset with the encounter.
signal revealed(kind: String)
const Kit = preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const Cube = preload("res://commons/artifacts/primitive_encounters/platform_block.tscn")
const Health = preload("res://commons/artifacts/health_cross/health_cross.tscn")
const Piece = preload("res://commons/artifacts/primitive_encounters/piece.gd")
const PREFABS = [
	preload("res://commons/artifacts/primitive_encounters/tetrahedron_blocker.tscn"),
	preload("res://commons/artifacts/primitive_encounters/pyramid_blocker.tscn"),
	preload("res://commons/artifacts/primitive_encounters/wedge_blocker.tscn"),
]
const NAMES = ["tetrahedron", "pyramid", "wedge"]
@export_enum("health", "prefab") var contents := "health"
@export var boost := 25.0
## A non-negative seed makes a later probability lesson repeatable.
@export var reward_seed := -1
var health_provider: Node
var opened := false
var selected_kind := ""
var reward: Node3D
var badge: StandardMaterial3D

func apply_grid_config(config: Dictionary) -> void:
	if opened: return
	contents = str(config.get("contents", contents))
	if contents not in ["health", "prefab"]: contents = "health"
	boost = clampf(float(config.get("boost", boost)), 1, 100)
	reward_seed = int(config.get("reward_seed", reward_seed))

func _ready() -> void:
	var support := Cube.instantiate()
	support.name = "MetreBox"
	add_child(support)
	badge = Kit.material(Color("d9a2bd") if contents == "prefab" else Color("89d3bc"))
	badge.emission_enabled = true
	badge.emission = badge.albedo_color
	badge.emission_energy_multiplier = 0.5
	# Flush ink is visible in the editor and does not catch the player's feet.
	for bar in [Vector3(.32,.006,.045), Vector3(.045,.006,.32)]:
		var mark := Kit.box(self, "StepMark", Vector3(0,1.006,0), bar, Color.WHITE, false)
		mark.material_override = badge
	if contents == "prefab":
		for i in 4:
			var angle := i*PI/2
			var mark := Kit.box(self, "ParcelEdge", Vector3(sin(angle)*.2,1.006,cos(angle)*.2), Vector3(.28,.006,.018), Color.WHITE, false)
			mark.rotation.y = angle
			mark.material_override = badge

func _physics_process(_delta: float) -> void:
	if opened: return
	for body in get_tree().get_nodes_in_group("player_body"):
		if can_open_from(body):
			open_box()
			return

func can_open_from(body: Node) -> bool:
	if not body is CharacterBody3D or not body.is_in_group("player_body"): return false
	if not body.is_on_floor(): return false
	var feet := to_local(body.global_position)
	return absf(feet.x) < .5 and absf(feet.z) < .5 and feet.y >= .94 and feet.y <= 1.18

func open_box() -> void:
	if opened: return
	opened = true
	if contents == "health":
		var cross := Health.instantiate()
		cross.health_provider = health_provider
		cross.boost = boost
		cross.take_below = 1.0
		cross.respawn_s = 0
		cross.arm_m = .23
		cross.hover_m = .45
		reward = cross
		selected_kind = "health"
	else:
		var rng := RandomNumberGenerator.new()
		if reward_seed >= 0: rng.seed = reward_seed
		else: rng.randomize()
		var index := rng.randi_range(0, PREFABS.size()-1)
		selected_kind = NAMES[index]
		var piece := Piece.new()
		# Existing desktop pointer and XR grip use exactly the same piece.
		piece.collision_layer = 6
		piece.collision_mask = 1
		var miniature := PREFABS[index].instantiate() as Node3D
		miniature.scale = Vector3.ONE*.24
		piece.add_child(miniature)
		reward = piece
	reward.name = "Reward"
	reward.position = Vector3(0,1.12,-.22)
	add_child(reward)
	if contents == "prefab":
		# Keep the original meshes/materials; replace their scenery collision with
		# one small pickable collider. The reward cannot push a visitor off a path.
		for body in reward.find_children("*","StaticBody3D",true,false):
			# wp keeps its visible prism UNDER its StaticBody3D.
			for surface in body.find_children("*","MeshInstance3D",true,false):
				surface.reparent(reward, true)
			body.free()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(.36,.3,.48)
		collision.shape = shape
		collision.position.y = .15
		reward.add_child(collision)
	badge.emission_energy_multiplier = .1
	revealed.emit(selected_kind)
	# Late-created pickables must be discovered by floor streaming.
	var floor_root := get_parent()
	while floor_root != null:
		if floor_root.has_meta("void_content_floor"):
			floor_root.get_parent().floor_changed.emit(int(floor_root.get_meta("void_content_floor")))
			break
		floor_root = floor_root.get_parent()
