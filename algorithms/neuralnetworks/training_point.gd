class_name TrainingPoint
extends VREntity

## Visual representation of a training data point for perceptron
## Shows position and label (above/below line)

var label: int = 1  # 1 or -1
var inputs: Array[float] = []

# Colors for classification
var positive_color: Color = Color(1.0, 0.6, 1.0, 1.0)  # Bright pink (class 1)
var negative_color: Color = Color(0.5, 0.5, 0.9, 1.0)  # Blue (class -1)
var correct_color: Color = Color(0.3, 1.0, 0.3, 1.0)   # Green (correctly classified)
var incorrect_color: Color = Color(1.0, 0.3, 0.3, 1.0) # Red (misclassified)

var is_classified_correctly: bool = false

func _init(pos: Vector3, target_label: int):
	position_v = pos
	label = target_label
	inputs = [pos.x, pos.y, 1.0]  # Bias term included

func setup_mesh():
	"""Create small sphere for data point"""
	mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	mesh_instance.mesh = sphere
	add_child(mesh_instance)

func setup_material():
	"""Color based on label"""
	material = StandardMaterial3D.new()
	material.albedo_color = positive_color if label == 1 else negative_color
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.5
	material.emission_energy_multiplier = 1.0

	if mesh_instance:
		mesh_instance.material_override = material

func update_classification(predicted_label: int):
	"""Update visual based on whether classification is correct"""
	is_classified_correctly = (predicted_label == label)

	if material:
		if is_classified_correctly:
			material.albedo_color = correct_color
			material.emission = correct_color * 0.5
		else:
			material.albedo_color = incorrect_color
			material.emission = incorrect_color * 0.5

func reset_color():
	"""Reset to original label color"""
	if material:
		material.albedo_color = positive_color if label == 1 else negative_color
		material.emission = material.albedo_color * 0.5

func check_boundaries():
	"""Override - don't constrain to tank, points are static"""
	pass
