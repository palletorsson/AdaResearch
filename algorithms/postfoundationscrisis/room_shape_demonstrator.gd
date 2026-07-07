# Room Shape Demonstrator — the room's geometry IS the policy
#
# A scale model of a room sits on a pedestal. The room has two seating arrangements
# visible: a long table with one chair at the head (centralized authority) and the same
# room with seats arranged in a circle (distributed). Toggle indicators show which
# arrangement each implies — a *who can speak first* question encoded in the floor plan.
#
# Pairs with ethical_design_clipboard: the clipboard names the principles, this artifact
# shows the geometry. Room shape is not neutral.
#
# @identity: First map where furniture layout is the moral object.
# @qfep_term: Edge — what the architecture forecloses.

extends Node3D
class_name RoomShapeDemonstrator

@export var room_color: Color = Color(0.8, 0.76, 0.7, 1.0)
@export var chair_color_authority: Color = Color(0.95, 0.45, 0.35, 1.0)
@export var chair_color_distributed: Color = Color(0.5, 0.85, 0.55, 1.0)
@export var room_size: Vector3 = Vector3(1.6, 0.5, 1.0)
@export var pedestal_height: float = 0.8


func _ready() -> void:
	_build_pedestal()
	_build_centralized_room()
	_build_distributed_room()
	_build_labels()


func apply_grid_config(config_data: Dictionary) -> void:
	pass


func _build_pedestal() -> void:
	for x_off in [-1.0, 1.0]:
		var ped := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(room_size.x + 0.2, pedestal_height, room_size.z + 0.2)
		ped.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.32, 0.38, 1.0)
		mat.roughness = 0.7
		ped.material_override = mat
		ped.position = Vector3(x_off, pedestal_height * 0.5, 0)
		add_child(ped)


func _build_centralized_room() -> void:
	# Walls — three sides only, so the model is visible.
	var origin := Vector3(-1.0, pedestal_height + room_size.y * 0.5, 0.0)
	_build_room_walls(origin, room_color)
	# Long table.
	var table := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 0.04, 0.18)
	table.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.4, 0.3, 1.0)
	table.material_override = mat
	table.position = origin + Vector3(0, -room_size.y * 0.5 + 0.16, 0)
	add_child(table)
	# Head-of-table chair.
	var chair := _make_chair(chair_color_authority)
	chair.position = origin + Vector3(0.6, -room_size.y * 0.5 + 0.1, 0)
	add_child(chair)
	# Other chairs (smaller, lighter — they have less floor presence).
	for x_off in [-0.3, 0.0, 0.3]:
		for z_off in [-0.18, 0.18]:
			var c := _make_chair(Color(0.7, 0.6, 0.55, 1.0))
			c.scale = Vector3(0.6, 0.6, 0.6)
			c.position = origin + Vector3(x_off, -room_size.y * 0.5 + 0.06, z_off)
			add_child(c)


func _build_distributed_room() -> void:
	var origin := Vector3(1.0, pedestal_height + room_size.y * 0.5, 0.0)
	_build_room_walls(origin, room_color)
	# Round table.
	var table := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.25
	cyl.bottom_radius = 0.25
	cyl.height = 0.04
	table.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.4, 0.3, 1.0)
	table.material_override = mat
	table.position = origin + Vector3(0, -room_size.y * 0.5 + 0.16, 0)
	add_child(table)
	# Six equal chairs in a circle.
	for i in 6:
		var a: float = TAU * float(i) / 6.0
		var chair := _make_chair(chair_color_distributed)
		chair.position = origin + Vector3(cos(a) * 0.4, -room_size.y * 0.5 + 0.1, sin(a) * 0.4)
		add_child(chair)


func _build_room_walls(origin: Vector3, color: Color) -> void:
	for wall_data in [
		{"size": Vector3(room_size.x, room_size.y, 0.04), "pos": Vector3(0, 0, -room_size.z * 0.5)},
		{"size": Vector3(0.04, room_size.y, room_size.z), "pos": Vector3(-room_size.x * 0.5, 0, 0)},
		{"size": Vector3(0.04, room_size.y, room_size.z), "pos": Vector3(room_size.x * 0.5, 0, 0)},
		{"size": Vector3(room_size.x, 0.04, room_size.z), "pos": Vector3(0, -room_size.y * 0.5, 0)},
	]:
		var wall := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = wall_data["size"]
		wall.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.9
		wall.material_override = mat
		wall.position = origin + wall_data["pos"]
		add_child(wall)


func _make_chair(color: Color) -> MeshInstance3D:
	var chair := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.1, 0.18, 0.1)
	chair.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.4
	chair.material_override = mat
	return chair


func _build_labels() -> void:
	var a := Label3D.new()
	a.text = "centralized"
	a.font_size = 22
	a.modulate = chair_color_authority
	a.position = Vector3(-1.0, pedestal_height + room_size.y + 0.25, 0)
	a.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(a)
	var b := Label3D.new()
	b.text = "distributed"
	b.font_size = 22
	b.modulate = chair_color_distributed
	b.position = Vector3(1.0, pedestal_height + room_size.y + 0.25, 0)
	b.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(b)
