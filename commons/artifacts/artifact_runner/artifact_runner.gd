extends Node3D
class_name ArtifactRunner

## Endless artifact-review runner — NO map_data.json.
##
## Streams the review queue (commons/artifacts/artifact_runner/artifact_queue.gd)
## ARTIFACTS_PER_SLOT at a time. Each slot is a procedural floor strip with 5
## artifacts on the left and 5 on the right of the path; you walk +z down the
## middle. A sliding window keeps a few slots loaded ahead and frees them behind
## — the same streaming model as spine_runner, but spawning registry artifacts
## (lookup_name → scene → instantiate) instead of GridSystems.
##
## Launch:  commons/scenes/desktop_artifact_runner.tscn  (or the VR variant)

const ArtifactQueueScript = preload("res://commons/artifacts/artifact_runner/artifact_queue.gd")

@export var artifacts_per_slot: int = 10
@export var slot_depth: float = 16.0      # z length of one chunk
@export var slot_width: float = 12.0      # x span of the floor
@export var row_x: float = 3.2            # how far left/right of the path each row sits
@export var slots_ahead: int = 2
@export var slots_behind: int = 1
@export var debug_print: bool = true
# Queue source. only_maps restricts to specific concept-map stubs
# (e.g. ["foundations","qfep","postcrisis"]); empty = all ten.
@export var only_maps: Array[String] = []
@export var shuffle_within_map: bool = false
@export var use_all_registry: bool = false  # ignore concept maps, walk every registered artifact
# Strip streamed artifacts from the physics world (collision off, rigidbodies frozen) so a spawning
# RigidBody/SoftBody can't shove or trap the player. You walk THROUGH them; they still animate. Off = let
# them collide (you can be body-checked when a chunk loads).
@export var artifacts_inert: bool = true

# Tier → uniform scale, so room-scale artifacts fit a corridor cell.
const TIER_SCALE := {"small": 1.0, "medium": 0.85, "large": 0.4, "applied": 0.75}

var _queue: Array = []                  # [{name, tier, section}]
var _name_scene: Dictionary = {}        # lookup_name -> scene path
var _slots: Dictionary = {}             # slot_idx -> Node3D
var _n_slots: int = 0
var _player: Node3D = null
var _current_idx: int = -1
var _header: Label3D = null


func _ready() -> void:
	_build_name_scene_index()
	if use_all_registry:
		_queue = ArtifactQueueScript.build_all_registry()
	else:
		_queue = ArtifactQueueScript.build(only_maps, shuffle_within_map)
	# keep only entries we can actually instantiate
	_queue = _queue.filter(func(e): return _name_scene.has(str(e.get("name", ""))))
	if _queue.is_empty():
		push_error("ArtifactRunner: queue empty (no resolvable artifacts)")
		return
	_n_slots = int(ceil(float(_queue.size()) / float(artifacts_per_slot)))
	_print("queue=%d artifacts, %d slots of %d" % [_queue.size(), _n_slots, artifacts_per_slot])

	_header = Label3D.new()
	_header.font_size = 56
	_header.outline_size = 10
	_header.modulate = Color(1.0, 0.9, 0.55)
	_header.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_header.no_depth_test = true
	_header.position = Vector3(0, 3.4, 4.0)
	add_child(_header)

	_find_player()
	# Defer the first spawn: spawning slots/artifacts DURING _ready runs each
	# artifact's _ready while the tree is still blocked (mid-add), which trips
	# add_child / global-transform calls in many legacy artifacts. Let _ready
	# finish first so every artifact enters a settled, unblocked tree.
	call_deferred("_update_window")


func _build_name_scene_index() -> void:
	var dir := DirAccess.open("res://commons/artifacts/registry")
	if dir == null:
		push_error("ArtifactRunner: no registry dir")
		return
	for fn in dir.get_files():
		if not fn.ends_with(".json"):
			continue
		var f := FileAccess.open("res://commons/artifacts/registry/" + fn, FileAccess.READ)
		if f == null:
			continue
		var data = JSON.parse_string(f.get_as_text())
		if not (data is Dictionary):
			continue
		for k in (data.get("artifacts", {}) as Dictionary).keys():
			var v = data["artifacts"][k]
			if v is Dictionary and v.has("scene"):
				var sc := str(v["scene"])
				if ResourceLoader.exists(sc):
					_name_scene[str(v.get("lookup_name", k))] = sc
	_print("registry index: %d resolvable artifacts" % _name_scene.size())


func _process(_delta: float) -> void:
	if _player == null:
		_find_player()
		return
	_update_window()


func _update_window() -> void:
	var pz: float = _player.global_position.z if _player else 0.0
	var idx: int = clampi(int(floor(pz / slot_depth)), 0, _n_slots - 1)
	var lo: int = maxi(0, idx - slots_behind)
	var hi: int = mini(_n_slots - 1, idx + slots_ahead)
	for i in range(lo, hi + 1):
		if not _slots.has(i):
			_spawn_slot(i)
	for key in _slots.keys():
		if int(key) < lo or int(key) > hi:
			_free_slot(int(key))
	if idx != _current_idx:
		_current_idx = idx
		_refresh_header(idx)


func _refresh_header(idx: int) -> void:
	if _header == null:
		return
	var first: Dictionary = _queue[idx * artifacts_per_slot] if idx * artifacts_per_slot < _queue.size() else {}
	var section := str(first.get("section", ""))
	_header.text = "[%d/%d]  %s\n(walk north · 10 at a time)" % [idx + 1, _n_slots, section]
	_header.global_position = Vector3(0, 3.4, float(idx) * slot_depth + 4.0)


func _spawn_slot(idx: int) -> void:
	if idx < 0 or idx >= _n_slots:
		return
	var z0: float = float(idx) * slot_depth
	var root := Node3D.new()
	root.name = "ArtSlot_%d" % idx
	root.position = Vector3(0, 0, z0)
	add_child(root)
	_slots[idx] = root

	# Floor strip the player walks on.
	var floor := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(slot_width, 0.2, slot_depth)
	col.shape = box
	col.position = Vector3(0, -0.1, slot_depth * 0.5)
	floor.add_child(col)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mi.mesh = bm
	mi.position = col.position
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.10, 0.11, 0.14) if idx % 2 == 0 else Color(0.13, 0.14, 0.18)
	mi.material_override = fmat
	floor.add_child(mi)
	root.add_child(floor)

	# Ten artifacts: 5 left (x = -row_x), 5 right (x = +row_x), spaced along z.
	var start: int = idx * artifacts_per_slot
	var per_side: int = int(artifacts_per_slot / 2)
	for j in range(artifacts_per_slot):
		var qi: int = start + j
		if qi >= _queue.size():
			break
		var entry: Dictionary = _queue[qi]
		var side: float = -1.0 if j < per_side else 1.0
		var slot_in_side: int = j if j < per_side else j - per_side
		var lz: float = (float(slot_in_side) + 0.5) * (slot_depth / float(per_side))
		_spawn_artifact(root, entry, Vector3(side * row_x, 0.0, lz))


func _spawn_artifact(root: Node3D, entry: Dictionary, local_pos: Vector3) -> void:
	var name := str(entry.get("name", ""))
	var scene_path: String = _name_scene.get(name, "")
	if scene_path == "":
		return
	var packed = load(scene_path)
	if packed == null:
		return
	var inst = packed.instantiate()
	if inst == null:
		return
	var holder := Node3D.new()
	holder.position = local_pos
	# Put the holder in the (already-live) slot tree FIRST, with its name plate, then
	# add the artifact LAST — so the artifact's _ready fires as a clean top-level add
	# into a settled, unblocked tree (it can add_child / read global transforms safely).
	root.add_child(holder)
	var tag := Label3D.new()
	tag.text = name
	tag.font_size = 22
	tag.outline_size = 5
	tag.modulate = Color(0.8, 0.85, 0.95)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 0.05, 0)
	holder.add_child(tag)
	var s: float = float(TIER_SCALE.get(str(entry.get("tier", "medium")), 0.85))
	inst.scale = Vector3(s, s, s)
	holder.add_child(inst)   # inst enters a live tree here → its _ready runs cleanly
	# Config AFTER tree-entry, so the artifact's _ready has built its nodes first.
	if inst.has_method("apply_grid_config"):
		inst.apply_grid_config({"emissive": false})
	# Strip from the physics world LAST (after config may have rebuilt children), so a
	# spawning RigidBody/SoftBody can't body-check or trap the player as the chunk loads.
	if artifacts_inert:
		_make_inert(inst)


# Recursively remove a streamed artifact from physics: no collisions in or out, rigidbodies
# frozen so they don't fall. You walk THROUGH it; it still renders and animates.
func _make_inert(node: Node) -> void:
	if node is CollisionObject3D:
		node.collision_layer = 0
		node.collision_mask = 0
		if node is RigidBody3D:
			node.freeze = true
		elif node is CharacterBody3D:
			node.set_physics_process(false)
	elif node is SoftBody3D:
		# SoftBody3D is a MeshInstance3D, not a CollisionObject3D — it has its own layers.
		node.collision_layer = 0
		node.collision_mask = 0
	for c in node.get_children():
		_make_inert(c)


func _free_slot(idx: int) -> void:
	if not _slots.has(idx):
		return
	var s: Node = _slots[idx]
	_slots.erase(idx)
	if is_instance_valid(s):
		s.queue_free()
	_print("free slot %d" % idx)


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player_body")
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		var dp := get_tree().root.find_child("DesktopPlayer", true, false)
		if dp:
			_player = dp


func _print(msg: String) -> void:
	if debug_print:
		print("ArtifactRunner: ", msg)
