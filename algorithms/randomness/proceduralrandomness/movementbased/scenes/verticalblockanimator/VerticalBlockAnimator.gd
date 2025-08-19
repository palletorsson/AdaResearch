extends Node3D

# Stops the animation after the specified time
@export var auto_stop_seconds: float = 20.0

@onready var mesh_instance = $MeshInstance3D

func _ready():
	# Load the shader (make sure the path is correct)
	var material = ShaderMaterial.new()
	material.shader = preload("res://algorithms/randomness/proceduralrandomness/movementbased/scenes/verticalblockanimator/SquareWavePattern.gdshader")  # 


	# Apply to the mesh
	mesh_instance.material_override = material
	
	# Set up auto-stop if enabled
	if auto_stop_seconds > 0:
		get_tree().create_timer(auto_stop_seconds).timeout.connect(_stop_animation)

func _stop_animation():
	# Generate a random pattern when stopping
	if mesh_instance.material_override:
		# Generate a random number between 1000-10000 to ensure a unique pattern
		var random_time = 1000.0 + randf() * 9000.0
		
		# Stop the animation by setting time_scale to 0
		mesh_instance.material_override.set_shader_parameter("time_scale", 0.0)
		
		# Set custom time to freeze at a random pattern
		mesh_instance.material_override.set_shader_parameter("custom_time", random_time)
		
		print("Animation stopped with random pattern (time value: ", random_time, ")")
