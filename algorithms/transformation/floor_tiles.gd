@tool
extends Node3D

@export var tile_size: float = 0.4      # s
@export var gutter: float = 0.01        # g
@export var count_x: int = 20
@export var count_z: int = 20
@export var half_stagger: bool = false  # shift every other row by half step
@export var global_offset: Vector3 = Vector3(0, 0, 0)
@export var tile_mesh: Mesh = null
@export_group("Rotation")
@export var base_rotation_degrees: float = 45.0
@export var random_rotation: bool = false
@export var random_rotation_min: float = 0.0
@export var random_rotation_max: float = 360.0
@export_group("Materials")
@export var alternating_colors: bool = true
@export var color_a: Color = Color.BLACK
@export var color_b: Color = Color.WHITE
@export var stagger_different_color: bool = false
@export var stagger_color_a: Color = Color.RED
@export var stagger_color_b: Color = Color.BLUE
@export var regenerate: bool = false: set = _set_regenerate

@onready var mm_inst: MultiMeshInstance3D = MultiMeshInstance3D.new()

func _ready() -> void:
	generate_tiles()

func _set_regenerate(value: bool) -> void:
	if value:
		generate_tiles()
		regenerate = false

func generate_tiles() -> void:
	# Clear existing multimesh instance
	if mm_inst.get_parent():
		mm_inst.get_parent().remove_child(mm_inst)

	add_child(mm_inst)
	if Engine.is_editor_hint():
		mm_inst.owner = get_tree().edited_scene_root

	var mm := MultiMesh.new()
	mm_inst.multimesh = mm
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = alternating_colors

	# Create default mesh if none provided
	if tile_mesh == null:
		var box := BoxMesh.new()
		box.size = Vector3(tile_size, 0.01, tile_size)

		# Create material with vertex color support
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		box.material = mat

		mm.mesh = box
	else:
		mm.mesh = tile_mesh
		# set BoxMesh size to tile_size with tiny thickness
		if tile_mesh is BoxMesh:
			tile_mesh.size = Vector3(tile_size, 0.01, tile_size)

	# For 45-degree rotated tiles, spacing needs to account for the diagonal
	var is_45_rotated: bool = abs(base_rotation_degrees - 45.0) < 0.1 or abs(base_rotation_degrees - -45.0) < 0.1
	var spacing_x: float = tile_size + gutter
	var spacing_z: float = tile_size + gutter

	if is_45_rotated:
		if half_stagger:
			# When rotated 45 degrees with stagger, use full diagonal for X, half for Z
			spacing_x = tile_size * sqrt(2.0) + gutter
			spacing_z = tile_size * sqrt(2.0) / 2.0 + gutter
		else:
			# When rotated 45 degrees without stagger, use full diagonal
			spacing_x = tile_size * sqrt(2.0) + gutter
			spacing_z = tile_size * sqrt(2.0) + gutter

	var base_rot := Basis(Vector3.UP, deg_to_rad(base_rotation_degrees))
	var total := count_x * count_z
	mm.instance_count = total

	var k := 0
	for j in range(count_z):
		for i in range(count_x):
			var ii := float(i)
			var jj := float(j)
			if half_stagger and (j % 2 != 0):
				ii += 0.5  # half-step shift on odd rows

			# Regular grid layout with separate X and Z spacing
			var x := spacing_x * ii
			var z := spacing_z * jj

			# Apply rotation (base + optional random)
			var rotation := base_rot
			if random_rotation:
				var random_angle := randf_range(random_rotation_min, random_rotation_max)
				rotation = Basis(Vector3.UP, deg_to_rad(random_angle))

			var xf := Transform3D(rotation, Vector3(x, 0.0, z) + global_offset)
			mm.set_instance_transform(k, xf)

			# Set alternating colors
			if alternating_colors:
				var use_color_a := (i + j) % 2 == 0
				var is_staggered_row := half_stagger and (j % 2 != 0)

				if stagger_different_color and is_staggered_row:
					mm.set_instance_color(k, stagger_color_a if use_color_a else stagger_color_b)
				else:
					mm.set_instance_color(k, color_a if use_color_a else color_b)

			k += 1

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
