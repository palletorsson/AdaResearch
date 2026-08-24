# RandomProfile.gd
# Creates a random height profile using pure randomness
# Profile is 1 meter wide with n points, starts and ends at 0.5
#
# @identity
# essence: h[i] = 1.0 + rng.randf_range(-v, v) * taper(i), with h[0] and h[n-1] forced
#   to 1.0 — white noise admitted only in the interior, the frame held by hand
# desire: to see the difference between a random number and a random SHAPE, and to
#   notice that the difference is entirely in what was refused
# critical_parameter: readout — what the five draws are claimed to be (relief | plate |
#   column); profile_seed pins which five numbers were drawn
# triggers: nothing — it draws once at _ready and stands there. There is no animation,
#   no timer and no interaction; this is the tier's one still object
# emerges: at readout:column the clamp becomes visible for the first time — the two
#   outer bars are exactly equal and only the interior three disagree, which is the
#   artifact's whole thesis and was previously buried inside a silhouette
# needs: nothing beyond the RandomPlane node it draws into [has]
# relationships: the discrete, five-sample sibling of [[perlin_noise_terrain]]; where
#   that samples a COHERENT field, this draws five independent numbers and the contrast
#   between the two silhouettes is what "coherent" means
# truth: a bounded random walk is a negotiation. The interior is free because somebody
#   decided in advance where the ends would be.

extends Node3D

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-02).
#
# Three exports — point_count, profile_width, max_height_variation — and all
# three are quantities. How many draws, how wide, how far. None of them can ask
# what the draws ARE, and this artifact has been answering that question
# silently since it was written by welding the five samples into one continuous
# extruded solid. A solid with a wobbly top edge is a LANDSCAPE, and five
# unrelated numbers are not a landscape; they are five numbers.
#
#   readout   WHAT THE FIVE DRAWS ARE CLAIMED TO BE
#
#     relief   a continuous surface. The samples are welded rib to rib into one
#              extruded solid with a wobbly top edge — a terrain profile, a
#              section through a hill. THE LEGACY LINEAGE, byte for byte.
#     plate    an image. The top edge stops wobbling: a plain rectangle, banded
#              into one field per segment, each band carrying its value as
#              COLOUR. The silhouette that made it a hill is gone and the same
#              five numbers are still all there.
#     column   measurements. One bar per sample, standing apart from its
#              neighbours, which is what five independent draws actually are.
#              This is also the only value at which the artifact's own argument
#              is visible: the outer two bars are EXACTLY equal, because they
#              were never drawn — they were clamped — and the interior three are
#              the only place chance was admitted.
#
# ONE WORD, THREE ARTIFACTS. `readout`, and these three values in this order
# with this default, is taken verbatim from perlin_noise and simplex_noise
# (2026-07-29) and is shared with perlin_noise_terrain. Four artifacts in the
# randomness tier now answer "what is this field" in one vocabulary, so the
# coherent-noise members and this white-noise one can be put side by side.
#
# WHAT IS DELIBERATELY NOT THE AXIS. The clamp itself — free ends, floor ends,
# pinned ends — is the truer subject and it was the first candidate. It fails
# R3: with five points, a base of 1.0 and a variation of ±0.3 tapered near the
# edges, every clamp regime produces the same gently-wobbling 1 m slab, and the
# whole difference lives in a few centimetres of one edge. `column` gets the
# same argument across by making the clamp legible instead of by varying it.
#
# NOT TOUCHED: the draws. Every readout uses the SAME profile_points, produced
# by the same randf_range calls in the same order from the same seed. Only what
# is built on top of them changes.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS — what the five draws are claimed to be. `relief` is the legacy default.
@export_enum("relief", "plate", "column") var readout: String = "relief"

## The allow-list, same spelling and same order as the @export_enum above. An
## unreadable word keeps the legacy default rather than blanking a profile five rooms
## expect to see.
const READOUTS: PackedStringArray = ["relief", "plate", "column"]

@export var point_count: int = 5
@export var profile_width: float = 1.0
@export var max_height_variation: float = 0.3

## SEED. This artifact called rng.randomize() and then drew every interior height from
## the result, so no two boots and no two captures were ever of the same profile. -1
## keeps that behaviour EXACTLY — the same single randomize() call in the same place.
## Any value >= 0 pins the draws instead. A sweep of `readout` MUST pin it, or three
## readouts of three different profiles get reported as a bite that is entirely noise.
@export var profile_seed: int = -1

var rng = RandomNumberGenerator.new()
var profile_points: Array[Vector3] = []
var profile_mesh: MeshInstance3D

## The red wireframe Grid-shader material the scene ships with. relief and column both
## keep it — column's argument is carried by the gaps between the bars, and it should
## look like the same object taken apart. Only `plate` has to swap it, because a plate
## whose whole claim is "the value survives as colour" cannot be drawn in a material
## that has no colour input.
var _shipped_material: Material = null
## True once _ready has built once.
var _built: bool = false

func _ready() -> void:
	# The grid sets config_* metadata SYNCHRONOUSLY before add_child and calls
	# apply_grid_config call_deferred, i.e. after this — so the meta read has to happen
	# here, before the seed is set and before a single number is drawn.
	_read_meta_overrides()
	# Initialize random generator
	# profile_seed < 0 is the shipped behaviour: the same one randomize() call, in the
	# same place, with no draw inserted ahead of it.
	if profile_seed < 0:
		rng.randomize()
	else:
		rng.seed = profile_seed

	# Get reference to the existing RandomPlane from the scene
	profile_mesh = $RandomPlane
	if not profile_mesh:
		print("ERROR: RandomPlane node not found in scene!")
		return
	_shipped_material = profile_mesh.material_override

	# Generate the random profile
	generate_random_profile()
	_built = true

	print("SimpleRandomProfile: Created profile with %d points using RandomPlane" % point_count)

func generate_random_profile() -> void:
	"""Generate a random height profile using pure randomness"""
	profile_points.clear()
	
	# Calculate spacing between points
	var spacing = profile_width / float(point_count - 1)
	
	# Generate points along the profile
	for i in range(point_count):
		var x_position = i * spacing - (profile_width / 2.0)  # Center the profile
		var height = _calculate_random_height_at_index(i)
		
		# Create point
		var point = Vector3(x_position, height, 0)
		profile_points.append(point)
		
		print("Point %d: x=%.3f, height=%.3f" % [i, x_position, height])

	# Create visual representation using the RandomPlane.
	# READOUT dispatch, appended at the end of the generator and nowhere else: the
	# default falls straight through to _create_profile_mesh(), which is untouched.
	match readout:
		"plate":
			_create_plate_mesh()
		"column":
			_create_column_mesh()
		_:
			if profile_mesh.material_override != _shipped_material:
				profile_mesh.material_override = _shipped_material
			_create_profile_mesh()      # relief — the legacy lineage, byte for byte

func _calculate_random_height_at_index(index: int) -> float:
	"""Calculate random height ensuring start and end are at 1.0"""
	var base_height = 1.0
	
	# Force first and last points to 1.0
	if index == 0 or index == point_count - 1:
		return base_height
	
	# For middle points, add random variation
	var random_variation = rng.randf_range(-max_height_variation, max_height_variation)
	
	# Optional: reduce variation near edges for smoother transition
	var edge_factor = 1.0
	var normalized_position = float(index) / float(point_count - 1)
	
	if normalized_position < 0.3:  # Near start
		edge_factor = normalized_position / 0.3
	elif normalized_position > 0.7:  # Near end
		edge_factor = (1.0 - normalized_position) / 0.3
	
	return base_height + (random_variation * edge_factor)

func _create_profile_mesh() -> void:
	"""Create a visual mesh representation of the profile using vertices"""
	if profile_points.size() < 2:
		return
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create a plane that follows the profile shape
	var depth = 0.1  # Small depth for the profile plane
	var subdivisions = profile_points.size() - 1
	
	# Generate vertices for the profile surface
	for i in range(profile_points.size() - 1):
		var p1 = profile_points[i]
		var p2 = profile_points[i + 1]
		
		# Create two triangles for each segment
		# Bottom edge (y=0)
		var bottom_p1 = Vector3(p1.x, 0, -depth/2)
		var bottom_p2 = Vector3(p2.x, 0, -depth/2)
		var bottom_p1_back = Vector3(p1.x, 0, depth/2)
		var bottom_p2_back = Vector3(p2.x, 0, depth/2)
		
		# Top edge (following profile)
		var top_p1 = Vector3(p1.x, p1.y, -depth/2)
		var top_p2 = Vector3(p2.x, p2.y, -depth/2)
		var top_p1_back = Vector3(p1.x, p1.y, depth/2)
		var top_p2_back = Vector3(p2.x, p2.y, depth/2)
		
		# Front face triangles
		surface_tool.set_normal(Vector3(0, 0, 1))
		_add_quad(surface_tool, bottom_p1, bottom_p2, top_p2, top_p1)
		
		# Back face triangles
		surface_tool.set_normal(Vector3(0, 0, -1))
		_add_quad(surface_tool, bottom_p1_back, top_p1_back, top_p2_back, bottom_p2_back)
		
		# Top face (if there's height)
		if p1.y > 0.01 or p2.y > 0.01:
			surface_tool.set_normal(Vector3(0, 1, 0))
			_add_quad(surface_tool, top_p1, top_p2, top_p2_back, top_p1_back)
		
		# Bottom face
		surface_tool.set_normal(Vector3(0, -1, 0))
		_add_quad(surface_tool, bottom_p1, bottom_p1_back, bottom_p2_back, bottom_p2)
	
	# Add side caps (left and right ends)
	if profile_points.size() >= 2:
		var first_point = profile_points[0]
		var last_point = profile_points[-1]
		
		# Left side cap (first point)
		surface_tool.set_normal(Vector3(-1, 0, 0))
		var left_bottom_front = Vector3(first_point.x, 0, -depth/2)
		var left_bottom_back = Vector3(first_point.x, 0, depth/2)
		var left_top_front = Vector3(first_point.x, first_point.y, -depth/2)
		var left_top_back = Vector3(first_point.x, first_point.y, depth/2)
		_add_quad(surface_tool, left_bottom_front, left_top_front, left_top_back, left_bottom_back)
		
		# Right side cap (last point)
		surface_tool.set_normal(Vector3(1, 0, 0))
		var right_bottom_front = Vector3(last_point.x, 0, -depth/2)
		var right_bottom_back = Vector3(last_point.x, 0, depth/2)
		var right_top_front = Vector3(last_point.x, last_point.y, -depth/2)
		var right_top_back = Vector3(last_point.x, last_point.y, depth/2)
		_add_quad(surface_tool, right_bottom_front, right_bottom_back, right_top_back, right_top_front)
	
	# Create and assign the mesh
	var mesh = surface_tool.commit()
	profile_mesh.mesh = mesh
	
	print("Profile mesh created with %d points" % profile_points.size())

func _add_quad(surface_tool: SurfaceTool, p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3) -> void:
	"""Helper function to add a quad as two triangles"""
	# Calculate UVs based on position
	surface_tool.set_uv(Vector2(0, 0))
	surface_tool.add_vertex(p1)
	
	surface_tool.set_uv(Vector2(1, 0))
	surface_tool.add_vertex(p2)
	
	surface_tool.set_uv(Vector2(1, 1))
	surface_tool.add_vertex(p3)
	
	# Second triangle
	surface_tool.set_uv(Vector2(0, 0))
	surface_tool.add_vertex(p1)
	
	surface_tool.set_uv(Vector2(1, 1))
	surface_tool.add_vertex(p3)
	
	surface_tool.set_uv(Vector2(0, 1))
	surface_tool.add_vertex(p4)

func regenerate_profile() -> void:
	"""Generate a new random profile"""
	generate_random_profile()

func set_point_count(new_count: int) -> void:
	"""Change the number of points in the profile"""
	point_count = max(3, new_count)  # Minimum 3 points
	generate_random_profile()

func set_height_variation(variation: float) -> void:
	"""Change the maximum height variation"""
	max_height_variation = max(0.0, variation)
	generate_random_profile()

func get_height_at_distance(distance: float) -> float:
	"""Get interpolated height at any distance along the profile"""
	if profile_points.size() < 2:
		return 1.0
	
	# Clamp distance to profile bounds
	distance = clamp(distance, 0.0, profile_width)
	
	# Find the two points to interpolate between
	for i in range(profile_points.size() - 1):
		var p1 = profile_points[i]
		var p2 = profile_points[i + 1]
		
		if distance >= p1.x and distance <= p2.x:
			# Linear interpolation between p1 and p2
			var t = (distance - p1.x) / (p2.x - p1.x)
			return lerp(p1.y, p2.y, t)
	
	# Fallback
	return 1.0

func get_random_heights_array() -> Array[float]:
	"""Return just the height values as an array"""
	var heights: Array[float] = []
	for point in profile_points:
		heights.append(point.y)
	return heights

func get_profile_as_string() -> String:
	"""Return profile as formatted string"""
	var result = "Random Profile: "
	for i in range(profile_points.size()):
		var point = profile_points[i]
		result += "%.2f" % point.y
		if i < profile_points.size() - 1:
			result += ", "
	return result

# ═════════════════════════════════════════════════════════════════════════════
# READOUT — the two non-legacy ways the same five draws can be written down.
# Both build into the same $RandomPlane node, over the same x range and the same
# 0.1 m depth _create_profile_mesh uses, so the three readouts occupy one seat and a
# sweep frames them identically.
# ═════════════════════════════════════════════════════════════════════════════

const PROFILE_DEPTH := 0.1          # matches _create_profile_mesh's `depth`
const CLAMP_HEIGHT := 1.0           # _calculate_random_height_at_index's base_height


## The heights alone, in draw order.
func _heights() -> Array:
	var out: Array = []
	for p in profile_points:
		out.append(p.y)
	return out


## The family's height ramp — blue at the low end, amber at the high. The same two
## colours perlin_noise's cube field lerps between, so a band here and a cube there are
## reading the number in the same language.
func _ramp(t: float) -> Color:
	return Color(0.2, 0.4, 0.8).lerp(Color(0.8, 0.6, 0.2), clampf(t, 0.0, 1.0))


func _span(values: Array) -> Vector2:
	var lo: float = 1e20
	var hi: float = -1e20
	for v in values:
		var f: float = float(v)
		lo = minf(lo, f)
		hi = maxf(hi, f)
	if hi - lo < 0.0001:
		hi = lo + 0.0001
	return Vector2(lo, hi)


## PLATE — the wobble removed, the numbers kept. A plain rectangle exactly as wide as
## the profile and exactly as tall as the clamp the ends were pinned to, banded into one
## field per segment with each band carrying its own value as colour. The silhouette
## that made five numbers into a hill is gone; the five numbers are all still here.
func _create_plate_mesh() -> void:
	if profile_points.size() < 2:
		return
	var heights: Array = _heights()
	var band_span: Vector2 = _span(heights)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(profile_points.size() - 1):
		var p1: Vector3 = profile_points[i]
		var p2: Vector3 = profile_points[i + 1]
		var mid: float = (float(heights[i]) + float(heights[i + 1])) * 0.5
		var t: float = (mid - band_span.x) / (band_span.y - band_span.x)
		var cx: float = (p1.x + p2.x) * 0.5
		var w: float = absf(p2.x - p1.x)
		_add_box(st, Vector3(cx, CLAMP_HEIGHT * 0.5, 0.0),
			Vector3(w, CLAMP_HEIGHT, PROFILE_DEPTH), _ramp(t))
	profile_mesh.mesh = st.commit()
	profile_mesh.material_override = _vertex_colour_material()


## COLUMN — one bar per sample, standing apart. Five independent draws drawn as five
## independent things, which is what they are.
##
## This is the value at which the artifact finally shows its own thesis: bars 0 and 4
## are EXACTLY the same height, because those two were never drawn — the generator
## returns base_height for them and returns early — and only bars 1, 2 and 3 disagree.
## Chance was admitted in the interior and refused at the frame, and in the welded
## relief silhouette you could not see where the refusal was.
##
## The shipped wireframe material is kept: this should read as the same object taken
## apart, not as a different object.
func _create_column_mesh() -> void:
	if profile_points.size() < 2:
		return
	if profile_mesh.material_override != _shipped_material:
		profile_mesh.material_override = _shipped_material
	var spacing: float = profile_width / float(maxi(point_count - 1, 1))
	var w: float = spacing * 0.55
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in profile_points:
		var h: float = maxf(float(p.y), 0.01)
		_add_box(st, Vector3(p.x, h * 0.5, 0.0),
			Vector3(w, h, PROFILE_DEPTH), Color(1, 1, 1))
	profile_mesh.mesh = st.commit()


## One axis-aligned box into an open SurfaceTool, six faces through the file's own
## _add_quad so the winding matches the legacy mesh exactly. The colour is written on
## every vertex; the wireframe material ignores it, the plate material reads it.
func _add_box(st: SurfaceTool, centre: Vector3, size: Vector3, c: Color) -> void:
	var h: Vector3 = size * 0.5
	var x0: float = centre.x - h.x
	var x1: float = centre.x + h.x
	var y0: float = centre.y - h.y
	var y1: float = centre.y + h.y
	var z0: float = centre.z - h.z
	var z1: float = centre.z + h.z
	st.set_color(c)
	st.set_normal(Vector3(0, 0, 1))
	_add_quad(st, Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x0, y1, z1))
	st.set_normal(Vector3(0, 0, -1))
	_add_quad(st, Vector3(x1, y0, z0), Vector3(x0, y0, z0), Vector3(x0, y1, z0), Vector3(x1, y1, z0))
	st.set_normal(Vector3(0, 1, 0))
	_add_quad(st, Vector3(x0, y1, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0), Vector3(x0, y1, z0))
	st.set_normal(Vector3(0, -1, 0))
	_add_quad(st, Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x0, y0, z1))
	st.set_normal(Vector3(-1, 0, 0))
	_add_quad(st, Vector3(x0, y0, z0), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x0, y1, z0))
	st.set_normal(Vector3(1, 0, 0))
	_add_quad(st, Vector3(x1, y0, z1), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1))


## A material that can actually show a value. cull_mode stays DISABLED to match the
## shipped Grid shader, which draws both sides.
func _vertex_colour_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color(1, 1, 1)
	m.roughness = 0.8
	m.metallic = 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


# ═════════════════════════════════════════════════════════════════════════════
# DNA plumbing
# ═════════════════════════════════════════════════════════════════════════════

func _read_meta_overrides() -> void:
	if has_meta("config_readout"):
		var v: String = str(get_meta("config_readout")).strip_edges().to_lower()
		if READOUTS.has(v):
			readout = v
		elif v != "":
			push_warning("random_edge_profile: unknown readout '%s' — keeping '%s'"
				% [v, readout])
	if has_meta("config_profile_seed"):
		profile_seed = int(str(get_meta("config_profile_seed")))
	if has_meta("config_point_count"):
		point_count = maxi(3, int(str(get_meta("config_point_count"))))
	if has_meta("config_max_height_variation"):
		max_height_variation = float(str(get_meta("config_max_height_variation")))


## LATENT BUG PAID (2026-08-02): this was `pass`. Every `#token: value` a map put on a
## random_edge_profile placement was parsed, logged by GridInteractablesComponent and
## stashed as metadata, then silently dropped, because nothing here ever read it back.
##
## Guarded like prng_crank_machine's: an unchanged readout touches nothing and says
## nothing, so curation_station's blanket apply_grid_config({"emissive": false}) cannot
## trigger a rebuild. And the rebuild deliberately does NOT redraw — it re-expresses the
## profile_points already on the table, because a late readout change must not deal a
## different set of numbers under a placement that pinned its seed.
func apply_grid_config(config: Dictionary) -> void:
	# _ready assigns `profile_mesh = $RandomPlane`, and config can arrive before
	# _ready — the museum stamps it on a root still outside the tree. The CHILD
	# exists from instantiate(); only the assignment waits. Resolve it here, once,
	# so every path below (including _create_column_mesh, which dereferences it
	# too) is safe rather than just the line that happened to crash.
	if profile_mesh == null:
		profile_mesh = get_node_or_null("RandomPlane") as MeshInstance3D
	if profile_mesh == null:
		push_warning("ProfileRandom: no RandomPlane child — config ignored")
		return
	var before: String = readout
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()
	if not _built:
		return                      # nothing built yet; _ready will use these values
	if readout == before:
		return
	match readout:
		"plate":
			_create_plate_mesh()
		"column":
			_create_column_mesh()
		_:
			if profile_mesh.material_override != _shipped_material:
				profile_mesh.material_override = _shipped_material
			_create_profile_mesh()
	print("[RandomEdgeProfile] Config applied — readout=%s" % [readout])
