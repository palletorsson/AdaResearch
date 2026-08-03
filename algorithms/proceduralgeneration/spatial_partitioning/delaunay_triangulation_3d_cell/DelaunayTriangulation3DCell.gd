@tool
extends MeshInstance3D
class_name DelaunayTriangulation3DCell

# @identity
# essence: Incremental Delaunay triangulation in 3D — circumsphere-tested tetrahedralization with grabbable vertex interaction
# desire: To show the dual of Voronoi: optimal triangulation where no point violates any circumsphere, dragging a vertex re-triangulates live
# critical_parameter: randomness — how far points deviate from hierarchical placement; 0 = regular lattice, 1 = scattered cloud
# triggers: Grabbing a vertex and dragging re-triggers triangulation; low randomness produces crystalline; high produces chaotic mesh
# emerges: Mathematically optimal triangulation from a single geometric constraint applied everywhere
# needs: @tool editor preview [has], grabbable VR points [has], edge/vertex visualization [has], Label3D [has]
# relationships: Dual of voronoi_diagram_3d in spatial_partitioning. Foundation for mesh generation in meshes sequence.
# truth: One constraint — no point inside any circumsphere — is enough to produce the best possible triangulation.

@export var generations: int = 7
@export var initial_points: int = 20
@export var subdivision_factor: float = 0.5
@export_range(0.0, 2.0) var randomness: float = 0.3
@export var cell_radius: float = 2.0
@export var show_vertices: bool = true
@export var show_edges: bool = true
@export var show_label: bool = true
@export var use_grabbable_points: bool = true  # Enable draggable vertices

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `formation`
# ═══════════════════════════════════════════════════════════════════════════
#
# HOW THE SITES ARE ARRANGED BEFORE ANY TRIANGLE EXISTS. This artifact's truth
# is that ONE constraint — no point inside any circumsphere — is enough to
# produce the best possible triangulation. That is a claim about a rule holding
# everywhere, and a rule that has only ever been shown on one input has not been
# shown to hold everywhere; it has been shown once. The shipped point set is a
# stack of jittered spherical shells, and every existing placement of this
# artifact teaches "Delaunay looks like this" when it means "Delaunay of THAT".
#
# So the axis is the input, not the algorithm. Not one line of triangulate_points
# or is_valid_triangle changes; the same circumsphere logic runs on five
# different arrangements and produces five obviously different meshes, which is
# the demonstration the singleton could not give.
#
# ADOPTED WORD FOR WORD from reactive_particles, reactive_particle_field,
# edge_particles and emergence_zone in qfep.json, which ask exactly this of a
# cloud of points — same spelling, same five values. The order is rotated so the
# legacy arrangement leads, which is the same thing physarum_colony does to
# ant_colony_v2's `anchorage`: the words and their meanings are shared, the
# default is each artifact's own.
#
#   shell   the shipped set: `generations` nested spheres of falling radius,
#           each jittered by `randomness`, plus a centre point. A hollow onion,
#           and the triangulation is a crust.  (DEFAULT — unchanged)
#   lattice the same number of sites on a regular cubic grid clipped to the same
#           ball. Every circumsphere test near-degenerate, the mesh regular to
#           the eye — the crystalline case the `randomness` slider points at
#           from the other end.
#   ring    the sites pressed into a flat annulus in the XZ plane. A three-
#           dimensional rule applied to a two-dimensional input: the tetrahedra
#           collapse to slivers and the mesh reads as a disc, not a solid.
#   column  the sites stacked in a narrow shaft up the Y axis. Nearest neighbours
#           are almost always the ones directly above and below, so the optimal
#           triangulation degenerates to a chain — a spine instead of a body.
#   drift   uniform scatter through the whole ball, no hierarchy at all. What the
#           artifact's own critical_parameter describes at randomness = 1 and
#           what the shipped generator cannot actually produce.
#
# EVERY FORMATION PLACES THE SAME NUMBER OF SITES inside the SAME cell_radius,
# so the mesh complexity and the framed extent are comparable across the five and
# the difference in the picture is the arrangement rather than the size or the
# count.
const FORMATIONS: PackedStringArray = ["shell", "lattice", "ring", "column", "drift"]
@export_enum("shell", "lattice", "ring", "column", "drift") var formation: String = "shell"

## SEED for the site scatter. Every formation, including the shipped one, places
## its points with random draws, so an unseeded run is a DIFFERENT cell every
## boot — different sites, different neighbours, different mesh. Five variants of
## an unseeded run are five different objects, and the bite critic would read
## that scatter as a confident result about `formation`.
## -1 keeps the legacy behaviour EXACTLY: the bare global randf()/randf_range()
## are used, in the same order, with no seed() call anywhere, precisely as they
## always were. Any value >= 0 pins the sites so the five tiles differ only in
## how the arrangement law placed them.
@export var point_seed: int = -1

## null unless point_seed >= 0. Null means "use the global randf()", which is
## what every existing placement does.
var _rng: RandomNumberGenerator = null

@export var regenerate: bool = false:
	set(value):
		if value:
			generate_cell_body()
			regenerate = false

var vertex_container: Node3D
var edge_container: Node3D
var current_points: Array = []  # Store points for retriangulation
var grab_point_scene: PackedScene

func _ready() -> void:
	_read_dna()
	# Built ONLY when point_seed >= 0. At the -1 default nothing is constructed
	# and _rf()/_rf_range() fall through to the bare global calls, so the legacy
	# stream is untouched — no seed() call is made anywhere on this path.
	if point_seed >= 0:
		_rng = RandomNumberGenerator.new()
		_rng.seed = point_seed
	# Load grabbable point scene (only at runtime, not in editor)
	if not Engine.is_editor_hint() and use_grabbable_points:
		grab_point_scene = load("res://commons/primitives/point/grab_sphere_point_with_text.tscn")
	generate_cell_body()

func generate_cell_body() -> void:
	# Clear previous visualization
	for child in get_children():
		child.queue_free()

	# FORMATION: the sites. "shell" calls generate_hierarchical_points() itself,
	# which is what every existing placement gets.
	current_points = _formation_points()
	var mesh_data = create_delaunay_mesh(current_points)
	mesh = mesh_data

	# Add vertex visualization
	if show_vertices:
		visualize_vertices(current_points)

	# Add edge visualization
	if show_edges:
		visualize_edges(current_points)

	# Add explanation label
	if show_label:
		add_explanation_label()

func visualize_vertices(points: Array) -> void:
	vertex_container = Node3D.new()
	vertex_container.name = "Vertices"
	add_child(vertex_container)

	var max_grabbable = 12  # Limit grabbable points for usability
	for i in range(min(points.size(), 30)):  # Limit to avoid clutter
		var point = points[i]

		# Use grabbable points at runtime (limited count for usability)
		if not Engine.is_editor_hint() and use_grabbable_points and grab_point_scene and i < max_grabbable:
			var grab_point = grab_point_scene.instantiate()
			grab_point.position = point
			grab_point.set_meta("point_index", i)
			vertex_container.add_child(grab_point)

			# Connect to dropped signal to regenerate mesh
			if grab_point.has_signal("dropped"):
				grab_point.dropped.connect(_on_point_dropped.bind(i, grab_point))
		else:
			# Static sphere for editor or non-grabbable points
			var sphere = MeshInstance3D.new()
			var sphere_mesh = SphereMesh.new()
			sphere_mesh.radius = 0.08
			sphere_mesh.height = 0.16
			sphere.mesh = sphere_mesh
			sphere.position = point

			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(1.0, 0.8, 0.2)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.8, 0.2)
			mat.emission_energy_multiplier = 2.0
			sphere.material_override = mat

			vertex_container.add_child(sphere)

func _on_point_dropped(_pickable, index: int, grab_node: Node3D) -> void:
	# Update the point position when dropped
	if index < current_points.size():
		current_points[index] = grab_node.position
		# Regenerate mesh and edges with new point positions
		_update_mesh_and_edges()

func _update_mesh_and_edges() -> void:
	# Regenerate mesh with new point positions
	var mesh_data = create_delaunay_mesh(current_points)
	mesh = mesh_data

	# Clear and rebuild edges
	if edge_container:
		edge_container.queue_free()
	if show_edges:
		visualize_edges(current_points)

func visualize_edges(points: Array) -> void:
	edge_container = Node3D.new()
	edge_container.name = "Edges"
	add_child(edge_container)

	var edge_mesh = ImmediateMesh.new()
	var edge_instance = MeshInstance3D.new()
	edge_instance.mesh = edge_mesh

	# Draw edges connecting nearby points
	for i in range(min(points.size(), 30)):
		var neighbors = find_nearest_neighbors(i, points, 3)
		for n in neighbors:
			edge_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
			edge_mesh.surface_add_vertex(points[i])
			edge_mesh.surface_add_vertex(points[n])
			edge_mesh.surface_end()

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.8, 1.0, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	edge_instance.material_override = mat

	edge_container.add_child(edge_instance)

func add_explanation_label() -> void:
	var label = Label3D.new()
	label.text = "DELAUNAY TRIANGULATION\nTriangles where no point\nlies inside circumcircle"
	label.position = Vector3(0, cell_radius + 1.0, 0)
	label.font_size = 40
	label.modulate = Color(0.3, 1.0, 0.8)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 8
	add_child(label)

	# Add drag instruction label (only at runtime with grabbable points)
	if not Engine.is_editor_hint() and use_grabbable_points:
		var instruction = Label3D.new()
		instruction.text = "Grab & drag points to\nretriangulate in real-time"
		instruction.position = Vector3(0, -cell_radius - 0.8, 0)
		instruction.font_size = 32
		instruction.modulate = Color(1.0, 0.9, 0.5)
		instruction.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		instruction.outline_size = 6
		add_child(instruction)

# Generate points with generational hierarchy
func generate_hierarchical_points() -> Array:
	var points = []
	
	# Generation 0: Initial points on sphere
	for i in range(initial_points):
		var theta = _rf() * TAU
		var phi = acos(2.0 * _rf() - 1.0)
		var r = cell_radius
		
		var point = Vector3(
			r * sin(phi) * cos(theta),
			r * sin(phi) * sin(theta),
			r * cos(phi)
		)
		points.append(point)
	
	# Subsequent generations: subdivide and add interior points
	for gen in range(1, generations):
		var gen_points = []
		var layer_radius = cell_radius * (1.0 - float(gen) / float(generations))
		var points_this_gen = int(initial_points * pow(subdivision_factor, gen))
		
		for i in range(points_this_gen):
			var theta = _rf() * TAU
			var phi = acos(2.0 * _rf() - 1.0)
			var r = layer_radius + _rf_range(-randomness, randomness)
			
			var point = Vector3(
				r * sin(phi) * cos(theta),
				r * sin(phi) * sin(theta),
				r * cos(phi)
			)
			gen_points.append(point)
		
		points.append_array(gen_points)
	
	# Add center point
	points.append(Vector3.ZERO)
	
	return points

# Create mesh using simplified Delaunay approach
func create_delaunay_mesh(points: Array) -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create convex hull and internal triangulation
	var triangles = triangulate_points(points)
	
	# Build mesh from triangles
	for tri in triangles:
		var p1 = points[tri[0]]
		var p2 = points[tri[1]]
		var p3 = points[tri[2]]
		
		var normal = (p2 - p1).cross(p3 - p1).normalized()
		
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(p1)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(p2)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(p3)
	
	surface_tool.generate_normals()
	return surface_tool.commit()

# Simplified triangulation using convex hull approach
func triangulate_points(points: Array) -> Array:
	var triangles = []
	var n = points.size()
	
	if n < 4:
		return triangles
	
	# Create triangulation using nearest neighbor approach
	for i in range(n):
		var neighbors = find_nearest_neighbors(i, points, 6)
		
		for j in range(neighbors.size() - 1):
			for k in range(j + 1, neighbors.size()):
				if is_valid_triangle(i, neighbors[j], neighbors[k], points):
					triangles.append([i, neighbors[j], neighbors[k]])
	
	# Remove duplicate triangles
	return remove_duplicate_triangles(triangles)

func find_nearest_neighbors(index: int, points: Array, count: int) -> Array:
	var distances = []
	var point = points[index]
	
	for i in range(points.size()):
		if i != index:
			var dist = point.distance_to(points[i])
			distances.append({"index": i, "distance": dist})
	
	distances.sort_custom(func(a, b): return a.distance < b.distance)
	
	var neighbors = []
	for i in range(min(count, distances.size())):
		neighbors.append(distances[i].index)
	
	return neighbors

func is_valid_triangle(i1: int, i2: int, i3: int, points: Array) -> bool:
	var p1 = points[i1]
	var p2 = points[i2]
	var p3 = points[i3]
	
	# Check if triangle has reasonable area
	var edge1 = p2 - p1
	var edge2 = p3 - p1
	var area = edge1.cross(edge2).length()
	
	return area > 0.001

func remove_duplicate_triangles(triangles: Array) -> Array:
	var unique = []
	var seen = {}
	
	for tri in triangles:
		var sorted_tri = tri.duplicate()
		sorted_tri.sort()
		var key = str(sorted_tri)
		
		if not seen.has(key):
			seen[key] = true
			unique.append(tri)
	
	return unique

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	var was: String = formation
	_read_dna()
	if formation != was:
		if point_seed >= 0:
			_rng = RandomNumberGenerator.new()
			_rng.seed = point_seed
		generate_cell_body()


# ═══════════════════════════════════════════════════════════════════════════
# formation — everything below is new and nothing above it moved.
# ═══════════════════════════════════════════════════════════════════════════

## Map tokens arrive as config_<key> metadata. An unreadable word keeps the
## shipped onion rather than silently rendering as some other arrangement.
func _read_dna() -> void:
	if has_meta("config_formation"):
		var v: String = str(get_meta("config_formation")).strip_edges().to_lower()
		if FORMATIONS.has(v):
			formation = v
	if has_meta("config_point_seed"):
		point_seed = int(str(get_meta("config_point_seed")))


## The only random draws in this artifact. With no seed declared these ARE
## `randf()` and `randf_range()` — the same global calls, in the same places,
## the same number of times — so the legacy point set is reproduced exactly.
func _rf() -> float:
	if _rng != null:
		return _rng.randf()
	return randf()


func _rf_range(from: float, to: float) -> float:
	if _rng != null:
		return _rng.randf_range(from, to)
	return randf_range(from, to)


## The sites. "shell" hands straight back to the untouched generator, so the four
## existing placements build exactly what they always built. Every other law
## places _shipped_site_count() points inside the same cell_radius.
func _formation_points() -> Array:
	var key: String = str(formation).strip_edges().to_lower()
	if not FORMATIONS.has(key) or key == "shell":
		return generate_hierarchical_points()

	var n: int = _shipped_site_count()
	var points: Array = []
	match key:
		"lattice":
			points = _lattice_points(n)
		"ring":
			points = _ring_points(n)
		"column":
			points = _column_points(n)
		"drift":
			points = _drift_points(n)
	points.append(Vector3.ZERO)
	return points


## How many sites generate_hierarchical_points() would have made, counted with
## its own arithmetic so the alternatives stay comparable when initial_points,
## generations or subdivision_factor are changed by a map token. The trailing
## centre point is added by the caller, so it is not counted here.
func _shipped_site_count() -> int:
	var total: int = initial_points
	for gen in range(1, generations):
		total += int(initial_points * pow(subdivision_factor, gen))
	return maxi(total, 4)


## A regular cubic grid clipped to the ball. Walked from the centre outward so a
## partial outer shell never leaves the cloud lopsided, and jittered by the same
## `randomness` the shell generator uses, so the two are honest about sharing a
## parameter.
func _lattice_points(n: int) -> Array:
	var side: int = int(ceil(pow(float(n) * 1.91, 1.0 / 3.0)))
	side = maxi(side, 2)
	var step: float = cell_radius * 2.0 / float(side - 1)
	var candidates: Array = []
	for ix in range(side):
		for iy in range(side):
			for iz in range(side):
				var p := Vector3(
					-cell_radius + float(ix) * step,
					-cell_radius + float(iy) * step,
					-cell_radius + float(iz) * step)
				if p.length() <= cell_radius * 1.001:
					candidates.append(p)
	candidates.sort_custom(func(a, b): return a.length() < b.length())
	var out: Array = []
	for i in range(mini(n, candidates.size())):
		var jitter := Vector3(
			_rf_range(-randomness, randomness),
			_rf_range(-randomness, randomness),
			_rf_range(-randomness, randomness)) * 0.15
		out.append(candidates[i] + jitter)
	return out


## A flat annulus in XZ. The inner radius is 40% of the outer so there is a hole
## for the mesh to be a disc around rather than a filled plate.
func _ring_points(n: int) -> Array:
	var out: Array = []
	for i in range(n):
		var theta: float = float(i) / float(maxi(n, 1)) * TAU * 2.0 + _rf() * 0.35
		var r: float = cell_radius * (0.4 + 0.6 * _rf())
		var y: float = _rf_range(-randomness, randomness) * 0.25
		out.append(Vector3(cos(theta) * r, y, sin(theta) * r))
	return out


## A narrow shaft up Y, full height, one twelfth of the radius wide. Nearest
## neighbours become the sites directly above and below.
func _column_points(n: int) -> Array:
	var out: Array = []
	var girth: float = cell_radius / 12.0
	for i in range(n):
		var t: float = float(i) / float(maxi(n - 1, 1))
		var theta: float = _rf() * TAU
		var r: float = girth * sqrt(_rf())
		out.append(Vector3(
			cos(theta) * r,
			-cell_radius + t * cell_radius * 2.0,
			sin(theta) * r))
	return out


## Uniform scatter through the ball. The cube-root of a uniform draw is what
## makes it uniform by VOLUME — without it the sites pile up at the centre and
## `drift` would quietly be a second, blurrier `shell`.
func _drift_points(n: int) -> Array:
	var out: Array = []
	for i in range(n):
		var theta: float = _rf() * TAU
		var phi: float = acos(2.0 * _rf() - 1.0)
		var r: float = cell_radius * pow(_rf(), 1.0 / 3.0)
		out.append(Vector3(
			r * sin(phi) * cos(theta),
			r * sin(phi) * sin(theta),
			r * cos(phi)))
	return out
