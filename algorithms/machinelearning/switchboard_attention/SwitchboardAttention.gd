extends Node3D

@onready var inputs_parent: Node3D = $Inputs
@onready var outputs_parent: Node3D = $Outputs
@onready var connections_parent: Node3D = $Connections

var input_nodes: Array[Node3D] = []
var output_nodes: Array[Node3D] = []

var query_index: int = 0

func _ready() -> void:
	# Create input and output nodes
	for i in range(5):
		var input_node = MeshInstance3D.new()
		input_node.mesh = SphereMesh.new()
		input_node.position = Vector3(-5, i * 1.5 - 3, 0)
		inputs_parent.add_child(input_node)
		input_nodes.append(input_node)

		var output_node = MeshInstance3D.new()
		output_node.mesh = BoxMesh.new()
		output_node.position = Vector3(5, i * 1.5 - 3, 0)
		outputs_parent.add_child(output_node)
		output_nodes.append(output_node)
	
	_update_connection()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		query_index = (query_index + 1) % input_nodes.size()
		_update_connection()
	if event.is_action_pressed("ui_down"):
		query_index = (query_index - 1 + input_nodes.size()) % input_nodes.size()
		_update_connection()

func _update_connection() -> void:
	# Clear existing connections
	for child in connections_parent.get_children():
		child.queue_free()

	var query_node = input_nodes[query_index]

	# Find the closest output node (the "Key")
	var closest_output: Node3D
	var min_dist = INF
	for output_node in output_nodes:
		var dist = query_node.global_transform.origin.distance_to(output_node.global_transform.origin)
		if dist < min_dist:
			min_dist = dist
			closest_output = output_node
	
	# Draw a "cable" between the query and the key
	var cable = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.1
	cyl.bottom_radius = 0.1
	cyl.height = min_dist
	cable.mesh = cyl
	
	var from = query_node.global_transform.origin
	var to = closest_output.global_transform.origin
	cable.global_transform.origin = (from + to) / 2
	cable.look_at(from, Vector3.UP)
	
	connections_parent.add_child(cable)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
