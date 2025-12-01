extends Node3D

## Turtle Test Script
## Verifies 3D rotation logic

var turtle: Turtle3D

func _ready():
	turtle = Turtle3D.new()
	add_child(turtle)
	turtle.branch_thickness = 0.05
	turtle.branch_length = 1.0
	turtle.set_colors(Color.RED, Color.GREEN)
	
	# Test Sequence
	print("Start: UP")
	turtle.forward() # Should go UP (Global Y)
	
	print("Turn Right 90")
	turtle.turn_right(90) # Should face RIGHT (Global X)
	turtle.forward()
	
	print("Pitch Down 90")
	turtle.pitch_down(90) # Should face BACK (Global Z) or FRONT depending on coord system
	turtle.forward()
	
	print("Turn Left 90")
	turtle.turn_left(90) # Should face LEFT relative to current, or UP/DOWN?
	turtle.forward()
	
	# Visual markers for axes
	var marker = MeshInstance3D.new()
	marker.mesh = BoxMesh.new()
	add_child(marker)

func _process(delta):
	rotation.y += delta * 0.5
