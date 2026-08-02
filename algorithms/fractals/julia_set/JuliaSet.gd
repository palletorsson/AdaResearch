extends Node3D

# Julia Set Visualization - MultiMesh Optimized
# Parameter-space fractal variants of the Mandelbrot set

# @identity
# essence: z_{n+1} = z_n^2 + c, fixed c, vary z_0. Each pixel is a starting point; escape or stay determines membership.
# desire: To morph — c_real and c_imag animate through parameter space, and the Julia set shape-shifts in real-time
# critical_parameter: c_real + c_imag — the complex parameter c determines whether the Julia set is connected (c inside Mandelbrot) or dust (c outside); page — which NAMED point in that parameter space is open (tour | basilica | rabbit | dendrite | spiral | dust)
# triggers: animate_parameters → c traces a Lissajous path; parameter trail shows recent c values as fading spheres
# emerges: The topology change — as c crosses the Mandelbrot boundary, the Julia set shatters from connected to disconnected, visibly
# needs: VR c-parameter control [missing], Mandelbrot overlay [missing]
# relationships: Sibling to julia_set_explorer (GPU shader) and mandelbrot_set; each point in the Mandelbrot indexes a Julia set
# truth: Every Julia set is a cross-section of the Mandelbrot set — the Mandelbrot is the catalog, each Julia set a page.

# Julia set parameters
@export var c_real := -0.7
@export var c_imag := 0.27015
@export var max_iterations := 50
@export var escape_radius := 2.0
@export var zoom_level := 1.0
@export var grid_resolution := 50
@export var animate_parameters := true
@export var point_size := 0.08

# ─────────────────────────────────────────────────────────────────────────────
# DNA PROMOTION (2026-08-02).
#
# There is no other artifact in this corpus whose family is this literal. A Julia
# set is not A shape — it is one entry in a catalogue indexed by a single complex
# number, and this file's own truth line already says so: "the Mandelbrot is the
# catalog, each Julia set a page." Vary c and you do not get a variation on a
# picture, you get a DIFFERENT TOPOLOGICAL OBJECT: a connected body, a body with
# no interior at all, or a dust of infinitely many disconnected points. Same
# eleven lines of arithmetic in _julia_iterations for every one of them.
#
#   page   which entry in the catalogue is open
#
#     tour | basilica | rabbit | dendrite | spiral | dust
#
#   tour      c never settles. The legacy lineage exactly: animate_parameters
#             drives c along a Lissajous path and zoom breathes with it, so the
#             object on the plinth is the catalogue being riffled rather than any
#             page of it. This is what every room that has ever placed this
#             artifact shows, and it stays the default.
#   basilica  c = -1 + 0i. Period 2. A connected chain of round bays down the
#             real axis, the shape that got named after San Marco reflected in
#             flooded pavement — a solid black core with fat lobes.
#   rabbit    c = -0.123 + 0.745i. Douady's rabbit, period 3. A connected body
#             that visibly grows THREE ears at every scale — the clearest picture
#             in the catalogue of a fractal repeating its own body plan.
#   dendrite  c = 0 + 1i. A Misiurewicz point: still connected, but with ZERO
#             interior. It has no black core at all because there is no inside —
#             about half as many points survive as any other page and they form a
#             bare branching filament. A shape made entirely of edge.
#   spiral    c = -0.8 + 0.156i. Just inside the Mandelbrot boundary, where the
#             arms wind. Connected, but the interior is shredded into spiral arms
#             instead of held in lobes.
#   dust      c = 0.4 + 0.4i. OUTSIDE the Mandelbrot set, and this is the
#             topology change the identity block promises: the set shatters. Not
#             one point survives to the iteration cap, so the tile has no black
#             in it whatsoever — every surviving point is escape-coloured, and
#             they are scattered specks with nothing joining them. Fatou dust.
#
# THE CURRICULUM DOES NOT MOVE. z -> z^2 + c, the escape radius, the iteration
# cap, the colouring and the grid are all untouched. The axis picks the constant
# and nothing else — which is the entire point, because picking the constant IS
# the mathematics here.
#
# WHY NAMED POINTS AND NOT A SLIDER. c is continuous, and a continuous knob
# cannot be a DNA axis: an axis is a small set of named values. These five are
# the points in parameter space that classical dynamics already named, so each
# tile is a thing with a name rather than a sample of a fog.
#
# STRICTLY ADDITIVE. No RNG in this file — nothing to shift. `tour` is the only
# value _apply_page does not recognise, and it returns before touching c_real,
# c_imag or animate_parameters, so the default artifact is byte-identical.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS — which page of the catalogue is open. `tour` is the legacy lineage.
@export_enum("tour", "basilica", "rabbit", "dendrite", "spiral", "dust") var page: String = "tour"

## The named points, keyed by page. Vector2(c_real, c_imag). `tour` is absent on
## purpose: it is not a point, it is a refusal to settle on one.
const PAGE_C := {
	"basilica": Vector2(-1.0, 0.0),
	"rabbit": Vector2(-0.123, 0.745),
	"dendrite": Vector2(0.0, 1.0),
	"spiral": Vector2(-0.8, 0.156),
	"dust": Vector2(0.4, 0.4),
}

## The allow-list a map token is checked against — the same six words the
## @export_enum declares, same spelling, same order.
const PAGES: PackedStringArray = ["tour", "basilica", "rabbit", "dendrite", "spiral", "dust"]

var time := 0.0

# MultiMesh instances for GPU instancing
var julia_multimesh_instance: MultiMeshInstance3D
var julia_multimesh: MultiMesh
var param_multimesh_instance: MultiMeshInstance3D
var _extent_anchor: MeshInstance3D
var param_multimesh: MultiMesh

# Shared mesh for instances
var cube_mesh: BoxMesh
var sphere_mesh: SphereMesh

# Materials
var set_material: StandardMaterial3D
var escape_material: StandardMaterial3D
var param_material: StandardMaterial3D

# Cache for iteration data
var iteration_cache: PackedInt32Array
var needs_regeneration := true
var last_c_real := 0.0
var last_c_imag := 0.0
var last_zoom := 0.0

func _ready() -> void:
	_read_dna_meta()
	_apply_page()
	_setup_meshes()
	_setup_materials()
	_setup_multimesh_instances()
	_generate_julia_set()

func _setup_meshes() -> void:
	# Small cube for Julia set points
	cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(point_size, point_size, point_size)

	# Sphere for parameter space
	sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.15
	sphere_mesh.height = 0.3

func _setup_materials() -> void:
	# Material for points in the set (black)
	set_material = StandardMaterial3D.new()
	set_material.albedo_color = Color(0.0, 0.0, 0.0)

	# Material for escaped points (will use instance colors)
	escape_material = StandardMaterial3D.new()
	escape_material.vertex_color_use_as_albedo = true
	escape_material.emission_enabled = true
	escape_material.emission_energy_multiplier = 0.3

	# Material for parameter indicator
	param_material = StandardMaterial3D.new()
	param_material.albedo_color = Color(1.0, 0.0, 0.0)
	param_material.emission_enabled = true
	param_material.emission = Color(1.0, 0.0, 0.0)
	param_material.emission_energy_multiplier = 0.8

func _setup_multimesh_instances() -> void:
	# Julia set visualization
	julia_multimesh = MultiMesh.new()
	julia_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	julia_multimesh.use_colors = true
	julia_multimesh.mesh = cube_mesh

	julia_multimesh_instance = MultiMeshInstance3D.new()
	julia_multimesh_instance.name = "JuliaMultiMesh"
	julia_multimesh_instance.multimesh = julia_multimesh
	julia_multimesh_instance.material_override = escape_material

	if has_node("JuliaVisualization"):
		$JuliaVisualization.add_child(julia_multimesh_instance)
	else:
		add_child(julia_multimesh_instance)

	# Parameter space visualization
	param_multimesh = MultiMesh.new()
	param_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	param_multimesh.use_colors = true
	param_multimesh.mesh = sphere_mesh

	_add_extent_anchor()
	param_multimesh_instance = MultiMeshInstance3D.new()
	param_multimesh_instance.name = "ParameterMultiMesh"
	param_multimesh_instance.multimesh = param_multimesh

	if has_node("ParameterSpace"):
		$ParameterSpace.add_child(param_multimesh_instance)
	else:
		add_child(param_multimesh_instance)

func _process(delta: float) -> void:
	time += delta

	if animate_parameters:
		# Animate Julia set parameter
		c_real = -0.7 + sin(time * 0.3) * 0.3
		c_imag = 0.27015 + cos(time * 0.5) * 0.2
		zoom_level = 1.0 + sin(time * 0.2) * 0.5

	# Only regenerate if parameters changed significantly
	if _parameters_changed():
		_generate_julia_set()
		last_c_real = c_real
		last_c_imag = c_imag
		last_zoom = zoom_level

	_update_parameter_space()

func _parameters_changed() -> bool:
	return abs(c_real - last_c_real) > 0.001 or \
		   abs(c_imag - last_c_imag) > 0.001 or \
		   abs(zoom_level - last_zoom) > 0.01

func _generate_julia_set() -> void:
	var bounds = 3.0 / zoom_level
	var point_data: Array[Dictionary] = []

	# Calculate all points
	for i in range(grid_resolution):
		for j in range(grid_resolution):
			var x = (float(i) / grid_resolution - 0.5) * 2 * bounds
			var y = (float(j) / grid_resolution - 0.5) * 2 * bounds

			var iterations = _julia_iterations(x, y, c_real, c_imag)
			var is_in_set = iterations >= max_iterations

			if is_in_set or iterations > 5:
				var color: Color
				if is_in_set:
					color = Color(0.0, 0.0, 0.0)
				else:
					var color_ratio = float(iterations) / max_iterations
					color = Color.from_hsv(color_ratio * 0.8, 0.8, 1.0)

				point_data.append({
					"position": Vector3(x * 2, 0, y * 2),
					"color": color
				})

	# Update MultiMesh
	var instance_count = point_data.size()
	julia_multimesh.instance_count = instance_count

	for idx in range(instance_count):
		var data = point_data[idx]
		var transform = Transform3D(Basis(), data.position)
		julia_multimesh.set_instance_transform(idx, transform)
		julia_multimesh.set_instance_color(idx, data.color)

func _julia_iterations(x: float, y: float, c_r: float, c_i: float) -> int:
	var z_real = x
	var z_imag = y
	var iteration = 0
	var escape_sq = escape_radius * escape_radius

	while iteration < max_iterations:
		var z_real_sq = z_real * z_real
		var z_imag_sq = z_imag * z_imag

		if z_real_sq + z_imag_sq > escape_sq:
			break

		var new_real = z_real_sq - z_imag_sq + c_r
		var new_imag = 2 * z_real * z_imag + c_i

		z_real = new_real
		z_imag = new_imag
		iteration += 1

	return iteration

func _update_parameter_space() -> void:
	# Current parameter point + trajectory
	var trajectory_points = 20
	param_multimesh.instance_count = trajectory_points + 1

	# Current position (larger sphere)
	var main_transform = Transform3D(Basis().scaled(Vector3(1.5, 1.5, 1.5)), Vector3(c_real * 3, 0, c_imag * 3))
	param_multimesh.set_instance_transform(0, main_transform)
	param_multimesh.set_instance_color(0, Color(1.0, 0.0, 0.0))

	# Trail points
	for i in range(trajectory_points):
		var t = time - float(i) * 0.1
		var trail_c_real = -0.7 + sin(t * 0.3) * 0.3
		var trail_c_imag = 0.27015 + cos(t * 0.5) * 0.2

		var scale_factor = 0.3 * (1.0 - float(i) / trajectory_points)
		var trail_transform = Transform3D(
			Basis().scaled(Vector3(scale_factor, scale_factor, scale_factor)),
			Vector3(trail_c_real * 3, 0, trail_c_imag * 3)
		)
		param_multimesh.set_instance_transform(i + 1, trail_transform)

		var alpha = 1.0 - float(i) / trajectory_points
		param_multimesh.set_instance_color(i + 1, Color(1.0, 0.5, 0.0, alpha))

# Public API for external control
func set_julia_parameters(real: float, imag: float) -> void:
	c_real = real
	c_imag = imag
	animate_parameters = false

func set_zoom(new_zoom: float) -> void:
	zoom_level = new_zoom

func set_resolution(new_resolution: int) -> void:
	grid_resolution = new_resolution
	_generate_julia_set()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass


# ── DNA: THE PAGE ────────────────────────────────────────────────────────────

## Read a map token / grid config value if the placer left one. An unknown word
## keeps the default rather than silently opening a page nobody asked for.
func _read_dna_meta() -> void:
	if has_meta("config_page"):
		var raw: String = str(get_meta("config_page")).strip_edges().to_lower()
		if PAGES.has(raw):
			page = raw
		else:
			push_warning("JuliaSet: unknown page '%s' — keeping '%s'" % [raw, page])


## Open one page: pin c to its named point and stop the tour. `tour` is not in
## the table and returns untouched, so the legacy artifact keeps moving.
func _apply_page() -> void:
	if not PAGE_C.has(page):
		return
	var c: Vector2 = PAGE_C[page]
	c_real = c.x
	c_imag = c.y
	animate_parameters = false


## An invisible MeshInstance3D sized to the point field, purely so the capture rig can see
## how big this artifact is.
##
## capture_config_sweep._subtree_aabb() counts MeshInstance3D ONLY. This artifact builds
## nothing but MultiMeshInstance3D, so the walk found no meshes at all and fell back to its
## default AABB(Vector3(-0.5, 0, -0.5), Vector3.ONE) — a 1 m box. The camera then framed
## 3.3 m of a field that spans +/-6 m in x and z, so every swept tile was a crop taken from
## inside the fractal rather than a picture of it, and no dna.framing could fix that because
## the extent moves with zoom_level.
##
## layers = 0 keeps it out of every camera while leaving it in the AABB walk, which is the
## same trick branching_growth_algorithm uses for its field shell. It is not drawn, it is
## not lit, it casts nothing, and it changes no pixel a player ever sees.
func _add_extent_anchor() -> void:
	if is_instance_valid(_extent_anchor):
		return
	# The field spans +/-bounds in x and z, and JuliaSet.gd:234 places points at position
	# (x*2, 0, y*2), so the WORLD extent is bounds*2 either side — a span of bounds*4. My
	# first attempt used bounds*2*2*2 and made the box twice too big, which drove the
	# subject down to 0.22% of frame: an anchor that overshoots is the same fault as no
	# anchor at all, just in the other direction.
	var span: float = (3.0 / maxf(zoom_level, 0.001)) * 4.0
	var box := BoxMesh.new()
	box.size = Vector3(span, 0.05, span)
	var mi := MeshInstance3D.new()
	mi.name = "ExtentAnchor"
	mi.mesh = box
	mi.layers = 0
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	_extent_anchor = mi
