extends Node3D

var time = 0.0
var transformation_stage = 0
var stage_timer = 0.0
var stage_interval = 3.0

# Transformation types
enum TransformationType {
	ROTATION,
	SCALING,
	TRANSLATION,
	SHEARING
}

var current_transformation = TransformationType.ROTATION

func _ready():
	setup_materials()
	setup_initial_transforms()

func setup_materials():
	# Point material - bright white
	var point_material = StandardMaterial3D.new()
	point_material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	point_material.emission_enabled = true
	point_material.emission = Color(0.8, 0.8, 0.8, 1.0)
	$Point.material_override = point_material
	
	# Line material - blue
	var line_material = StandardMaterial3D.new()
	line_material.albedo_color = Color(0.3, 0.7, 1.0, 1.0)
	line_material.emission_enabled = true
	line_material.emission = Color(0.1, 0.2, 0.4, 1.0)
	$Line.material_override = line_material
	
	# Plane material - green with transparency
	var plane_material = StandardMaterial3D.new()
	plane_material.albedo_color = Color(0.3, 1.0, 0.3, 0.7)
	plane_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plane_material.emission_enabled = true
	plane_material.emission = Color(0.1, 0.3, 0.1, 1.0)
	$Plane.material_override = plane_material
	
	# Cube material - red (applied to the CubeBaseMesh inside cube_scene.tscn)
	var cube_material = StandardMaterial3D.new()
	cube_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	cube_material.emission_enabled = true
	cube_material.emission = Color(0.4, 0.1, 0.1, 1.0)
	
	# Apply material to the MeshInstance3D inside the cube scene
	var cube_mesh = $Cube.get_node("CubeBaseStaticBody3D/CubeBaseMesh")
	if cube_mesh:
		cube_mesh.material_override = cube_material
	
	# Transformation indicator materials
	var rotation_material = StandardMaterial3D.new()
	rotation_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	rotation_material.emission_enabled = true
	rotation_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$TransformationControls/RotationIndicator.material_override = rotation_material
	
	var scale_material = StandardMaterial3D.new()
	scale_material.albedo_color = Color(0.8, 0.2, 1.0, 1.0)
	scale_material.emission_enabled = true
	scale_material.emission = Color(0.2, 0.05, 0.3, 1.0)
	$TransformationControls/ScaleIndicator.material_override = scale_material
	
	var translation_material = StandardMaterial3D.new()
	translation_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	translation_material.emission_enabled = true
	translation_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$TransformationControls/TranslationIndicator.material_override = translation_material

func setup_initial_transforms():
	# Reset all objects to base positions
	$Point.position = Vector3(-6, 0, 0)
	$Line.position = Vector3(-2, 0, 0)
	$Plane.position = Vector3(2, 0, 0)
	$Cube.position = Vector3(6, 0, 0)
	
	# Reset scales and rotations
	$Point.scale = Vector3.ONE
	$Line.scale = Vector3.ONE
	$Plane.scale = Vector3.ONE
	$Cube.scale = Vector3.ONE
	
	$Point.rotation = Vector3.ZERO
	$Line.rotation = Vector3.ZERO
	$Plane.rotation = Vector3.ZERO
	$Cube.rotation = Vector3.ZERO

func _process(delta):
	time += delta
	stage_timer += delta
	
	# Cycle through transformation types
	if stage_timer >= stage_interval:
		stage_timer = 0.0
		current_transformation = (current_transformation + 1) % TransformationType.size()
		
		# Reset transforms when starting new cycle
		if current_transformation == TransformationType.ROTATION:
			setup_initial_transforms()
	
	apply_transformations()
	animate_indicators()

func apply_transformations():
	var progress = stage_timer / stage_interval
	var smooth_progress = smoothstep(0.0, 1.0, progress)
	
	match current_transformation:
		TransformationType.ROTATION:
			apply_rotation_transformations(smooth_progress)
		
		TransformationType.SCALING:
			apply_scaling_transformations(smooth_progress)
		
		TransformationType.TRANSLATION:
			apply_translation_transformations(smooth_progress)
		
		TransformationType.SHEARING:
			apply_shearing_transformations(smooth_progress)

func apply_rotation_transformations(progress):
	# Point: Simple pulsing (0D -> can't really rotate, so pulse instead)
	var pulse = 1.0 + sin(time * 4.0) * 0.3
	$Point.scale = Vector3.ONE * pulse
	
	# Line: Rotate around Y-axis
	$Line.rotation.y = progress * PI * 2.0
	
	# Plane: Rotate around X and Z axes
	$Plane.rotation.x = progress * PI
	$Plane.rotation.z = progress * PI * 0.5
	
	# Cube: Complex rotation around multiple axes
	$Cube.rotation.x = progress * PI * 1.5
	$Cube.rotation.y = progress * PI * 2.0
	$Cube.rotation.z = progress * PI * 0.75

func apply_scaling_transformations(progress):
	# Point: Scale uniformly
	var scale_factor = 1.0 + progress * 2.0
	$Point.scale = Vector3.ONE * scale_factor
	
	# Line: Scale length (Y-axis)
	$Line.scale.y = 1.0 + progress * 2.0
	
	# Plane: Non-uniform scaling
	$Plane.scale.x = 1.0 + progress * 1.5
	$Plane.scale.z = 1.0 + progress * 0.5
	
	# Cube: Asymmetric scaling
	$Cube.scale.x = 1.0 + sin(progress * PI) * 1.0
	$Cube.scale.y = 1.0 + cos(progress * PI) * 1.0
	$Cube.scale.z = 1.0 + progress * 0.8

func apply_translation_transformations(progress):
	var base_positions = [Vector3(-6, 0, 0), Vector3(-2, 0, 0), Vector3(2, 0, 0), Vector3(6, 0, 0)]
	
	# Point: Linear motion
	$Point.position = base_positions[0] + Vector3(0, sin(progress * PI) * 2.0, 0)
	
	# Line: Circular motion
	var angle = progress * PI * 2.0
	$Line.position = base_positions[1] + Vector3(cos(angle) * 1.0, sin(angle) * 1.0, 0)
	
	# Plane: Figure-8 motion
	$Plane.position = base_positions[2] + Vector3(
		sin(progress * PI * 2.0) * 1.0,
		sin(progress * PI * 4.0) * 0.5,
		cos(progress * PI * 2.0) * 0.5
	)
	
	# Cube: Complex 3D path
	$Cube.position = base_positions[3] + Vector3(
		sin(progress * PI * 3.0) * 0.8,
		cos(progress * PI * 2.0) * 1.2,
		sin(progress * PI * 4.0) * 0.6
	)

func apply_shearing_transformations(progress):
	# Create shearing effect using transform basis manipulation
	var shear_amount = progress * 0.5
	
	# Point: No shearing (0D), but add wobble effect
	var wobble = sin(time * 6.0) * 0.1
	$Point.position.x = -6 + wobble
	
	# Line: Shear along one axis
	var line_transform = Transform3D()
	line_transform.basis = Basis(
		Vector3(1.0, shear_amount, 0),
		Vector3(0, 1.0, 0),
		Vector3(0, 0, 1.0)
	)
	line_transform.origin = Vector3(-2, 0, 0)
	$Line.transform = line_transform
	
	# Plane: Shear in multiple directions
	var plane_transform = Transform3D()
	plane_transform.basis = Basis(
		Vector3(1.0, shear_amount * 0.5, 0),
		Vector3(shear_amount * 0.3, 1.0, 0),
		Vector3(0, 0, 1.0)
	)
	plane_transform.origin = Vector3(2, 0, 0)
	$Plane.transform = plane_transform
	
	# Cube: Complex 3D shearing
	var cube_transform = Transform3D()
	cube_transform.basis = Basis(
		Vector3(1.0, shear_amount * 0.4, shear_amount * 0.2),
		Vector3(shear_amount * 0.3, 1.0, shear_amount * 0.1),
		Vector3(shear_amount * 0.1, shear_amount * 0.2, 1.0)
	)
	cube_transform.origin = Vector3(6, 0, 0)
	$Cube.transform = cube_transform

func animate_indicators():
	# Highlight current transformation indicator
	var indicators = [
		$TransformationControls/RotationIndicator,
		$TransformationControls/ScaleIndicator,
		$TransformationControls/TranslationIndicator,
		$TransformationControls/RotationIndicator  # Rotation for shearing (placeholder)
	]
	
	# Reset all indicators
	for i in range(indicators.size()):
		var indicator = indicators[i]
		var base_scale = 1.0
		var glow_intensity = 0.2
		
		if i == current_transformation:
			base_scale = 1.0 + sin(time * 8.0) * 0.3
			glow_intensity = 0.5 + sin(time * 6.0) * 0.3
		
		indicator.scale = Vector3.ONE * base_scale
		
		# Update emission intensity
		var material = indicator.material_override as StandardMaterial3D
		if material:
			var base_emission = material.emission
			material.emission = base_emission * glow_intensity

func get_transformation_name() -> String:
	match current_transformation:
		TransformationType.ROTATION:
			return "Rotation"
		TransformationType.SCALING:
			return "Scaling"
		TransformationType.TRANSLATION:
			return "Translation"
		TransformationType.SHEARING:
			return "Shearing"
		_:
			return "Unknown"
