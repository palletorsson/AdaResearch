# @identity
# essence: gaussian sampling as paint — dots fall in a normal distribution around a safe zone
# desire: see how often a sample lands far from center vs near center, mediated by stddev
# critical_parameter: refusal — what the plate does with the draws the safe zone throws away (void | rim | echo | ghost | none); stddev sets the spread those draws are taken from
# triggers: timer ticks every splatter_update_interval; each tick samples (x,y) from gaussian and stamps a translucent dot
# emerges: a painting that IS the gaussian PDF — densest at center, sparser at the tails, with edge detection tracing the boundary
# needs: stddev slider [missing]; safe zone radius dial [missing]; clear-canvas button [missing]
# relationships: kin to GaussianBlurCircle, which asks the same question one step later — that one carries `sitter` (what is put UNDER the kernel), this one carries `refusal` (which of the SAMPLES ever reach the plate); contrast to BlueNoise (rejection-based) and probability_distributions_3d (3D variant)
# truth: A bell curve drawn in the air, made visible by the dots that miss. Density is the proof of distribution — and the hole in the middle is a decision, not a fact.

extends MeshInstance3D
class_name GaussianPaintSplatter

# Export variables for customization
@export var splatter_width: int = 640
@export var splatter_height: int = 640
@export var stddev: float = 80.0  # Standard deviation for splatter distribution
@export var splatter_update_interval: float = 0.05  # Timer interval for updating splatter
@export var safe_zone_radius: float = 80.0  # Radius of the safe zone where no splatter will occur
@export var dot_radius: int = 5  # Radius of splatter dots
@export var dot_alpha: float = 0.6  # Alpha (transparency) value for the dots
@export var edge_toggle: bool = true  # Toggle for showing/hiding the edge outline
@export var edge_detection_frequency: int = 50  # Detect edges every N splatter updates
@export var show_visual_frame: bool = true
@export var frame_margin: float = 0.2
@export var frame_border_thickness: float = 0.08
@export var frame_depth: float = 0.03
@export var frame_back_offset: float = 0.02
@export var frame_back_color: Color = Color(0.08, 0.1, 0.14, 0.9)
@export var frame_border_color: Color = Color(0.72, 0.78, 0.9, 1.0)
@export var color_palette: Array[Color] = [
	Color(1.0, 0.4, 0.4, 0.6),  # Red
	Color(0.4, 1.0, 0.4, 0.6),  # Green
	Color(0.4, 0.4, 1.0, 0.6),  # Blue
	Color(1.0, 1.0, 0.4, 0.6),  # Yellow
	Color(1.0, 0.4, 1.0, 0.6),  # Magenta
]

# ─────────────────────────────────────────────────────────────────────────────
# DNA PROMOTION (2026-08-02) — refusal
#
# This plate is a REJECTION SAMPLER and has been one since the day it was
# written, without ever saying so. Look at what _add_gaussian_splatter actually
# does: it draws a sample, measures it, and if the sample landed inside
# safe_zone_radius it RETURNS — the draw was made, paid for, and thrown away.
# The picture on the plate is therefore not the gaussian. It is the gaussian
# minus its own densest region, and the part you cannot see is precisely the
# part the distribution most wanted to put there.
#
# That is the axis. Not how big the hole is — a radius is a magnitude, and
# "how much" is not an argument. What a sampler DOES with the draws it refuses
# is an argument, and it is one every rejection method in the curriculum has to
# answer and almost none of them answer out loud:
#
#   refusal   what becomes of a draw the safe zone will not accept
#
#     void   the draw vanishes. No mark, no tally, no trace — the plate cannot
#            be told apart from a bell that simply had a hole in it, and a
#            reader has no way to know a decision was ever made. THE LEGACY
#            LINEAGE, byte for byte: this is the bare `return` that has always
#            been on line 120, and it is what all eight rooms ship today.
#     rim    the draw is pushed to the wall. It keeps its DIRECTION and loses
#            its RADIUS, so every refusal lands on the boundary circle itself
#            and the hole acquires a hard bright edge whose density is the
#            tally of everything refused along that bearing. The count survives;
#            the coordinate does not. This is what clamping looks like when you
#            can finally see it, and clamping is everywhere in this repo.
#     echo   the draw is returned through the boundary, mirrored: r becomes
#            2R − r. Nothing is lost and nothing is invented — it is a bijection
#            — but the refused mass piles into the annulus just outside the rim
#            and doubles it. The plate now overstates the tails, which is the
#            standard, quiet cost of reflecting at a wall.
#     ghost  the draw is recorded where it fell, in its own pale ink. The hole
#            fills with a grey bell and the plate admits, in one glance, both
#            what it kept and what it refused. Maximum disclosure, and the only
#            value at which the picture is honest about being a subtraction.
#     none   nothing is refused. safe_zone_radius stops legislating, every draw
#            is kept in the palette ink, and the plate shows one undivided
#            gaussian — the control frame, and the thing the other four are all
#            departures from.
#
# THE LADDER RUNS none · void < rim < echo < ghost, ordered by how much the
# picture concedes about its own censorship: nothing, then the count, then the
# shape displaced, then everything. `none` sits outside it because there is
# nothing to concede when nothing was refused.
#
# WHAT IS DELIBERATELY NOT THE AXIS. splatter_update_interval is a RATE and
# invisible to a still (info_board already burned a whole sweep proving that).
# stddev and safe_zone_radius are the two tempting dials and both are
# MAGNITUDES: sweeping stddev would publish five bells of five widths, which is
# a picture of a number, not of a claim. dot_alpha and color_palette are "which
# colour", which is never an argument. All four stay plain exports.
#
# NOT TOUCHED: the mathematics. The Box–Muller transform, the mean, the
# standard deviation, the distance test against safe_zone_radius and the
# blend-on-white compositing are identical at every value. This axis changes
# only what happens on the far side of a test whose answer never moves.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS — what becomes of a draw the safe zone will not accept.
## "void" is the legacy value: the bare `return` this artifact has always had.
@export_enum("void", "rim", "echo", "ghost", "none") var refusal: String = "void"

## The allow-list — the same five words in the same spelling as the
## @export_enum above. A map token (#refusal:) is checked against this.
const REFUSALS: PackedStringArray = ["void", "rim", "echo", "ghost", "none"]

## The ink a refused draw is recorded in at `ghost`. Deliberately not from
## color_palette: a refusal that came back in the same paint as an acceptance
## would be a lie about the plate. Grey, low alpha, legible over white.
const GHOST_INK: Color = Color(0.42, 0.44, 0.50, 0.30)

# ── Determinism: the seed, and the bench-only prefill ────────────────────────
# THIS ARTIFACT IS MADE OF RANDOM DRAWS, so an evidence sweep of an unseeded
# plate renders five different splatters and reports the difference between the
# splatters as the axis — a confident, entirely false bite that nothing
# downstream can catch. Two exports close that, and both default to
# "behave exactly as before".

## Pins the streams this plate draws from. -1 = do not touch them, i.e. today:
## randomize() at the top of _ready() and every sample off the global stream,
## which is right in a room and useless on a bench. Any value >= 0 builds TWO
## local generators instead — one for positions, one for palette picks.
##
## The split is not decoration. `rim` and `echo` KEEP a draw the other values
## discard, so they consume one extra palette pick per refusal; on a single
## stream that offset would shift every subsequent position and the five tiles
## would again be five different splatters. With positions on their own
## generator the sample sequence is identical at all five values and the only
## thing that varies is what the plate did with it — which is the whole claim.
@export var splatter_seed: int = -1

## Bench-only. The timer stamps one dot every splatter_update_interval, so at
## the moment the sweep photographs (~1.2 s) there are about twenty dots on a
## 640x640 plate — 0.4% ink, a white square, and five identical white squares.
## This lays the painting down synchronously at the end of _ready() instead, so
## the axis has something to be visible in. 0 = today, and 0 is what every room
## ships; the timer is untouched and keeps stamping afterwards either way.
@export var preroll_splatters: int = 0

## Positions, when splatter_seed >= 0. null = use the global stream (today).
var _pos_rng: RandomNumberGenerator = null
## Palette picks, when splatter_seed >= 0. Kept apart from _pos_rng on purpose;
## see the note on splatter_seed above.
var _hue_rng: RandomNumberGenerator = null

# Internal variables
var img: Image
var texture: ImageTexture
var edge_points: Array = []
var splatter_count: int = 0
var timer: Timer

# Outline mesh
var outline_mesh: ImmediateMesh
var outline_mesh_instance: MeshInstance3D
var visual_frame_root: Node3D

func _ready() -> void:
	randomize()
	_setup_visual_frame()
	_initialize_texture()
	_setup_timer()
	_setup_outline_mesh()
	# APPENDED LAST, and only ever additive. randomize() above still runs at
	# every value including the default, so a room's global stream is exactly
	# where it always was; _setup_seeded_streams() draws nothing, and _preroll()
	# returns immediately unless a bench asked for it.
	_setup_seeded_streams()
	_preroll()
	print("GaussianPaintSplatter: Initialized with safe zone radius %.0f" % safe_zone_radius)

# Initialize the image and texture
func _initialize_texture() -> void:
	img = Image.create(splatter_width, splatter_height, false, Image.FORMAT_RGBA8)
	texture = ImageTexture.new()

	# Fill background with white
	img.fill(Color.WHITE)

	texture = ImageTexture.create_from_image(img)
	_update_material(texture)

# Set up the timer for continuous splatter
func _setup_timer() -> void:
	timer = Timer.new()
	timer.wait_time = splatter_update_interval
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

# Set up the outline mesh
func _setup_outline_mesh() -> void:
	outline_mesh = ImmediateMesh.new()
	outline_mesh_instance = MeshInstance3D.new()
	outline_mesh_instance.mesh = outline_mesh

	# Create material for outline
	var outline_material = StandardMaterial3D.new()
	outline_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline_material.albedo_color = Color.BLACK
	outline_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outline_mesh_instance.material_override = outline_material

	add_child(outline_mesh_instance)
	outline_mesh_instance.visible = edge_toggle

# Timer callback
func _on_timer_timeout() -> void:
	_add_gaussian_splatter()
	texture.update(img)

	splatter_count += 1

	# Periodically detect edges
	if splatter_count % edge_detection_frequency == 0:
		_detect_edges()
		_create_outline_mesh()
		print("GaussianPaintSplatter: Edge detection at splatter count %d" % splatter_count)

# Add a splatter dot using Gaussian distribution
func _add_gaussian_splatter() -> void:
	var x := _random_gaussian(splatter_width / 2.0, stddev)
	var y := _random_gaussian(splatter_height / 2.0, stddev)

	# Calculate distance from center
	var center := Vector2(splatter_width / 2.0, splatter_height / 2.0)
	var splatter_pos := Vector2(x, y)
	var dist_from_center := center.distance_to(splatter_pos)

	# DRAW THE HUE BEFORE THE REFUSAL TEST, not after.
	#
	# The pick used to sit below this block, so `void` and `ghost` returned WITHOUT
	# consuming a hue draw while `rim`, `echo` and `none` fell through and consumed one per
	# refused sample. With a rejected fraction in the tens of percent the stream ends up
	# offset by hundreds of draws, so every accepted dot is a DIFFERENT COLOUR between
	# those two groups — same positions, different paint. The two-generator split pins
	# positions and cannot pin that. The critic compares colour per pixel, so most of the
	# measured void-to-rim change would have been a recolour rather than a rim, and the
	# axis would have reported a confident bite for the wrong reason.
	#
	# Hoisted here, every value consumes exactly one hue draw per sample and the palette
	# stream is identical across all five.
	var color := color_palette[_hue_index(color_palette.size())]

	# Skip if within safe zone
	if dist_from_center < safe_zone_radius:
		# ── THE AXIS ── the one branch point in this file, and it sits on the
		# far side of a test whose answer never moves. `void` falls to the
		# default arm and hits the same bare `return` this line has always
		# been, having drawn nothing extra: the legacy stream, byte for byte.
		match refusal_name():
			"none":
				pass  # nothing is refused — fall through and keep the draw
			"rim":
				splatter_pos = _rim_of(center, splatter_pos)
			"echo":
				splatter_pos = _echo_of(center, splatter_pos, dist_from_center)
			"ghost":
				_stamp_ghost(splatter_pos)
				return
			_:
				return  # "void" — the legacy lineage
		x = splatter_pos.x
		y = splatter_pos.y

	# Draw circular splatter
	_draw_circle(int(x), int(y), dot_radius, color)

# Draw a circular splatter on the image
func _draw_circle(center_x: int, center_y: int, radius: int, color: Color) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			# Check if point is inside circle
			if dx * dx + dy * dy <= radius * radius:
				var px = clamp(center_x + dx, 0, splatter_width - 1)
				var py = clamp(center_y + dy, 0, splatter_height - 1)

				# Blend with existing pixel
				var current_color := img.get_pixel(px, py)
				var blended := current_color.blend(color)
				img.set_pixel(px, py, blended)

# Detect edges using radial sampling
func _detect_edges() -> void:
	edge_points.clear()

	var center := Vector2(splatter_width / 2.0, splatter_height / 2.0)
	var num_directions := 360  # Number of radial directions
	var max_distance := splatter_width / 2
	var color_threshold := 0.9  # Threshold to detect non-white pixels

	for angle in range(num_directions):
		var radian_angle := deg_to_rad(float(angle))
		var direction := Vector2(cos(radian_angle), sin(radian_angle))

		var found_edge := false
		for distance in range(int(safe_zone_radius), max_distance):
			var point := center + direction * distance

			# Check bounds
			if point.x < 0 or point.x >= splatter_width or point.y < 0 or point.y >= splatter_height:
				break

			# Check if pixel is colored (not white)
			var pixel_color := img.get_pixel(int(point.x), int(point.y))
			if pixel_color.r < color_threshold or pixel_color.g < color_threshold or pixel_color.b < color_threshold:
				# Found edge - store normalized coordinates
				edge_points.append(point)
				found_edge = true
				break

# Create outline mesh from detected edge points
func _create_outline_mesh() -> void:
	if edge_points.is_empty():
		return

	outline_mesh.clear_surfaces()
	outline_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	# Scale factor to convert image coordinates to 3D coordinates
	var scale_factor := 2.0 / float(splatter_width)
	var offset := Vector2(splatter_width / 2.0, splatter_height / 2.0)

	for point in edge_points:
		# Convert from image space to 3D space
		var normalized = (point - offset) * scale_factor
		outline_mesh.surface_add_vertex(Vector3(normalized.x, 0, normalized.y))

	# Close the loop
	if edge_points.size() > 0:
		var first_point = edge_points[0]
		var normalized = (first_point - offset) * scale_factor
		outline_mesh.surface_add_vertex(Vector3(normalized.x, 0, normalized.y))

	outline_mesh.surface_end()
	outline_mesh_instance.visible = edge_toggle

# Generate Gaussian random number using Box-Muller transform
func _random_gaussian(mean: float, stddev: float) -> float:
	# _unit_draw() IS randf() whenever splatter_seed is -1, which is every room.
	# Nothing is inserted before either call, so the order and the count of
	# draws in this transform are exactly what they always were.
	var u1 := _unit_draw()
	var u2 := _unit_draw()

	# Prevent log(0)
	if u1 < 0.0001:
		u1 = 0.0001

	var z0 := sqrt(-2.0 * log(u1)) * cos(TAU * u2)
	return mean + stddev * z0

# Update material with texture
func _update_material(tex: ImageTexture) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_texture = tex
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	material_override = material

# Public API
func reset() -> void:
	"""Reset the splatter"""
	img.fill(Color.WHITE)
	texture.update(img)
	edge_points.clear()
	splatter_count = 0
	_create_outline_mesh()
	print("GaussianPaintSplatter: Reset")

func pause() -> void:
	"""Pause splatter generation"""
	timer.paused = true

func resume() -> void:
	"""Resume splatter generation"""
	timer.paused = false

func set_safe_zone_radius(radius: float) -> void:
	"""Change the safe zone radius"""
	safe_zone_radius = radius
	print("GaussianPaintSplatter: Safe zone radius set to %.0f" % radius)

func set_standard_deviation(new_stddev: float) -> void:
	"""Change the standard deviation"""
	stddev = new_stddev
	print("GaussianPaintSplatter: Standard deviation set to %.1f" % stddev)

func toggle_edge_outline() -> void:
	"""Toggle edge outline visibility"""
	edge_toggle = !edge_toggle
	outline_mesh_instance.visible = edge_toggle

func _setup_visual_frame() -> void:
	if not show_visual_frame or mesh == null:
		return

	var aabb := mesh.get_aabb()
	var size := aabb.size
	if size.length_squared() <= 0.0:
		return

	var normal_axis := _smallest_axis_index(size)
	var axis_u := (normal_axis + 1) % 3
	var axis_v := (normal_axis + 2) % 3
	var size_u := _component_by_axis(size, axis_u)
	var size_v := _component_by_axis(size, axis_v)

	if size_u <= 0.0 or size_v <= 0.0:
		return

	var center := aabb.position + size * 0.5
	var normal_dir := _axis_vector(normal_axis)
	var u_dir := _axis_vector(axis_u)
	var v_dir := _axis_vector(axis_v)

	var frame_u := size_u + frame_margin * 2.0
	var frame_v := size_v + frame_margin * 2.0
	var back_center := center - normal_dir * frame_back_offset

	visual_frame_root = Node3D.new()
	visual_frame_root.name = "VisualFrame"
	add_child(visual_frame_root)

	var back_material := _create_frame_material(frame_back_color, false)
	var border_material := _create_frame_material(frame_border_color, true)

	# Backplate behind the visual
	_add_frame_piece(back_center, _size_from_axes(normal_axis, axis_u, axis_v, frame_depth, frame_u, frame_v), back_material)

	# Border ring around the visual
	var half_u := frame_u * 0.5
	var half_v := frame_v * 0.5
	var half_t := frame_border_thickness * 0.5

	var top_center := back_center + v_dir * (half_v - half_t)
	var bottom_center := back_center - v_dir * (half_v - half_t)
	var left_center := back_center - u_dir * (half_u - half_t)
	var right_center := back_center + u_dir * (half_u - half_t)

	_add_frame_piece(top_center, _size_from_axes(normal_axis, axis_u, axis_v, frame_depth, frame_u, frame_border_thickness), border_material)
	_add_frame_piece(bottom_center, _size_from_axes(normal_axis, axis_u, axis_v, frame_depth, frame_u, frame_border_thickness), border_material)
	_add_frame_piece(left_center, _size_from_axes(normal_axis, axis_u, axis_v, frame_depth, frame_border_thickness, frame_v), border_material)
	_add_frame_piece(right_center, _size_from_axes(normal_axis, axis_u, axis_v, frame_depth, frame_border_thickness, frame_v), border_material)

func _create_frame_material(color: Color, emissive: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.2
	return mat

func _add_frame_piece(center: Vector3, size_vec: Vector3, material: Material) -> void:
	var piece := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	piece.mesh = box
	piece.material_override = material
	piece.position = center
	piece.scale = size_vec
	visual_frame_root.add_child(piece)

func _smallest_axis_index(v: Vector3) -> int:
	if v.x <= v.y and v.x <= v.z:
		return 0
	if v.y <= v.x and v.y <= v.z:
		return 1
	return 2

func _component_by_axis(v: Vector3, axis: int) -> float:
	if axis == 0:
		return v.x
	if axis == 1:
		return v.y
	return v.z

func _axis_vector(axis: int) -> Vector3:
	if axis == 0:
		return Vector3.RIGHT
	if axis == 1:
		return Vector3.UP
	return Vector3.BACK

func _size_from_axes(normal_axis: int, axis_u: int, axis_v: int, depth: float, size_u: float, size_v: float) -> Vector3:
	var out := Vector3.ZERO
	out = out + _axis_vector(normal_axis) * depth
	out = out + _axis_vector(axis_u) * size_u
	out = out + _axis_vector(axis_v) * size_v
	return Vector3(absf(out.x), absf(out.y), absf(out.z))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## KNOWN LIMITATION, stated rather than hidden: the scene root
## (GaussianPaintSplatter.tscn) is a bare Node3D and this script lives on its
## PaintSplatter child, so the grid — which calls apply_grid_config on the ROOT
## — never reaches this method today. The sweep and the editor both set the
## property directly on whichever node owns it, so the axis is fully reachable
## there; a map token is not, until either the root gains a forwarder or the
## script moves up. Moving it is not a promotion-sized change: this script
## `extends MeshInstance3D` and owns the plate's mesh and material_override.
func apply_grid_config(config: Dictionary) -> void:
	if config.has("refusal"):
		var want: String = str(config["refusal"]).strip_edges().to_lower()
		if REFUSALS.has(want):
			refusal = want
		else:
			push_warning("gaussian_paint_splatter: unknown refusal '%s' — keeping '%s'" % [want, refusal])
	if config.has("splatter_seed"):
		splatter_seed = int(str(config["splatter_seed"]))
		_setup_seeded_streams()
	if config.has("preroll_splatters"):
		preroll_splatters = int(str(config["preroll_splatters"]))


# ═════════════════════════════════════════════════════════════════════════════
# THE REFUSAL
# ═════════════════════════════════════════════════════════════════════════════
# One function per value that needs one. None of them touches the sampler, the
# safe-zone test, the palette, the blend or the frame — they are only ever
# reached after the plate has already decided it will not accept a draw.

## The reader. Lower, strip, and fall back to the legacy value on anything
## unrecognised: a typo must not fill in a hole eight rooms expect to be empty.
func refusal_name() -> String:
	var v: String = refusal.strip_edges().to_lower()
	if REFUSALS.has(v):
		return v
	if v != "":
		push_warning("gaussian_paint_splatter: unknown refusal '%s' — keeping 'void'" % v)
	return "void"


## RIM — the refused draw keeps its bearing and loses its radius, landing on the
## boundary circle. The hole gets a hard bright edge and its density along any
## bearing is the tally of what was thrown away there.
func _rim_of(center: Vector2, p: Vector2) -> Vector2:
	var dir := p - center
	if dir.length_squared() < 0.000001:
		dir = Vector2.RIGHT
	return center + dir.normalized() * safe_zone_radius


## ECHO — the refused draw is reflected through the boundary: r becomes 2R − r,
## so a sample at the dead centre returns at 2R and one just inside the rim
## returns just outside it. Nothing is lost, and the annulus R..2R carries twice
## the mass it should — the standard quiet cost of bouncing at a wall.
func _echo_of(center: Vector2, p: Vector2, d: float) -> Vector2:
	var dir := p - center
	if dir.length_squared() < 0.000001:
		dir = Vector2.RIGHT
	return center + dir.normalized() * (2.0 * safe_zone_radius - d)


## GHOST — the refused draw is stamped where it actually fell, in GHOST_INK.
## Draws no palette pick, so this value consumes exactly the stream `void`
## consumes and the two plates are the same samples with one of them showing
## its own subtraction.
func _stamp_ghost(p: Vector2) -> void:
	_draw_circle(int(p.x), int(p.y), dot_radius, GHOST_INK)


# ═════════════════════════════════════════════════════════════════════════════
# DETERMINISM
# ═════════════════════════════════════════════════════════════════════════════

## Builds the two local generators, or leaves both null. Null is the default and
## the room behaviour: every call below falls straight through to the global
## randf()/randi() this file has always used.
func _setup_seeded_streams() -> void:
	if splatter_seed < 0:
		_pos_rng = null
		_hue_rng = null
		return
	_pos_rng = RandomNumberGenerator.new()
	_pos_rng.seed = splatter_seed
	_hue_rng = RandomNumberGenerator.new()
	# Disjoint from _pos_rng, and from anything else in the scene, so a palette
	# pick can never move a position. Same trick random_walk_leash uses for its
	# ghost walks.
	_hue_rng.seed = splatter_seed * 7919 + 104729


## One uniform draw for a POSITION. Identical to randf() unless seeded.
func _unit_draw() -> float:
	if _pos_rng != null:
		return _pos_rng.randf()
	return randf()


## One palette index. Identical to randi() % n unless seeded.
func _hue_index(n: int) -> int:
	if n <= 0:
		return 0
	if _hue_rng != null:
		return _hue_rng.randi() % n
	return randi() % n


## BENCH ONLY (preroll_splatters == 0 in every room, so this returns having done
## nothing and having drawn nothing). Runs the timer's own tick body N times
## synchronously — the identical sampler, the identical test, the identical
## stamp — so the plate the sweep photographs is a finished painting instead of
## twenty scattered dots. splatter_count is deliberately NOT advanced: the edge
## detector fires on that counter, and its outline is drawn at the wrong scale
## (see _create_outline_mesh), so waking it early would put a bug's picture in
## the evidence.
func _preroll() -> void:
	if preroll_splatters <= 0:
		return
	for i in range(preroll_splatters):
		_add_gaussian_splatter()
	texture.update(img)
