extends Node3D

class_name ConstraintBlock

@export var block_color: Color = Color.WHITE
@export var initial_position: Vector3 = Vector3.ZERO
@export var is_fixed: bool = false

var block_size: Vector3 = Vector3(0.5, 0.5, 0.5)

func _ready():
	_create_block_mesh()
	_create_constraint_indicator()

func _create_block_mesh():
	# Create the block cube
	var cube = CSGBox3D.new()
	cube.size = block_size
	cube.material = StandardMaterial3D.new()
	cube.material.albedo_color = block_color
	cube.material.emission_enabled = true
	cube.material.emission = block_color * 0.1
	
	add_child(cube)

func _create_constraint_indicator():
	if is_fixed:
		# Add visual indicator for fixed blocks
		var indicator = CSGSphere3D.new()
		indicator.radius = 0.1
		indicator.material = StandardMaterial3D.new()
		indicator.material.albedo_color = Color.BLACK
		indicator.material.emission_enabled = true
		indicator.material.emission = Color.BLACK * 0.5
		indicator.position = Vector3(0, 0.4, 0)
		
		add_child(indicator)
		
		# Add text label for fixed blocks
		var label = Label3D.new()
		label.text = "FIXED"
		label.font_size = 16
		label.pixel_size = 0.05
		label.position = Vector3(0, 0.8, 0)
		add_child(label)
