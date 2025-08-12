extends Node3D

@export var width_meters: float = 1.0
@export var height_meters: float = 3.0
@export var depth_meters: float = 1.0

@export var variation_seed: float = -1.0
@export_range(0.5, 2.0, 0.05) var panel_scale: float = 1.0
@export_range(0.0, 1.0, 0.01) var accent_density: float = 0.35
@export_range(0.0, 1.0, 0.01) var scratch_intensity: float = 0.2
@export_range(0.005, 0.05, 0.001) var line_width: float = 0.02

@onready var static_body: StaticBody3D = $StaticBody3D
@onready var mesh_instance: MeshInstance3D = $StaticBody3D/Mesh
@onready var collision_shape: CollisionShape3D = $StaticBody3D/CollisionShape3D

func _ready():
	randomize()
	_apply_dimensions()
	_apply_material_variation()
	print("scene init")

func _apply_dimensions():
	if mesh_instance == null or collision_shape == null:
		push_warning("SciFiPanelWall: Child nodes not found; skipping dimension setup")
		return

	var box_mesh := mesh_instance.mesh as BoxMesh
	if box_mesh:
		box_mesh.size = Vector3(width_meters, height_meters, depth_meters)
	else:
		# Fallback: create a BoxMesh if missing
		var new_mesh := BoxMesh.new()
		new_mesh.size = Vector3(width_meters, height_meters, depth_meters)
		mesh_instance.mesh = new_mesh

	var box_shape := collision_shape.shape as BoxShape3D
	if box_shape:
		box_shape.size = Vector3(width_meters, height_meters, depth_meters)
	else:
		var new_shape := BoxShape3D.new()
		new_shape.size = Vector3(width_meters, height_meters, depth_meters)
		collision_shape.shape = new_shape

	# Place the panel so its base sits on the parent's origin (y=0)
	if static_body:
		static_body.position.y = height_meters * 0.5

func _apply_material_variation():
	if mesh_instance == null:
		return
	var mat := mesh_instance.material_override
	if mat == null:
		return
	if mat is ShaderMaterial:
		var shader_mat := mat as ShaderMaterial
		# unique per instance so panels look different
		mesh_instance.material_override = shader_mat.duplicate()
		shader_mat = mesh_instance.material_override as ShaderMaterial

		var seed_value = variation_seed
		if seed_value < 0.0:
			seed_value = randf()

		shader_mat.set_shader_parameter("seed", seed_value)
		shader_mat.set_shader_parameter("panel_scale", panel_scale)
		shader_mat.set_shader_parameter("accent_density", accent_density)
		shader_mat.set_shader_parameter("scratch_intensity", scratch_intensity)
		shader_mat.set_shader_parameter("line_width", line_width)
