# Pedestal.gd - Display pedestal for math objects
@tool
extends Node3D

@export var pedestal_color: Color = Color(0.15, 0.15, 0.2):
	set(value):
		pedestal_color = value
		_update_material()

@export var pedestal_radius: float = 0.08:
	set(value):
		pedestal_radius = value
		_update_mesh()

@export var pedestal_height: float = 0.02:
	set(value):
		pedestal_height = value
		_update_mesh()

func _ready() -> void:
	_create_pedestal()
	_update_mesh()
	_update_material()

func _create_pedestal() -> void:
	var existing = get_node_or_null("PedestalMesh")
	if existing:
		return
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "PedestalMesh"
	add_child(mesh_instance)
	
	# Add snap point for shelf snapping
	var snap_point = Node3D.new()
	snap_point.name = "SnapPoint"
	snap_point.add_to_group("shelf_snap_point")
	add_child(snap_point)

func _update_mesh() -> void:
	var mesh_instance = get_node_or_null("PedestalMesh") as MeshInstance3D
	if not mesh_instance:
		return
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = pedestal_radius
	cylinder.bottom_radius = pedestal_radius * 1.1
	cylinder.height = pedestal_height
	cylinder.radial_segments = 32
	mesh_instance.mesh = cylinder
	mesh_instance.position.y = pedestal_height / 2.0
	
	# Update snap point position
	var snap_point = get_node_or_null("SnapPoint")
	if snap_point:
		snap_point.position.y = pedestal_height + 0.05

func _update_material() -> void:
	var mesh_instance = get_node_or_null("PedestalMesh") as MeshInstance3D
	if not mesh_instance:
		return
	
	var material = StandardMaterial3D.new()
	material.albedo_color = pedestal_color
	material.metallic = 0.5
	material.roughness = 0.4
	mesh_instance.material_override = material
