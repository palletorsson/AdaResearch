extends Node3D

# @identity
# essence: tapered CSG tube tunnel + animated rainbow gradient shader — walk through a cone of cycling color
# desire: to step into a narrowing tunnel of light where color flows past you like standing inside a prism
# critical_parameter: start_radius vs end_radius — the taper ratio determines whether the tunnel feels like entering or being swallowed
# triggers: _process updates shader parameters every frame; gradient_offset and animation_speed drive continuous color flow
# emerges: the cone shape creates forced perspective that makes the tunnel feel infinitely long even at modest segment counts
# needs: rainbow_hallway.gdshader [has]; CSG collision [has]; VR walkthrough [has]; speed control slider [missing]
# relationships: follows rainbow (static arc vs immersive tunnel); contrasts with spectrum_forest (ambient vs directed color experience)
# truth: a hallway of color is not a hallway with color on it — it is a space where color becomes the architecture itself

# ─────────────────────────────────────────────────────────────────────
#  STAGE-2 DNA — hand promotion 2026-08-05. The runner refused this token
#  for NO TURNABLE KNOBS. It has ten exports; two are RATES (animation_speed
#  is a shader clock, and a still cannot photograph a rate), and the other
#  eight are radii, lengths, counts and glow strengths — sizes, every one.
#  What the hallway is ABOUT, the colour you walk through, was seven
#  hard-coded Color literals in setup_hallway() with no way to say otherwise.
#
#  harmony — which rule chooses the colours the walk passes through.
#            The artifact's own truth line is "a hallway of color is not a
#            hallway with color on it — it is a space where color becomes
#            the architecture itself", and until now that architecture could
#            only ever be one thing: the spectrum, in order, once.
#
#  `banding` WAS CONSIDERED AND DECLINED. It is rainbow's word (roygbiv |
#  six | continuous | two) and rainbow is this file's declared predecessor
#  in its own @identity — but rainbow draws SEPARATE ARC MESHES, so a band
#  count there is a count of visible seams. Here the colours live in a
#  GradientTexture1D sampled per fragment, which interpolates: seven stops,
#  six stops and a continuous ramp render as the same smooth wash and the
#  axis would measure itself inert. `palette` was declined too —
#  platonicsolids has it for pride|trans|mono, which asks WHOSE colours,
#  and this asks BY WHAT RULE.
# ─────────────────────────────────────────────────────────────────────

const HARMONIES := ["spectral", "complementary", "analogous", "monochrome"]

@export_enum("spectral", "complementary", "analogous", "monochrome") var harmony: String = "spectral"

## CAPTURE FIXTURE, NOT AN AXIS, and off in every map. This artifact is built
## entirely from CSGCombiner3D/CSGCylinder3D and owns no MeshInstance3D at all.
## GridInteractablesComponent._compute_local_aabb handles CSGShape3D and so
## grounds it correctly, but capture_config_sweep._subtree_aabb counts only
## MeshInstance3D and MultiMeshInstance3D and falls back to a 1 m box — which
## puts the sweep camera about five metres from the origin, inside the mouth of
## a sixteen-metre tunnel, photographing a fragment of tube wall. Set to "on"
## the artifact adds one BoxMesh at the tunnel's true extent with layers = 0,
## so it renders to nothing and exists only to be measured. Left OFF by default
## so no placement gains a node.
##
## Untyped-by-String on purpose: a typed bool export rejects a fixture string
## "true" before _ready and the flag silently does nothing.
@export var capture_anchor: String = "off"  # off | on

@export var animation_speed: float = 1.0
@export var gradient_offset: float = 0.5
@export var glow_intensity: float = 0.5
@export var emission_strength: float = 0.5

@export_group("Cone Shape")
@export var cone_mode: bool = true
@export var start_radius: float = 4.0
@export var end_radius: float = 1.5
@export var num_segments: int = 12
@export var segment_length: float = 2.0
@export var wall_thickness: float = 0.3

var shader_material: ShaderMaterial
var gradient_texture: GradientTexture1D
var segments_parent: Node3D
var _built: bool = false

func _ready() -> void:
	_read_dna()

	segments_parent = get_node_or_null("HallwaySegments")
	if not segments_parent:
		segments_parent = Node3D.new()
		segments_parent.name = "HallwaySegments"
		add_child(segments_parent)

	setup_hallway()
	setup_environment()
	if capture_anchor.strip_edges().to_lower() == "on":
		_add_capture_anchor()
	_built = true


## Read the axis off the metadata the grid stamps on the artifact ROOT before
## add_child, so it lands before a single segment is generated. An unknown word
## keeps the value already held.
func _read_dna() -> void:
	if has_meta("config_harmony"):
		var h: String = str(get_meta("config_harmony")).strip_edges().to_lower()
		if HARMONIES.has(h):
			harmony = h


## The seven stops this file has always shipped, in the order it shipped them.
## Held in one place so every rule below can be derived FROM them rather than
## invented beside them.
func _spectral_colors() -> PackedColorArray:
	return PackedColorArray([
		Color(1.0, 0.2, 0.2),   # Red
		Color(1.0, 0.6, 0.2),   # Orange
		Color(1.0, 1.0, 0.2),   # Yellow
		Color(0.2, 1.0, 0.2),   # Green
		Color(0.2, 0.6, 1.0),   # Blue
		Color(0.6, 0.2, 1.0),   # Purple
		Color(1.0, 0.2, 0.6)    # Pink
	])


## Seven stops at seven positions, at EVERY value of harmony. The axis argues
## about the rule that picks the colours, never about how many names the
## spectrum gets — see the decline of `banding` at the top of this file.
func _gradient_offsets() -> PackedFloat32Array:
	return PackedFloat32Array([0.0, 0.16, 0.33, 0.5, 0.66, 0.83, 1.0])


## SHORT-CIRCUIT AT THE SHIPPED VALUE. `spectral` returns the literal array and
## never touches a hue calculation, so the default cannot drift by a rounding
## step. The other three take their base hue from the shipped first stop
## (Color(1.0, 0.2, 0.2), hue 0.0), so nothing here is a colour somebody chose
## twice — the rule is applied to the artifact's own starting note.
##
##   complementary — every stop is the opposite of its neighbour: the walk is a
##                   passage between two hues that have nothing between them but
##                   the grey where they cancel.
##   analogous     — the whole tunnel inside a twelfth of the circle: colour that
##                   changes without ever becoming another colour.
##   monochrome    — one hue, value alone. The counterfactual to the artifact's
##                   own title: a hallway of light and dark, walked the same way.
func _gradient_colors() -> PackedColorArray:
	var base: PackedColorArray = _spectral_colors()
	if harmony == "spectral":
		return base
	var h0: float = base[0].h
	var n: int = base.size()
	var out: PackedColorArray = PackedColorArray()
	for i in range(n):
		var t: float = float(i) / float(n - 1)
		if harmony == "complementary":
			out.append(Color.from_hsv(fposmod(h0 + 0.5 * float(i % 2), 1.0), 0.8, 1.0))
		elif harmony == "analogous":
			out.append(Color.from_hsv(fposmod(h0 + (t - 0.5) / 6.0, 1.0), 0.8, 1.0))
		else:
			out.append(Color.from_hsv(h0, 0.8, 0.15 + 0.85 * t))
	return out


## The colour of the omni light dropped every third segment. At `spectral` this
## is the shipped line verbatim — the lights were on a hue sweep of their own,
## offset by gradient_offset, and that stays exactly true at the default. At any
## other value they read the gradient instead, because a tunnel lit in hues its
## own walls do not carry would make the axis argue with itself.
func _light_color(t: float) -> Color:
	if harmony == "spectral":
		var hue: float = fmod(t + gradient_offset, 1.0)
		return Color.from_hsv(hue, 0.8, 1.0)
	var cols: PackedColorArray = _gradient_colors()
	var idx: int = clampi(int(round(t * float(cols.size() - 1))), 0, cols.size() - 1)
	return cols[idx]


## A box at the tunnel's real extent, rendering to no visual layer. See the
## capture_anchor export. Parented to the ROOT and not to HallwaySegments so
## setup_hallway's clear pass cannot take it away on a rebuild.
func _add_capture_anchor() -> void:
	if get_node_or_null("CaptureAnchor") != null:
		return
	var anchor := MeshInstance3D.new()
	anchor.name = "CaptureAnchor"
	var box := BoxMesh.new()
	var span: float = float(maxi(num_segments, 1)) * segment_length
	var r: float = maxf(start_radius, end_radius) + wall_thickness
	box.size = Vector3(r * 2.0, r * 2.0, span)
	anchor.mesh = box
	anchor.position = Vector3(0, 0, -span * 0.5)
	anchor.layers = 0
	add_child(anchor)


func setup_hallway() -> void:
	# Clear existing segments. remove_child first: queue_free does not take effect
	# until the end of the frame, so on a rebuild the old tubes would otherwise
	# still be in the tree while the new ones are added.
	for child in segments_parent.get_children():
		segments_parent.remove_child(child)
		child.queue_free()

	# Create the shader material
	shader_material = ShaderMaterial.new()
	var shader = load("res://algorithms/wavefunctions/rainbow_hallway/rainbow_hallway.gdshader")
	if shader:
		shader_material.shader = shader

	# Create gradient texture
	gradient_texture = GradientTexture1D.new()
	var gradient = Gradient.new()

	# The colours the walk passes through — see harmony, above.
	gradient.offsets = _gradient_offsets()
	gradient.colors = _gradient_colors()

	gradient_texture.gradient = gradient
	if shader_material:
		shader_material.set_shader_parameter("rainbow_gradient", gradient_texture)
	
	# Generate cone segments
	_generate_cone_segments()
	
	# Set initial shader parameters
	update_shader_parameters()

func _generate_cone_segments() -> void:
	var total_length = num_segments * segment_length
	
	for i in range(num_segments):
		var t = float(i) / float(num_segments - 1) if num_segments > 1 else 0.0
		var radius = lerp(start_radius, end_radius, t)
		var z_pos = i * segment_length
		
		# Create tube segment using CSG
		var segment = _create_tube_segment(radius, segment_length, i)
		segment.position = Vector3(0, 0, -z_pos)
		segments_parent.add_child(segment)
		
		# Add light only every 3rd segment for performance
		if i % 3 == 0:
			var light_color: Color = _light_color(t)
			var light = OmniLight3D.new()
			light.light_color = light_color
			light.light_energy = 3.0  # Brighter to compensate for fewer lights
			light.omni_range = radius * 3.5  # Larger range
			light.shadow_enabled = false  # Disable shadows for performance
			light.position = Vector3(0, 0, -z_pos - segment_length * 0.5)
			segments_parent.add_child(light)

func _create_tube_segment(radius: float, length: float, index: int) -> CSGCombiner3D:
	var combiner = CSGCombiner3D.new()
	combiner.name = "Segment_%d" % index
	combiner.use_collision = true
	
	# Outer cylinder - reduced sides for performance
	var outer = CSGCylinder3D.new()
	outer.radius = radius + wall_thickness
	outer.height = length
	outer.sides = 16  # Reduced from 24 for better performance
	outer.rotation_degrees.x = 90
	outer.position.z = -length * 0.5
	combiner.add_child(outer)
	
	# Inner cylinder (subtract) - reduced sides for performance
	var inner = CSGCylinder3D.new()
	inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	inner.radius = radius
	inner.height = length + 0.1  # Slightly longer to avoid z-fighting
	inner.sides = 16  # Reduced from 24 for better performance
	inner.rotation_degrees.x = 90
	inner.position.z = -length * 0.5
	combiner.add_child(inner)
	
	# Apply material
	if shader_material:
		combiner.material_override = shader_material
	else:
		# Fallback material
		var mat = StandardMaterial3D.new()
		var hue = float(index) / float(num_segments)
		mat.albedo_color = Color.from_hsv(hue, 0.7, 0.9)
		mat.emission_enabled = true
		mat.emission = Color.from_hsv(hue, 0.8, 1.0)
		mat.emission_energy_multiplier = emission_strength
		combiner.material_override = mat
	
	return combiner

func setup_environment() -> void:
	var env = Environment.new()
	
	env.glow_enabled = true
	env.glow_intensity = glow_intensity
	env.glow_strength = 1.2
	env.glow_mix = 0.5
	env.glow_bloom = 0.2
	env.glow_hdr_threshold = 0.4
	
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.1, 0.1, 0.15)
	env.ambient_light_energy = 0.3
	
	var world_env = get_node_or_null("WorldEnvironment")
	if world_env:
		world_env.environment = env

func _process(_delta):
	update_shader_parameters()

func update_shader_parameters() -> void:
	if shader_material:
		shader_material.set_shader_parameter("animation_speed", animation_speed)
		shader_material.set_shader_parameter("gradient_offset", gradient_offset)
		shader_material.set_shader_parameter("glow_intensity", glow_intensity)
		shader_material.set_shader_parameter("emission_strength", emission_strength)
		var total_length = num_segments * segment_length
		shader_material.set_shader_parameter("gradient_start_z", 0.0)
		shader_material.set_shader_parameter("gradient_length_m", total_length)

## GUARDED. This used to call setup_hallway() unconditionally at the bottom — on
## ANY call, including one naming nothing this artifact owns — which is the
## force_pad fault: every child freed and the whole tunnel regenerated for a key
## the artifact never read. It now rebuilds only when a value actually CHANGED
## and only after _ready has built once. All 4 placements (Color_Walls,
## Corridor_Color_Walls, TestMap_Unused_16 and the Curation_Bay_color_4
## curation_station roster) carry the bare token with no config keys at all, and
## the grid does not call this method for a token that carries none.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return

	var changed: bool = false

	if config.has("harmony"):
		var h: String = str(config["harmony"]).strip_edges().to_lower()
		if HARMONIES.has(h) and h != harmony:
			harmony = h
			changed = true

	if config.has("start_radius"):
		var sr: float = float(config["start_radius"])
		if not is_equal_approx(sr, start_radius):
			start_radius = sr
			changed = true

	if config.has("end_radius"):
		var er: float = float(config["end_radius"])
		if not is_equal_approx(er, end_radius):
			end_radius = er
			changed = true

	if config.has("num_segments"):
		var ns: int = int(config["num_segments"])
		if ns > 0 and ns != num_segments:
			num_segments = ns
			changed = true

	if config.has("segment_length"):
		var sl: float = float(config["segment_length"])
		if sl > 0.0 and not is_equal_approx(sl, segment_length):
			segment_length = sl
			changed = true

	if config.has("animation_speed"):
		var asp: float = float(config["animation_speed"])
		if not is_equal_approx(asp, animation_speed):
			animation_speed = asp
			# _process pushes this to the shader every frame; no rebuild needed.

	if not changed:
		return
	# Before the first build there is nothing to tear down — _ready() will pick the
	# new values up when it runs.
	if not _built:
		return
	setup_hallway()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

