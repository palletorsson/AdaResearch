extends MeshInstance3D

@export var speed: float = 2.0
@export var radius: float = 6.0
@export var height_var: float = 2.0

var time: float = 0.0

func _process(delta):
	time += delta * speed
	
	# Complex Lissajous-like motion to test all parameters
	# X changes Pan
	# Z changes Distance (Freq/Amp)
	# Y changes Grain Pitch (Direction.y)
	# Speed changes Grain Density
	
	position.x = sin(time) * radius
	position.z = cos(time * 0.8) * radius - 5.0 
	position.y = sin(time * 1.3) * height_var
