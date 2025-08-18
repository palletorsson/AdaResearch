extends Node3D

var time = 0.0
var data_points = []
var bias_level = 0.5
var fairness_score = 0.3

class DataPoint:
	var position: Vector2
	var group: String  # "A" or "B"
	var prediction: bool
	var actual: bool
	var visual_object: CSGSphere3D
	
	func _init(pos: Vector2, grp: String, act: bool):
		position = pos
		group = grp
		actual = act
		prediction = false

func _ready():
	create_biased_dataset()
	setup_materials()

func create_biased_dataset():
	# Create dataset with systematic bias
	for i in range(100):
		var pos = Vector2(randf() * 8 - 4, randf() * 6 - 3)
		var group = "A" if randf() < 0.6 else "B"  # Unequal representation
		var actual = pos.y > sin(pos.x) * 2  # True classification
		
		var point = DataPoint.new(pos, group, actual)
		
		# Biased prediction - Group A gets unfair advantage
		if group == "A":
			point.prediction = actual or randf() < 0.3  # False positives
		else:
			point.prediction = actual and randf() > 0.2  # False negatives
		
		var sphere = CSGSphere3D.new()
		sphere.radius = 0.08
		sphere.position = Vector3(pos.x, pos.y, 0)
		$DataPoints.add_child(sphere)
		point.visual_object = sphere
		
		data_points.append(point)

func setup_materials():
	# Update data point materials based on bias
	for point in data_points:
		var material = StandardMaterial3D.new()
		
		# Color based on group and prediction accuracy
		if point.group == "A":
			if point.prediction == point.actual:
				material.albedo_color = Color(0.2, 1.0, 0.2, 1.0)  # Correct - green
			else:
				material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)  # Incorrect - yellow
		else:  # Group B
			if point.prediction == point.actual:
				material.albedo_color = Color(0.2, 0.8, 1.0, 1.0)  # Correct - blue
			else:
				material.albedo_color = Color(1.0, 0.2, 0.2, 1.0)  # Incorrect - red
		
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.4
		point.visual_object.material_override = material

func _process(delta):
	time += delta
	
	# Calculate bias metrics
	calculate_bias_metrics()
	
	animate_bias_visualization()
	animate_indicators()

func calculate_bias_metrics():
	var group_a_correct = 0
	var group_a_total = 0
	var group_b_correct = 0
	var group_b_total = 0
	
	for point in data_points:
		if point.group == "A":
			group_a_total += 1
			if point.prediction == point.actual:
				group_a_correct += 1
		else:
			group_b_total += 1
			if point.prediction == point.actual:
				group_b_correct += 1
	
	var accuracy_a = float(group_a_correct) / group_a_total if group_a_total > 0 else 0
	var accuracy_b = float(group_b_correct) / group_b_total if group_b_total > 0 else 0
	
	bias_level = abs(accuracy_a - accuracy_b)
	fairness_score = 1.0 - bias_level

func animate_bias_visualization():
	# Animate data points to show bias
	for i in range(data_points.size()):
		var point = data_points[i]
		
		# Pulsing based on bias
		var pulse_intensity = 0.2 if point.prediction == point.actual else 0.5
		var pulse = 1.0 + sin(time * 6.0 + i * 0.1) * pulse_intensity
		point.visual_object.scale = Vector3.ONE * pulse
		
		# Height based on confidence (biased)
		var confidence = 0.5 + sin(time * 2.0 + point.position.x) * 0.3
		if point.group == "B":
			confidence *= 0.7  # Lower confidence for Group B
		
		point.visual_object.position.z = confidence * 0.5

func animate_indicators():
	# Bias indicator
	var bias_height = bias_level * 2.0 + 0.5
	$BiasIndicator.height  = bias_height 
	$BiasIndicator.position.y = -3 + bias_height/2
	
	# Fairness metric
	var fairness_height = fairness_score * 2.0 + 0.5
	$FairnessMetric.size.y = fairness_height
	$FairnessMetric.position.y = -3 + fairness_height/2
	
	# Update colors based on bias level
	var bias_material = StandardMaterial3D.new()
	bias_material.albedo_color = Color(1.0, 1.0 - bias_level, 0.2, 1.0)
	bias_material.emission_enabled = true
	bias_material.emission = bias_material.albedo_color * 0.3
	$BiasIndicator.material_override = bias_material
	
	var fairness_material = StandardMaterial3D.new()
	fairness_material.albedo_color = Color(0.2 + fairness_score * 0.6, 1.0, 0.3, 1.0)
	fairness_material.emission_enabled = true
	fairness_material.emission = fairness_material.albedo_color * 0.3
	$FairnessMetric.material_override = fairness_material
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$BiasIndicator.scale.x = pulse
	$FairnessMetric.scale.x = pulse
