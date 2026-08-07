extends Node3D
class_name FloatingSphereField

# @identity
# essence: a sparse field of soft glowing spheres drifting in the void around the player — the SUBTLE successor to the Kusama dot-grid. Where the grid asserted a rigid lattice ("the grid IS the aesthetic"), this is the grid exhaled: the same "forms exist in space before they have shape" reading, but as a few dozen luminous motes hanging in air, breathing on a slow drift instead of snapping to coordinates.
# desire: the field wants to be ATMOSPHERE, not architecture. It should be felt at the edge of vision and never counted. A point-grid says "here is structure"; this says "here is room, and the room is not empty." It wants to make the void legible as a place without filling it.
# critical_parameter: sphere_count — the entire reading hinges on sparsity. A few dozen (~40) reads as "a presence in the air"; a few hundred reads as fog or snow and the subtlety collapses. Sparse is the point. The Kusama grid was overwhelming-by-repetition; this is its inverse — presence-by-scarcity.
# triggers: _ready() builds TWO GPUParticles3D emitters over one shared SphereMesh — glow motes under an additive unshaded override, beads under a shaded dielectric one — each with a ParticleProcessMaterial (box emission volume); preprocess fills the volume at t=0 so it reads immediately. apply_grid_config rebuilds from DNA.
# emerges: low count + large bounds + slow drift = "ambient field, barely there"; raise emission and tighten bounds and it becomes "a swarm of fireflies"; kill drift and it freezes into a soft 3D starfield; push bead_fraction toward 1 and the light in the room turns to gravel.
# needs: GPUParticles3D [present]; box emission volume sized to the play space [present]; sphere draw pass [present]; additive emissive material so spheres glow not occlude [present]; preprocess so the field is full on the first frame (VR + capture) [present]; a top-to-bottom value ramp on the mote, because an unshaded ball has no top and no bottom of its own [present]; a second emitter to carry a second finish, because one particle system has exactly one material [present]; per-particle colour spread, the only per-instance channel a field of four-pixel motes actually has [present]
# relationships: successor to floating_primitives (the Kusama/grid biome layer — this is the proposed re-definition, prototyped as a placeable artifact first); cousin to the noise_dust biome layer (seq 8) which also drifts motes, but THIS uses zero noise/randomness in its INTENT (the GPU does the scatter, the curriculum still teaches "points in space"); sibling to dark_sphere (both are spheres in void, one absorbs light, one emits it).
# truth: the void was never empty — it was under-rendered. The grid made the void countable; this makes it inhabited. To replace a lattice with a drift is to trade the comfort of knowing exactly where everything is for the truth that presence does not require a coordinate.

## A sparse field of soft, drifting, glowing spheres — an ambient
## "forms in the void" field built on a single GPUParticles3D.
##
## Prototype for re-defining the seq-1 biome layer (floating_primitives,
## "the Kusama/grid field"). Built as a placeable artifact first so the
## look can be tuned in one map (Point_One) before promotion.
##
## Origin sits at the artifact's grid cell; the emission volume is
## centered on `volume_offset` from there so the field can be parked
## over the whole play area regardless of where the token lives.

# ── DNA ───────────────────────────────────────────────────────────────

## STAGE-2 AXIS — how populated the void is.
##
## This is the artifact's own declared critical_parameter made reachable as one
## word. The @identity above says the entire reading hinges on sparsity, and yet
## all 51 shipped placements sit at the same 44: the knob existed (config_sphere_count)
## and no map ever moved it. `density` is that knob given four named stops.
##
## Worth varying because the difference is the artifact's whole argument. At
## `scarce` the void has a few countable events in it; at `fog` it has weather.
## Same 16 x 6 x 16 m emission volume at every value — `bounds` and `volume_offset`
## are deliberately NOT touched, so the composition of the room never shifts and
## only the population does. Radius moves inversely with count so both extremes
## stay legible from the pulled-back capture distance the 20 x 10 x 20 visibility
## AABB forces: a few large motes, or a haze of fine ones.
##
## Count and mass only — no drift/lifetime knob here. A still cannot hold a rate.
@export_enum("scarce", "sparse", "dense", "fog") var density: String = "sparse"

@export_group("Density")
## How many spheres exist at once. SPARSE is the whole point — a few
## dozen reads as "presence in the air"; hundreds read as fog/snow.
## Normally driven by the `density` axis; an explicit `#sphere_count:` token
## on a placement still wins, exactly as it did before the axis existed.
@export var sphere_count: int = 44
## Half-extents of the box the spheres live in (metres). Sized to the
## play space so the field surrounds without crowding.
@export var bounds: Vector3 = Vector3(8.0, 3.0, 8.0)
## Centre of the emission volume relative to this node's origin.
@export var volume_offset: Vector3 = Vector3(0.0, 2.4, 0.0)

@export_group("Sphere")
## Radius of one mote in metres. Driven by `density` (large motes when scarce,
## fine ones in fog) unless a placement names `#sphere_radius:` explicitly.
@export var sphere_radius: float = 0.055
## Random scale spread — each sphere picks a size in [min, max] × radius.
@export var scale_min: float = 0.5
@export var scale_max: float = 1.6

@export_group("Motion")
## Metres/second of gentle drift. Keep tiny — this should breathe, not fly.
@export var drift_speed: float = 0.18
## Slight upward bias so the field feels like it's rising/floating.
@export var float_bias: float = 0.06
## Organic wander. 0 = straight drift, higher = lazy curling paths.
@export var turbulence: float = 0.6
## Seconds a sphere lives before respawning elsewhere in the volume.
@export var lifetime: float = 14.0

@export_group("Look")
## Core tint. Defaults to a cool lab-white with a cyan lean to match
## the Point_One blue accent.
@export var color: Color = Color(0.72, 0.88, 1.0)
@export var emission_energy: float = 1.6
## Additive blend = spheres glow and layer softly instead of occluding.
## Governs the GLOW motes only — beads are matter and are drawn opaque.
@export var additive: bool = true
## Fraction of the field built as BEADS instead of glow motes.
##
## A glow mote is light: unshaded, additive, no surface. A bead is matter: a
## shaded dielectric with a specular lobe, a dark side and a dim luminous core,
## so it turns under the room's light instead of sitting at one value forever.
## Same radius, same volume, same total population — this splits the FINISH of
## the field, never its silhouette. At 0.0 every mote is glow, which is the
## pre-2026-08 build exactly.
##
## Held near a third on purpose: the field is still mostly light, and the beads
## are the few forms that have caught a surface.
@export_range(0.0, 1.0, 0.01) var bead_fraction: float = 0.30

# ── Surface ───────────────────────────────────────────────────────────
#
# THE MOTE IS FOUR TO TWENTY PIXELS. Everything below follows from that one
# measurement, taken off the shipped sweep tile: the whole field occupies 0.517%
# of the frame, and a single 0.11 m mote lands at roughly 13 px in a 760 px
# render. There is no room on it for a surface story. What there IS room for is
# a gradient across the mote and a difference between motes, so that is where
# the finish went.
#
# The reference radius the grain is sized against — the shipped 0.055 m. The
# bead grain is scaled by REF/r so a `scarce` mote (0.10 m) and a `fog` mote
# (0.026 m) carry the same NUMBER of surface features, not the same feature size.
const MOTE_REF_RADIUS: float = 0.055

# Multiplier on PbrKit's hard_plastic tiling, chosen by counting pixels rather
# than metres. PbrKit's rule of thumb (factor ~= 1 / longest dimension) would
# read 1 / 0.11 = 9 for a mote and put about 120 noise blobs across it — one
# blob per pixel in the capture, which is the television static this project has
# already paid three rounds of critics to learn about. 0.30 lands roughly four
# features across a mote instead: about 3 px each in the capture frame, about
# 30 px at arm's length in VR, where the player is standing INSIDE the emission
# volume and the near motes are the size of a plum.
const BEAD_GRAIN_FACTOR: float = 0.30

# The bead's luminous floor, as a fraction of emission_energy. A bead is matter,
# so it is meant to be dimmer than the light around it — but a shaded surface in
# an unlit room is a surface that is not there, and a third of the field must not
# be able to vanish. This is the floor that keeps it present with the lights off.
const BEAD_EMISSION: float = 0.62

# The mote's own light-to-shade ramp. Peak at the top pole, floor at the bottom,
# with the fall-off weighted low so most of the sphere sits near full value and
# the dark side is a hem rather than half the ball.
#
# The peak is deliberately over 1.0 and the texture is a half-float, because the
# ramp must REDISTRIBUTE the mote's light, not remove it: floor + (peak - floor)
# * e/(e+1) = 0.944, so the field renders within 6% of the brightness it has
# shipped at across 75 placements while its tonal spread goes from nothing to
# nearly two to one. Clamping the peak at 1.0 in an RGB8 texture would have cost
# 14% of the field's presence to buy the same gradient.
const RAMP_PEAK: float = 1.16
const RAMP_FLOOR: float = 0.62
const RAMP_EXPONENT: float = 1.5

# 32 rows, mipmapped. NOT a stylistic choice: the mip chain is what makes one
# ramp correct at both viewing distances. At arm's length the GPU samples near
# mip 0 and the mote is a shaded ball; at capture distance it samples down the
# chain and the ramp softens instead of aliasing; only when the mote is about
# one pixel does it reach the flat top of the chain, which is the right answer
# there. A 256-row ramp would have been averaged to a constant long before that.
const RAMP_ROWS: int = 32

const PBR := preload("res://commons/render/pbr_kit.gd")

## Cached across the process, like PbrKit's own flat_normal — 75 placements
## should not mint 75 identical 4 x 32 ramps.
static var _mote_ramp: ImageTexture = null


# ── Axis table ────────────────────────────────────────────────────────

const DENSITIES: PackedStringArray = ["scarce", "sparse", "dense", "fog"]

## Population per value. `sparse` is 44 — the shipped number, byte-identical to
## every one of the 51 current placements.
const DENSITY_COUNT: Dictionary = {
	"scarce": 12,
	"sparse": 44,
	"dense": 150,
	"fog": 400,
}

## Mote radius in metres, moving inversely with count so total luminous mass
## stays in the same register while the GRAIN changes. 0.055 is the shipped value.
const DENSITY_RADIUS: Dictionary = {
	"scarce": 0.10,
	"sparse": 0.055,
	"dense": 0.038,
	"fog": 0.026,
}

## Fixed emitter seed so two builds of one value scatter identically. Without it
## the GPU picks a fresh scatter each run and a pixel critic reads the noise as
## the axis moving.
const FIELD_SEED: int = 20260728

# ── Internal ──────────────────────────────────────────────────────────

var _built: bool = false
var _particles: GPUParticles3D = null
## Only the nodes THIS script created. Teardown walks this, never get_children() —
## the grid adds label plates, packaging and tag markers as siblings and freeing
## those is how an artifact loses its framing.
var _spawned: Array[Node] = []
## Set when a placement names the count/radius directly. An explicit token beats
## the axis, so every pre-axis map keeps behaving exactly as it did.
var _count_overridden: bool = false
var _radius_overridden: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build_field()          # synchronous — children exist when _ready returns
	_built = true


func apply_grid_config(config_data: Dictionary) -> void:
	var before_density: String = density
	var before_count: int = sphere_count
	var before_radius: float = sphere_radius
	var before_count_ovr: bool = _count_overridden
	var before_radius_ovr: bool = _radius_overridden
	var before_bounds: Vector3 = bounds
	var before_offset: Vector3 = volume_offset
	var before_drift: float = drift_speed
	var before_energy: float = emission_energy
	var before_turbulence: float = turbulence
	var before_color: Color = color
	var before_bead: float = bead_fraction

	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()

	# Called before _ready (the grid queues this deferred, but a composer may
	# configure an instance it has not parented yet): keep the values, build later.
	if not _built:
		return

	# curation_station passes {"emissive": false} one line after hiding labels and
	# making the instance inert. Nothing geometric moved, so touch nothing and say
	# nothing — an unconditional rebuild here throws that framing away.
	if density == before_density \
			and sphere_count == before_count \
			and is_equal_approx(sphere_radius, before_radius) \
			and _count_overridden == before_count_ovr \
			and _radius_overridden == before_radius_ovr \
			and bounds.is_equal_approx(before_bounds) \
			and volume_offset.is_equal_approx(before_offset) \
			and is_equal_approx(drift_speed, before_drift) \
			and is_equal_approx(emission_energy, before_energy) \
			and is_equal_approx(turbulence, before_turbulence) \
			and is_equal_approx(bead_fraction, before_bead) \
			and color.is_equal_approx(before_color):
		return

	_rebuild_now()
	var total: int = _resolved_count()
	print("[FloatingSphereField] Config applied — density=%s, spheres=%d (%d bead), radius=%.3f" % [
		density, total, _resolved_bead_count(total), _resolved_radius()])


## Synchronous teardown + rebuild. No call_deferred anywhere in this path: a
## deferred rebuild that removes children first leaves _auto_ground_artifact
## measuring a zero AABB, and the artifact is then never grounded.
func _rebuild_now() -> void:
	for c: Node in _spawned:
		if is_instance_valid(c):
			remove_child(c)     # out of the tree now — no double-render frame
			c.queue_free()
	_spawned.clear()
	_particles = null
	_build_field()


func _read_metadata_overrides() -> void:
	if has_meta("config_density"):
		density = _pick_axis(str(get_meta("config_density")), DENSITIES, density)
	if has_meta("config_sphere_count"):
		sphere_count = int(str(get_meta("config_sphere_count")))
		_count_overridden = true
	if has_meta("config_sphere_radius"):
		sphere_radius = float(str(get_meta("config_sphere_radius")))
		_radius_overridden = true
	if has_meta("config_drift_speed"):
		drift_speed = float(str(get_meta("config_drift_speed")))
	if has_meta("config_emission_energy"):
		emission_energy = float(str(get_meta("config_emission_energy")))
	if has_meta("config_turbulence"):
		turbulence = float(str(get_meta("config_turbulence")))
	if has_meta("config_bead_fraction"):
		bead_fraction = clampf(float(str(get_meta("config_bead_fraction"))), 0.0, 1.0)
	if has_meta("config_color"):
		color = _parse_color(str(get_meta("config_color")), color)
	if has_meta("config_bounds"):
		bounds = _parse_vec3(str(get_meta("config_bounds")), bounds)
	if has_meta("config_volume_offset"):
		volume_offset = _parse_vec3(str(get_meta("config_volume_offset")), volume_offset)


# ── Axis resolution ───────────────────────────────────────────────────

## Spheres alive at once. The axis decides unless a placement named the count.
func _resolved_count() -> int:
	if _count_overridden:
		return maxi(1, sphere_count)
	return maxi(1, int(DENSITY_COUNT.get(density, DENSITY_COUNT["sparse"])))


## Mote radius in metres. Inverse to the count, so `scarce` is a dozen fat motes
## and `fog` is four hundred fine ones rather than four hundred fat ones welding
## into a solid wall.
func _resolved_radius() -> float:
	if _radius_overridden:
		return maxf(0.001, sphere_radius)
	return float(DENSITY_RADIUS.get(density, DENSITY_RADIUS["sparse"]))


## How many of the field's motes are beads. Rounds, and never takes the last
## glow mote — a field with no light in it is a different artifact.
func _resolved_bead_count(total: int) -> int:
	var f: float = clampf(bead_fraction, 0.0, 1.0)
	if f <= 0.001 or total <= 1:
		return 0
	var n: int = int(round(float(total) * f))
	return clampi(n, 0, total - 1)


## Accept an axis value only if it names something we actually build. Lower-cased
## and stripped; anything unrecognised is a typo in a map token and falls back to
## the current value rather than stranding the placement with an empty field.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


# ── Build ─────────────────────────────────────────────────────────────

## TWO EMITTERS, ONE FIELD. A GPUParticles3D has exactly one material_override
## across every particle it owns — the same limit a MultiMeshInstance3D has, and
## for the same reason: there is no per-instance material to reach for. Splitting
## the population across two emitters is therefore the ONLY way this artifact can
## hold more than one surface, and it costs nothing: the total particle count, the
## emission volume, the drift and the mesh are all identical to the single-emitter
## build, and the two share one Mesh resource.
##
## Both scatter from a fixed seed, so the same density value still builds the
## same picture twice — the beads sit at FIELD_SEED + 977 rather than at
## FIELD_SEED, or they would land inside the glow motes one for one.
func _build_field() -> void:
	var total: int = _resolved_count()
	var beads: int = _resolved_bead_count(total)
	var glow: int = maxi(1, total - beads)
	# One Mesh, two emitters. The bead is the same sphere at the same radius as
	# the mote beside it — this splits the finish, not the shape.
	var shared: Mesh = _make_sphere_mesh()

	_particles = _spawn_emitter("SphereField", glow, 0, shared,
		_make_glow_material(), _make_process_material(false))
	if beads > 0:
		_spawn_emitter("SphereFieldBeads", beads, 977, shared,
			_make_bead_material(), _make_process_material(true))


func _spawn_emitter(node_name: String, amount: int, seed_offset: int, mesh: Mesh,
		mat: Material, proc: ParticleProcessMaterial) -> GPUParticles3D:
	var p: GPUParticles3D = GPUParticles3D.new()
	p.name = node_name
	p.amount = maxi(1, amount)
	p.lifetime = lifetime
	p.preprocess = lifetime          # fill the volume at t=0 (VR + capture)
	p.explosiveness = 0.0
	p.randomness = 1.0
	p.fixed_fps = 30
	p.position = volume_offset
	# Fixed scatter: the same value must build the same picture twice. Set through
	# set() and guarded, so an engine without the property is a no-op rather than
	# a parse error.
	if "use_fixed_seed" in p:
		p.set("use_fixed_seed", true)
		p.set("seed", FIELD_SEED + seed_offset)
	# Generous visibility AABB so Godot never frustum-culls the whole
	# emitter when the player's view doesn't include its centroid — the
	# same sparse-lattice gotcha floating_primitives documents.
	p.visibility_aabb = AABB(
		-bounds - Vector3(2, 2, 2),
		(bounds + Vector3(2, 2, 2)) * 2.0)

	p.process_material = proc
	p.draw_pass_1 = mesh
	p.material_override = mat
	# Shadow casting lives on the GeometryInstance (the particles node),
	# not on the material — soft glowing motes shouldn't cast shadows, and
	# neither should a bead the size of a marble.
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	add_child(p)
	_spawned.append(p)
	return p


func _make_process_material(bead: bool) -> ParticleProcessMaterial:
	var pm := ParticleProcessMaterial.new()
	# Box emission filling the play volume.
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = bounds
	# Near-weightless: a faint upward float, no hard gravity.
	pm.gravity = Vector3(0.0, float_bias, 0.0)
	# Gentle omnidirectional drift.
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 180.0
	pm.initial_velocity_min = drift_speed * 0.4
	pm.initial_velocity_max = drift_speed
	pm.damping_min = 0.0
	pm.damping_max = 0.4
	# Per-sphere size spread.
	pm.scale_min = scale_min
	pm.scale_max = scale_max
	# Organic wander.
	if turbulence > 0.0:
		pm.turbulence_enabled = true
		pm.turbulence_noise_strength = turbulence
		pm.turbulence_noise_scale = 1.8
		pm.turbulence_noise_speed_random = 0.4
	# Soft fade-in / fade-out over life via an alpha ramp so spheres
	# never pop in or out — key to the "barely there" reading.
	pm.color = color
	pm.alpha_curve = _make_alpha_curve_texture()
	# PER-MOTE COLOUR. This is the only per-instance channel a particle system
	# has, and until now the field ignored it: every mote shipped at exactly
	# `color`, which is most of why a lint measured the whole thing as one flat
	# value. The ramp is sampled at a random position per particle and MULTIPLIES
	# `color`, so it is written as a set of modulators around 1.0 rather than as
	# absolute colours — `color` still governs the field's hue, and a placement
	# that recolours the field still gets its own colour back.
	pm.color_initial_ramp = _make_initial_color_ramp(bead)
	return pm


func _make_alpha_curve_texture() -> CurveTexture:
	# 0 → fade up → hold → fade down → 0 across the particle's life.
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.18, 1.0))
	curve.add_point(Vector2(0.82, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	var tex := CurveTexture.new()
	tex.curve = curve
	return tex


func _make_sphere_mesh() -> Mesh:
	var r: float = _resolved_radius()
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	# Tessellation follows the mote's screen size. A 0.10 m sphere at `scarce` is
	# read as a shape and earns its silhouette; a 0.026 m one in `fog` is a few
	# pixels of glow and paying 12 x 6 for it 400 times is waste, not fidelity.
	if r >= 0.08:
		m.radial_segments = 16
		m.rings = 8
	elif r >= 0.045:
		m.radial_segments = 12
		m.rings = 6
	else:
		m.radial_segments = 8
		m.rings = 4
	return m


## The glow mote: still light, but light with a top and a bottom.
##
## UNSHADED is not negotiable here — an additive mote that took real lighting
## would go dark in the void it exists to furnish. But unshaded means the sphere
## has no shading at all, which is precisely the reading a lint measured as flat:
## a couple of hundred perfect discs of one value. The ramp is the shading, paid
## for once as a 4 x 32 texture instead of per-pixel.
##
## It goes in BOTH albedo and emission because `unshaded` decides between those
## two paths inside Godot's generated shader, and the mote must carry its gradient
## whichever one runs. EMISSION_OP_MULTIPLY, never ADD — the default operator adds
## the texture to the emission colour, which would brighten the field instead of
## sculpting it, and lesson six of this pass is that emissive is already loud.
func _make_glow_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var ramp: ImageTexture = _mote_ramp_texture()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.albedo_texture = ramp
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_texture = ramp
	mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	mat.emission_energy_multiplier = emission_energy
	# Mipmaps are the whole reason the ramp is 32 rows — see RAMP_ROWS. Plain
	# linear, not anisotropic: a mote is never seen at a grazing angle, it is a
	# ball, and the extra taps buy nothing on four columns of grey.
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.vertex_color_use_as_albedo = true
	# Additive + transparent so spheres glow and layer instead of
	# occluding each other or the artifacts behind them.
	if additive:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return mat


## The bead: the same sphere at the same radius, finished as matter.
##
## Everything the glow mote cannot have. It is shaded, so it turns under the
## room's key light; opaque, so it occludes what is behind it; dielectric with a
## clear coat, so it carries a specular lobe that moves as the player walks. That
## lobe is the point — a mote at one value forever is what the lint measured, and
## a highlight that travels is the cheapest honest answer to it.
##
## Albedo is the field's own colour pulled down about a quarter. Two reasons, and
## both are arithmetic rather than taste: a bead must read DIMMER than the light
## beside it or it is just a badly drawn mote, and the per-mote modulator reaches
## 1.34x, which would clip a 1.0 blue channel to white. Pulled down, the brightest
## bead lands near 0.96 and the field keeps its colour instead of blowing out.
##
## ONE darkening only. The albedo choice is it. There is no grime multiply, no AO
## map and no baked wear here, because three subtle darkenings agree on black and
## a third of this field would have quietly become a hole in the room.
func _make_bead_material() -> StandardMaterial3D:
	var r: float = _resolved_radius()
	var base: Color = color.darkened(0.28)
	var mat: StandardMaterial3D = PBR.hard_plastic(base, 0.62, 0.04)
	# GRAIN SCALE, decided in pixels. PbrKit's triplanar is metric, so the kit's
	# default tiling of 5/m puts half a noise period across a 0.11 m mote — one
	# flat colour, which is the flatness this pass exists to remove. Its rule of
	# thumb (1 / longest dimension) overshoots just as badly in the other
	# direction; see BEAD_GRAIN_FACTOR for the pixel count. REF/r keeps the
	# FEATURE COUNT fixed across the density axis instead of the feature size, so
	# a fat `scarce` bead and a fine `fog` bead are the same material seen from
	# two distances rather than two different materials.
	PBR.scale_detail(mat, BEAD_GRAIN_FACTOR * (MOTE_REF_RADIUS / maxf(r, 0.001)))
	# The luminous core. Set at the mote ramp's own floor so the two populations
	# share one bottom value: with the lights off, a bead sits exactly where the
	# dark hem of the mote beside it sits, and the field has a single floor rather
	# than a bright half and a missing half.
	mat.emission_enabled = true
	mat.emission = base.darkened(1.0 - RAMP_FLOOR)
	mat.emission_energy_multiplier = maxf(emission_energy * BEAD_EMISSION, 0.0)
	return mat


# ── Surface textures ──────────────────────────────────────────────────

## The mote's light-to-shade ramp: peak at the +Y pole, floor at the -Y pole.
##
## SphereMesh puts v = 0 at the top pole, and Godot samples image row 0 at v = 0,
## so row 0 is the peak and the last row is the floor. Particles here are not
## billboarded or spun (transform_align is disabled and angular velocity is zero),
## so every mote in the field agrees about which way is up and the whole
## population reads as lit from above by the same room.
##
## Half-float, because the peak is 1.16 and an RGB8 texture would clip it. The
## profile is t^(1/RAMP_EXPONENT) with t = 1 at the top, whose mean over the ball
## is exactly RAMP_EXPONENT/(RAMP_EXPONENT+1) = 0.6 — that is where the 0.944
## brightness parity quoted up at RAMP_PEAK comes from, and it is checkable:
## change either constant and the field's shipped brightness moves.
##
## RGBAH is also linear by construction, so nothing here gets an accidental sRGB
## round trip on its way into albedo.
static func _mote_ramp_texture() -> ImageTexture:
	if _mote_ramp != null:
		return _mote_ramp
	var img: Image = Image.create(4, RAMP_ROWS, false, Image.FORMAT_RGBAH)
	var span: float = RAMP_PEAK - RAMP_FLOOR
	var inv: float = 1.0 / maxf(RAMP_EXPONENT, 0.01)
	for row in range(RAMP_ROWS):
		var t: float = 1.0 - float(row) / float(maxi(RAMP_ROWS - 1, 1))
		var v: float = RAMP_FLOOR + span * pow(t, inv)
		var c: Color = Color(v, v, v, 1.0)
		for col in range(4):
			img.set_pixel(col, row, c)
	img.generate_mipmaps()
	_mote_ramp = ImageTexture.create_from_image(img)
	return _mote_ramp


## Per-mote variation — the other half of the finish, and the half that only a
## field can have. A single object gets its material read from its surface; a
## couple of hundred motes four pixels wide get theirs from being DIFFERENT FROM
## EACH OTHER. This is a GPUParticles3D, so there is no per-instance material to
## reach for; `color_initial_ramp` is the one per-particle channel that exists.
##
## Written as MODULATORS around 1.0, not as colours. Godot multiplies this into
## the process material's `color`, so a placement that recolours the field still
## gets its own hue back — this only decides how far each mote sits from it.
##
## Every channel's mean is exactly 1.0 by construction: with linear interpolation
## and stops at 0.0 / 0.5 / 1.0, the mean of a uniformly sampled ramp is
## (lo + 2*mid + hi) / 4, and each triple below sums to 4.0. The field therefore
## gains a two-to-three-to-one spread between motes and loses nothing in average
## brightness — which is the only reason it can be applied to 75 live placements.
##
## Dim motes lean cool and bright ones lean warm, so the spread reads as depth in
## the room rather than as a flicker in the exposure.
func _make_initial_color_ramp(bead: bool) -> GradientTexture1D:
	var lo: Color = Color(0.50, 0.55, 0.62)
	var mid: Color = Color(1.00, 1.00, 1.00)
	var hi: Color = Color(1.50, 1.45, 1.38)
	if bead:
		# Tighter. A bead already has a dark side from real shading, and stacking
		# a wide albedo spread on top of that is the third darkening this file is
		# careful not to take.
		lo = Color(0.66, 0.70, 0.80)
		hi = Color(1.34, 1.30, 1.20)
	# A default Gradient already has two stops: 0 black, 1 white. Add the midpoint
	# and tint the ends in place — em_environment learned the hard way that
	# reassigning `offsets` and `colors` as whole arrays transiently mismatches
	# their lengths.
	var g := Gradient.new()
	g.add_point(0.5, mid)
	g.set_color(0, lo)
	g.set_color(2, hi)
	var tex := GradientTexture1D.new()
	# HDR: the bright stop is above 1.0 and an RGBA8 gradient would clamp it,
	# which would drop the mean below 1.0 and quietly dim all 75 placements.
	tex.use_hdr = true
	tex.width = 64
	tex.gradient = g
	return tex


# ── Helpers ───────────────────────────────────────────────────────────

func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	var a := 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(float(parts[0]), float(parts[1]), float(parts[2]), a)


func _parse_vec3(s: String, fallback: Vector3) -> Vector3:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
