extends Node3D

@export var animation_speed: float = 1.0
@export var blend_speed: float = 2.0

var _player_model: Node3D
var _animation_tree: AnimationTree
var _skeleton: Skeleton3D
var _time: float = 0.0

# Bone trackers
var _bone_trackers: Dictionary = {}

func _ready():
	_load_player_model()
	_setup_bone_trackers()

func _load_player_model():
	var player_scene = load("res://algorithms/wavefunctions/dancing_body/player.glb")
	if player_scene:
		_player_model = player_scene.instantiate()
		add_child(_player_model)
		
		# Find skeleton
		_skeleton = _find_skeleton(_player_model)
		
		# Setup animation tree
		_setup_animation_tree()

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = _find_skeleton(child)
		if result:
			return result
	return null

func _setup_animation_tree():
	# Create a simple animation tree that cycles through animations
	_animation_tree = AnimationTree.new()
	add_child(_animation_tree)
	
	if _player_model:
		var anim_player = _player_model.get_node_or_null("AnimationPlayer")
		if anim_player:
			_animation_tree.anim_player = anim_player.get_path()

func _setup_bone_trackers():
	if not _skeleton:
		return
		
	# Track key bones for Fourier analysis
	var bones_to_track = ["l-arm", "r-arm", "l-forearm", "r-forearm", "head"]
	
	for bone_name in bones_to_track:
		var bone_idx = _skeleton.find_bone(bone_name)
		if bone_idx >= 0:
			# Create a trace ball for this bone
			var tracker = preload("res://commons/primitives/point/draw_dot.tscn").instantiate()
			tracker.record_only_when_grabbed = false
			tracker.fade_trail = true
			tracker.fade_duration = 10.0
			add_child(tracker)
			
			_bone_trackers[bone_name] = {
				"idx": bone_idx,
				"tracker": tracker
			}

func _process(delta):
	_time += delta
	
	# Update bone tracker positions
	if _skeleton:
		for bone_name in _bone_trackers:
			var data = _bone_trackers[bone_name]
			var bone_idx = data["idx"]
			var tracker = data["tracker"]
			
			# Get global position of bone
			var bone_pose = _skeleton.get_bone_global_pose(bone_idx)
			var bone_global_pos = _skeleton.global_transform * bone_pose.origin
			
			tracker.global_position = bone_global_pos
