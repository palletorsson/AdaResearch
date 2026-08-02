extends Node3D

# Sphere Grid Display System
# Generates a grid of spheres using ring and segment combinations with gradient coloring
#
# @identity
# essence: a 2D lattice of spheres, one per (rings × radial_segments) pair, each surface painted with exactly that many latitude/longitude lines so its tessellation parameters are readable at a glance
# desire: to turn two abstract mesh parameters into a walkable table — you don't read "rings=8, segments=16", you see the ball that those numbers make
# critical_parameter: rings_values × radial_segments_values — the two axes of the sweep; every entry pair spawns one labelled sphere at spacing intervals, gradient-coloured by its index
# triggers: _ready() seeds a blue→pink gradient if unset and calls generate_sphere_grid(); each cell builds a SphereMesh + ParametricGrid material + a billboard Label3D naming its rings/segments/hemisphere
# emerges: the discretisation of a smooth surface made visible — coarse spheres read as faceted gems, fine ones as smooth balls, and the whole grid is the continuum of that trade-off
# needs: SphereMesh grid generator [present]; ParametricGrid material via grid_material_factory [present]; per-cell parameter labels [present]; @identity [present, 2026-07-18]; class_name — absent, spawned by scene
# relationships: sibling of combine_capsule and combine_torus (the same parameter-sweep grammar over different primitives); a primitives-sequence teaching table; downstream of the point/line/grid ontology
# truth: a sphere is not a thing but a decision about how finely to cut a curve — the grid lets you hold every version of that decision at once and choose with your eyes.

@export_group("Sphere Parameters")
@export var radius: float = 0.3
@export var rings_values: Array[int] = [1, 2, 4, 8, 12, 16]
@export var radial_segments_values: Array[int] = [6, 8, 12, 16]
@export var hemisphere_default: bool = false
@export var alternate_hemisphere: bool = false

@export_group("Grid Settings")
@export var spacing: float = 2.5

## AXIS — WHAT ORDER THE SWEEP CLAIMS ITS FAMILY HAS. The members never change: the same
## rings × radial_segments pairs are built, in the same order, with the same colours. What
## changes is whether the display asserts that the family has a structure, and whose
## structure it is. Adopted word for word by [[combine_capsule]], which is the same
## apparatus pointed at a different primitive — one grammar, one vocabulary, so a room
## holding both cannot have one of them arguing taxonomy and the other arguing pile.
##
##   table    the lattice — two independent axes, position IS the parameter, every
##            member captioned with the numbers that made it. The periodic-table claim:
##            the order is in the objects and the display merely reports it.
##   ladder   the cross-product collapsed to one ascending file, each member a step
##            higher than the last. The claim that the family is a SEQUENCE with a
##            direction — coarse to fine — and not a plane of independent choices.
##   stack    one column, every member on the same footprint. The claim that these are
##            not many objects but ONE object described at many resolutions.
##   heap     coordinates abandoned: the members piled at the origin, uncaptioned. The
##            claim that the ordering was ours all along and the objects never had it.
##
## The captions are the pivot. They are the only text in the frame and they are what makes
## the table a table; `heap` withholds them, which is why that value reads from the far
## side of a room.
@export_enum("table", "ladder", "stack", "heap") var taxonomy: String = "table"
const TAXONOMIES: PackedStringArray = ["table", "ladder", "stack", "heap"]

@export_group("Visual Settings")
@export var use_wireframe: bool = false
@export var metallic: float = 0.1
@export var roughness: float = 0.3
@export var color_gradient: Gradient
@export var wireframe_width: float = 0.1
@export var wireframe_brightness: float = 2.0

const GRID_SHADER_PATH = "res://commons/resourses/shaders/basic_grid.gdshader"
const GridMaterialFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")

# When true (default), each sphere paints (radial_segments × rings) as
# UV-space lines (longitudes × latitudes) via ParametricGrid. High-poly
# spheres still read as their parameter values rather than smooth balls.
@export var use_parametric_grid: bool = true

var sphere_instances: Array[MeshInstance3D] = []
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
		color_gradient.set_color(0, Color(0.2, 0.6, 1.0, 1.0))
		color_gradient.set_color(1, Color(1.0, 0.3, 0.6, 1.0))
	generate_sphere_grid()

func generate_sphere_grid():
	clear_existing_spheres()
	if rings_values.is_empty() or radial_segments_values.is_empty():
		return
	var total = rings_values.size() * radial_segments_values.size()
	var index = 0
	var z_pos = 0.0
	for rings in rings_values:
		var x_pos = 0.0
		for segments in radial_segments_values:
			var ratio = 0.0 if total <= 1 else float(index) / float(total - 1)
			create_sphere_at_position(_taxonomy_place(Vector3(x_pos, 0, z_pos), index), rings, segments, ratio, index)
			index += 1
			x_pos += spacing
		z_pos += spacing

func create_sphere_at_position(pos: Vector3, rings: int, segments: int, gradient_ratio: float, grid_index: int):
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	sphere_mesh.rings = rings
	sphere_mesh.radial_segments = segments
	var hemisphere_enabled = hemisphere_default
	if alternate_hemisphere:
		hemisphere_enabled = (grid_index % 2) == 0
	sphere_mesh.is_hemisphere = hemisphere_enabled
	mesh_instance.mesh = sphere_mesh
	mesh_instance.position = pos

	var gradient_color: Color = color_gradient.sample(gradient_ratio) if color_gradient else Color(1, 1, 1, 1)

	if use_parametric_grid:
		# SphereMesh UV: u = longitude (radial_segments), v = latitude (rings).
		var pg_material := GridMaterialFactory.make_parametric(
			gradient_color, segments, rings,
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
	# it — a pile of unnamed balls is the whole of that claim. Every other value, `table`
	# included, keeps the legacy caption at the legacy offset.
	if taxonomy != "heap":
		create_label_for_sphere(pos + Vector3(0, 1.4, 0), rings, segments, hemisphere_enabled)
	add_child(mesh_instance)
	sphere_instances.append(mesh_instance)

func create_label_for_sphere(pos: Vector3, rings: int, segments: int, hemisphere_enabled: bool):
	var label = Label3D.new()
	label.text = "Rings: " + str(rings) + "\nSegments: " + str(segments) + "\nHemisphere: " + ("Yes" if hemisphere_enabled else "No")
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	label.outline_size = 4
	add_child(label)

func clear_existing_spheres():
	for child in get_children():
		child.queue_free()
	sphere_instances.clear()

func regenerate_grid():
	generate_sphere_grid()

func set_wireframe_mode(enabled: bool):
	use_wireframe = enabled
	update_materials()

func set_color_gradient(gradient: Gradient):
	if gradient:
		color_gradient = gradient
	else:
		color_gradient = Gradient.new()
		color_gradient.set_color(0, Color(0.2, 0.6, 1.0, 1.0))
		color_gradient.set_color(1, Color(1.0, 0.3, 0.6, 1.0))
	update_colors()

func update_materials():
	for mesh_instance in sphere_instances:
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
	var count = sphere_instances.size()
	if count == 0:
		return
	for i in range(count):
		var mesh_instance = sphere_instances[i]
		if mesh_instance and is_instance_valid(mesh_instance):
			var material = mesh_instance.material_override
			var ratio = 0.0 if count <= 1 else float(i) / float(count - 1)
			var gradient_color = color_gradient.sample(ratio) if color_gradient else Color(1, 1, 1, 1)

			if material is ShaderMaterial:
				material.set_shader_parameter("fill_color", Vector3(gradient_color.r, gradient_color.g, gradient_color.b))
			elif material is StandardMaterial3D:
				material.albedo_color = gradient_color

func get_sphere_count() -> int:
	return sphere_instances.size()


# ── TAXONOMY ─────────────────────────────────────────────────────────────────
# One axis, four claims about whether the family has an order. Shared word for word with
# combine_capsule.gd. Appended LAST so nothing above it moved: `table` returns the cell the
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
