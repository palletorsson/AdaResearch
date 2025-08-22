extends Node3D

@export var butterfly_scene: PackedScene
var timer: Timer  # Timer to handle spawning intervals

func _ready() -> void:
	# Set up the timer to spawn butterflies every 30 seconds
	timer = Timer.new()
	timer.wait_time = 10.0
	timer.one_shot = false  # Keep the timer running repeatedly
	timer.connect("timeout", Callable(self, "spawn_butterflies"))
	add_child(timer)
	timer.start()  # Start the timer

# Spawn butterflies and play animations
func spawn_butterflies() -> void:
	for n in range(1):
		if butterfly_scene:
			var butterfly_instance = butterfly_scene.instantiate() as Node3D
			add_child(butterfly_instance)
			butterfly_instance.add_to_group("remove")  # Optional group for management
			
			# Check if the instantiated scene has the necessary nodes
			var butterfly_node = butterfly_instance.get_node("butterfly")
			if butterfly_node:
				var animation_player = butterfly_node.get_node("AnimationPlayer")
				if animation_player:
					animation_player.play("fly")  # Play the "fly" animation
				else:
					print("Error: AnimationPlayer not found in 'butterfly' node.")
			else:
				print("Error: 'butterfly' node not found in instantiated scene.")
		else:
			print("Error: Butterfly scene is not assigned.")
