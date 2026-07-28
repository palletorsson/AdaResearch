extends Node3D
class_name FloatingSphereField

# @identity
# essence: a sparse field of soft glowing spheres drifting in the void around the player — the SUBTLE successor to the Kusama dot-grid. Where the grid asserted a rigid lattice ("the grid IS the aesthetic"), this is the grid exhaled: the same "forms exist in space before they have shape" reading, but as a few dozen luminous motes hanging in air, breathing on a slow drift instead of snapping to coordinates.
# desire: the field wants to be ATMOSPHERE, not architecture. It should be felt at the edge of vision and never counted. A point-grid says "here is structure"; this says "here is room, and the room is not empty." It wants to make the void legible as a place without filling it.
# critical_parameter: sphere_count — the entire reading hinges on sparsity. A few dozen (~40) reads as "a presence in the air"; a few hundred reads as fog or snow and the subtlety collapses. Sparse is the point. The Kusama grid was overwhelming-by-repetition; this is its inverse — presence-by-scarcity.
# triggers: _ready() builds one GPUParticles3D with a ParticleProcessMaterial (box emission volume), a small SphereMesh draw pass, and an additive emissive override; preprocess fills the volume at t=0 so it reads immediately. apply_grid_config rebuilds from DNA.
# emerges: low count + large bounds + slow drift = "ambient field, barely there"; raise emission and tighten bounds and it becomes "a swarm of fireflies"; kill drift and it freezes into a soft 3D starfield.
# needs: GPUParticles3D [present]; box emission volume sized to the play space [present]; sphere draw pass [present]; additive emissive material so spheres glow not occlude [present]; preprocess so the field is full on the first frame (VR + capture) [present]
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
@export var additive: bool = true

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
			and color.is_equal_approx(before_color):
		return

	_rebuild_now()
	print("[FloatingSphereField] Config applied — density=%s, spheres=%d, radius=%.3f" % [
		density, _resolved_count(), _resolved_radius()])


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


## Accept an axis value only if it names something we actually build. Lower-cased
## and stripped; anything unrecognised is a typo in a map token and falls back to
## the current value rather than stranding the placement with an empty field.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build_field() -> void:
	var count: int = _resolved_count()

	_particles = GPUParticles3D.new()
	_particles.name = "SphereField"
	_particles.amount = count
	_particles.lifetime = lifetime
	_particles.preprocess = lifetime          # fill the volume at t=0 (VR + capture)
	_particles.explosiveness = 0.0
	_particles.randomness = 1.0
	_particles.fixed_fps = 30
	_particles.position = volume_offset
	# Fixed scatter: the same value must build the same picture twice. Set through
	# set() and guarded, so an engine without the property is a no-op rather than
	# a parse error.
	if "use_fixed_seed" in _particles:
		_particles.set("use_fixed_seed", true)
		_particles.set("seed", FIELD_SEED)
	# Generous visibility AABB so Godot never frustum-culls the whole
	# emitter when the player's view doesn't include its centroid — the
	# same sparse-lattice gotcha floating_primitives documents.
	_particles.visibility_aabb = AABB(
		-bounds - Vector3(2, 2, 2),
		(bounds + Vector3(2, 2, 2)) * 2.0)

	_particles.process_material = _make_process_material()
	_particles.draw_pass_1 = _make_sphere_mesh()
	_particles.material_override = _make_glow_material()
	# Shadow casting lives on the GeometryInstance (the particles node),
	# not on the material — soft glowing motes shouldn't cast shadows.
	_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	add_child(_particles)
	_spawned.append(_particles)


func _make_process_material() -> ParticleProcessMaterial:
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


func _make_glow_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = emission_energy
	mat.vertex_color_use_as_albedo = true
	# Additive + transparent so spheres glow and layer instead of
	# occluding each other or the artifacts behind them.
	if additive:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return mat


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
