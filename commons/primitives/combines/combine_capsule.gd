extends Node3D

# Capsule Grid Display System
# Generates a grid of capsules by combining height and segment values with gradient coloring
#
# @identity
# essence: a lattice of capsules sweeping height against radial_segments, each painted with UV-space lines so the three-zone hemisphere-cylinder-hemisphere body of a capsule stays legible at every density
# desire: to show that a capsule is a cylinder that grew two caps — vary the height and the middle stretches, vary the segments and the whole skin sharpens or smooths
# critical_parameter: height_values × radial_segments_values — the two sweep axes (rings held fixed at 6); each pair spawns one labelled capsule, gradient-coloured orange→blue by index
# triggers: _ready() seeds an orange→blue gradient if unset and calls generate_capsule_grid(); each cell builds a CapsuleMesh + ParametricGrid material + a Label3D naming its height and segments
# emerges: the difference between geometric parameters (height, a real length) and topological ones (segments, a count) shown side by side — height stretches, segments tessellate, and they do not trade against each other
# needs: CapsuleMesh grid generator [present]; ParametricGrid material via grid_material_factory [present]; per-cell height/segment labels [present]; @identity [present, 2026-07-18]; class_name — absent, spawned by scene
# relationships: sibling of combine_sphere and combine_torus (shared parameter-sweep grammar); a primitives-sequence teaching table; the capsule is the sphere's elongated cousin
# truth: length and resolution are different kinds of number — one measures the world, the other measures how coarsely you agreed to describe it, and the capsule wears both at once.

@export_group("Capsule Parameters")
@export var radius: float = 0.3
@export var height_values: Array[float] = [0.6, 0.9, 1.2, 1.5]
@export var radial_segments_values: Array[int] = [8, 12, 16, 20]
@export var rings: int = 6

@export_group("Grid Settings")
@export var spacing: float = 3.0

## AXIS — WHAT ORDER THE SWEEP CLAIMS ITS FAMILY HAS. The members never change: the same
## height × radial_segments pairs are built, in the same order, with the same colours.
## What changes is whether the display asserts that the family has a structure, and whose
## structure it is. Adopted word for word from [[combine_sphere]] — this is the same
## apparatus pointed at a different primitive, so it gets the same vocabulary rather than
## a private one that would make two halves of one grammar argue past each other.
##
##   table    the lattice — two independent axes, position IS the parameter, every
##            member captioned with the numbers that made it. The periodic-table claim:
##            the order is in the objects and the display merely reports it.
##   ladder   the cross-product collapsed to one ascending file, each member a step
##            higher than the last. The claim that the family is a SEQUENCE with a
##            direction and not a plane of independent choices.
##   stack    one column, every member on the same footprint. The claim that these are
##            not many objects but ONE object described at many resolutions.
##   heap     coordinates abandoned: the members piled at the origin, uncaptioned. The
##            claim that the ordering was ours all along and the objects never had it.
##
## The captions are the pivot. They are the only text in the frame and they are what makes
## the table a table; `heap` withholds them, which is why that value reads from across a
## room. It bites hardest here because a capsule's height is a LENGTH — take the numbers
## away and the one axis you could only ever have read off the label is gone.
@export_enum("table", "ladder", "stack", "heap") var taxonomy: String = "table"
const TAXONOMIES: PackedStringArray = ["table", "ladder", "stack", "heap"]

@export_group("Visual Settings")
@export var use_wireframe: bool = false
@export var metallic: float = 0.15
@export var roughness: float = 0.35
@export var color_gradient: Gradient
@export var wireframe_width: float = 0.1
@export var wireframe_brightness: float = 2.0

const GRID_SHADER_PATH = "res://commons/resourses/shaders/basic_grid.gdshader"
const GridMaterialFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")

# When true (default), each capsule paints radial_segments × rings (longitudes
# × latitudes) as UV-space lines via ParametricGrid. The visual encoding
# stays legible at every density.
@export var use_parametric_grid: bool = true

var capsule_instances: Array[MeshInstance3D] = []
var grid_shader: Shader

func _ready():
	var _t: String = str(taxonomy).strip_edges().to_lower()
	taxonomy = _t if TAXONOMIES.has(_t) else "table"

	if not use_parametric_grid:
		grid_shader = load(GRID_SHADER_PATH)
		if not grid_shader:
			push_error("Failed to load SimpleGrid shader from: " + GRID_SHADER_PATH)

	if color_gradient == null:
		color_gradient = Gradient.new()
		color_gradient.set_color(0, Color(0.9, 0.5, 0.2, 1.0))
		color_gradient.set_color(1, Color(0.2, 0.4, 1.0, 1.0))
	generate_capsule_grid()

func generate_capsule_grid():
	clear_existing_capsules()
	if height_values.is_empty() or radial_segments_values.is_empty():
		return
	var total = height_values.size() * radial_segments_values.size()
	var index = 0
	var z_pos = 0.0
	for height_value in height_values:
		var x_pos = 0.0
		for segments in radial_segments_values:
			var ratio = 0.0 if total <= 1 else float(index) / float(total - 1)
			create_capsule_at_position(_taxonomy_place(Vector3(x_pos, 0, z_pos), index), height_value, segments, ratio)
			index += 1
			x_pos += spacing
		z_pos += spacing

func create_capsule_at_position(pos: Vector3, height_value: float, segments: int, gradient_ratio: float):
	var mesh_instance = MeshInstance3D.new()
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = radius
	capsule_mesh.height = height_value
	capsule_mesh.rings = rings
	capsule_mesh.radial_segments = segments
	mesh_instance.mesh = capsule_mesh
	mesh_instance.position = pos

	var gradient_color: Color = color_gradient.sample(gradient_ratio) if color_gradient else Color(1, 1, 1, 1)

	if use_parametric_grid:
		# CapsuleMesh UV: u = longitude (radial_segments). Height is geometric
		# (not segment-count) so v gets a fixed default that reads as the
		# top-cylinder-bottom three-zone structure of the capsule.
		var pg_material := GridMaterialFactory.make_parametric(
			gradient_color, segments, max(rings, 4),
			{ "line_color": Color(0.3, 0.9, 1.0), "emission": wireframe_brightness }
		)
		if pg_material is ShaderMaterial:
			(pg_material as ShaderMaterial).render_priority = 1
		mesh_instance.material_override = pg_material
	elif grid_shader:
		var shader_material = ShaderMaterial.new()
		shader_material.shader = grid_shader
		shader_material.set_shader_parameter("line_color", Vector3(0.3, 0.9, 1.0))
		shader_material.set_shader_parameter("fill_color", Vector3(gradient_color.r, gradient_color.g, gradient_color.b))
		shader_material.set_shader_parameter("line_width", wireframe_width * 10.0)
		shader_material.set_shader_parameter("emission_strength", wireframe_brightness)
		shader_material.render_priority = 1
		mesh_instance.material_override = shader_material
	else:
		# Fallback to standard material if shader fails to load
		var material = StandardMaterial3D.new()
		if use_wireframe:
			material.flags_use_point_size = true
			material.flags_wireframe = true
		material.albedo_color = color_gradient.sample(gradient_ratio) if color_gradient else Color(1, 1, 1, 1)
		material.metallic = metallic
		material.roughness = roughness
		mesh_instance.material_override = material

	# Set sorting offset to help with depth issues
	mesh_instance.sorting_offset = 1.0

	# The caption is what makes the lattice a table. `heap` is the one value that withholds
	# it — a pile of unnamed bodies is the whole of that claim. Every other value, `table`
	# included, keeps the legacy caption at the legacy offset.
	if taxonomy != "heap":
		create_label_for_capsule(pos + Vector3(0, 1.6, 0), height_value, segments)
	add_child(mesh_instance)
	capsule_instances.append(mesh_instance)

func create_label_for_capsule(pos: Vector3, height_value: float, segments: int):
	var label = Label3D.new()
	label.text = "Height: " + str("%0.2f" % height_value) + "\nSegments: " + str(segments)
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	label.outline_size = 4
	add_child(label)

func clear_existing_capsules():
	for child in get_children():
		child.queue_free()
	capsule_instances.clear()

func regenerate_grid():
	generate_capsule_grid()

func set_wireframe_mode(enabled: bool):
	use_wireframe = enabled
	update_materials()

func set_color_gradient(gradient: Gradient):
	if gradient:
		color_gradient = gradient
	else:
		color_gradient = Gradient.new()
		color_gradient.set_color(0, Color(0.9, 0.5, 0.2, 1.0))
		color_gradient.set_color(1, Color(0.2, 0.4, 1.0, 1.0))
	update_colors()

func update_materials():
	for mesh_instance in capsule_instances:
		if mesh_instance and is_instance_valid(mesh_instance):
			var material = mesh_instance.material_override
			if material is ShaderMaterial:
				material.set_shader_parameter("line_width", wireframe_width * 10.0)
			elif material is StandardMaterial3D:
				# Fallback for standard materials
				if use_wireframe:
					material.flags_wireframe = true
					material.flags_use_point_size = true
				else:
					material.flags_wireframe = false
					material.flags_use_point_size = false

func update_colors():
	var count = capsule_instances.size()
	if count == 0:
		return
	for i in range(count):
		var mesh_instance = capsule_instances[i]
		if mesh_instance and is_instance_valid(mesh_instance):
			var material = mesh_instance.material_override
			var ratio = 0.0 if count <= 1 else float(i) / float(count - 1)
			var gradient_color = color_gradient.sample(ratio) if color_gradient else Color(1, 1, 1, 1)

			if material is ShaderMaterial:
				material.set_shader_parameter("fill_color", Vector3(gradient_color.r, gradient_color.g, gradient_color.b))
			elif material is StandardMaterial3D:
				material.albedo_color = gradient_color

func get_capsule_count() -> int:
	return capsule_instances.size()


# ── TAXONOMY ─────────────────────────────────────────────────────────────────
# One axis, four claims about whether the family has an order. Shared word for word with
# combine_sphere.gd. Appended LAST so nothing above it moved: `table` returns the cell the
# legacy loop already computed, coordinate for coordinate, and every member keeps its
# caption. The other three discard the cell and re-site the member from its index alone.

## Where a member of the sweep stands.
func _taxonomy_place(cell: Vector3, index: int) -> Vector3:
	match taxonomy:
		"ladder":
			# One ascending file. The two axes of the cross-product are spent as a single
			# ordered run, lifted a step per member, so the family reads as a sequence
			# going somewhere rather than a plane of independent choices.
			return Vector3(float(index) * spacing * 0.62, float(index) * spacing * 0.17, 0.0)
		"stack":
			# One column on one footprint: the same object, described again and again.
			return Vector3(0.0, float(index) * spacing * 0.34, 0.0)
		"heap":
			# Coordinates abandoned. The scatter is a HASH of the index, never randf():
			# a random render path would make each sweep frame a different pile, and the
			# critic would be measuring the noise instead of the axis.
			var a: float = _index_hash(index * 2 + 1) * TAU
			var r: float = spacing * 0.55 * sqrt(_index_hash(index * 2 + 2))
			return Vector3(cos(a) * r, _index_hash(index * 2 + 7) * spacing * 0.24, sin(a) * r)
		_:
			return cell                    # "table" — the legacy lattice, untouched


## Deterministic 0..1 from an integer. Same value every boot, every frame, every machine.
func _index_hash(n: int) -> float:
	var s: float = sin(float(n) * 12.9898 + 78.233) * 43758.5453
	return s - floor(s)
