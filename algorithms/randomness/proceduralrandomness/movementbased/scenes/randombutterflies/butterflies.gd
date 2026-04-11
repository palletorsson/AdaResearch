extends Node3D

# Butterfly spawner — spawns entropy-seeking butterflies.
# Butterflies discover entropy_axiom nodes in the scene and are drawn to them.

@export var butterfly_scene: PackedScene
@export var spawn_interval: float = 10.0
@export var max_butterflies: int = 8  # Cap to keep performance reasonable

var timer: Timer


func _ready() -> void:
	timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.one_shot = false
	timer.timeout.connect(_on_spawn_timeout)
	add_child(timer)
	timer.start()

	# Spawn one immediately so the scene isn't empty
	_spawn_butterfly()


func _on_spawn_timeout() -> void:
	# Count current butterflies
	var count: int = get_tree().get_nodes_in_group("entropy_butterfly").size()
	if count < max_butterflies:
		_spawn_butterfly()


func _spawn_butterfly() -> void:
	if not butterfly_scene:
		return

	var instance: Node3D = butterfly_scene.instantiate() as Node3D
	if not instance:
		return

	add_child(instance)
	instance.add_to_group("remove")

	# Start the fly animation on the inner butterfly node
	var butterfly_node: Node3D = instance.find_child("butterfly", true, false) as Node3D
	if butterfly_node:
		var anim: AnimationPlayer = butterfly_node.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim:
			anim.play("fly")

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
