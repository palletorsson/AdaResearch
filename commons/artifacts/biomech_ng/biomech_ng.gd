extends Node3D
class_name BioMechNG

# @identity
# essence: a single DNA-driven BIOMECH NG SPECIMEN — the NON-PRIMITIVE sibling of
#   biomech. Where biomech stacks spheres/boxes/cylinders into four cyborgs, BioMechNG
#   GROWS each body from generated SURFACES: lofted swept tubes, marching-cubes
#   isosurfaces, Gielis superformula shells, and procedurally-paneled revolution
#   armour. Depending on its `mode` DNA it becomes one of four flesh-and-machine
#   organisms whose skin is a true continuous surface, not an assembly of parts:
#   serpentloft (a rearing serpent whose whole body is ONE continuous swept tube —
#   an elliptical cross-section lofted along a parametric rearing-coil path with a
#   muscle-pulsed radius and ridged-noise skin, a row of metal vertebra plates
#   marching the same path, bezier cables drooping off the flanks, feelers reaching
#   off the neck, a glowing-eyed head pod lunging at the tip), fusion (flesh melting
#   into metal as ONE watertight marching-cubes skin — a clustered flesh organism
#   smooth-unioned with a dorsal steel carapace into a single field, the seam graded
#   per-vertex and lerped by a spatial shader so the boundary is a smooth melt, a
#   glowing core socketed in the chest, eyes on the head lobe, emissive veins tracing
#   the seam, four bezier legs), carapace (a Gielis-superformula shell creature — the
#   spherical product of two mismatched-symmetry superformulae yields a compound-curved
#   biomech carapace primitives cannot express, a recessed glow core port, six bezier
#   legs, a multi-tube sensor neck with a little superformula cranium, a dorsal ridge
#   of studs), and mech (procedural hard-surface paneling — a revolution shell wearing
#   inset/extruded/bevelled armor plates, convex-hull armor chunks, scattered greebles,
#   a flesh underbelly showing through the panel seams, a glowing optic head, four
#   multi-tube legs). It is the body confessing it was always partly grown, and the
#   surface confessing it was always partly machined.
# desire: it wants the FLESH to read as soft living tissue (subsurface scatter,
#   backlight, faint vein glow — kept DEEP RED, never the pale salmon that washes out
#   under SSS), the METAL to read as lit steel (an emission floor so the dark chassis
#   is form, not silhouette), and the CORES / EYES / VEINS to GLOW. Above all it wants
#   the SEAM where soft surface flows into hard surface — the melt band of the fusion
#   skin, the plate that floats proud of the curved shell, the vertebra half-buried in
#   the lofted flesh.
# critical_parameter: mode + seed + the colour triad (color_a FLESH / color_b METAL /
#   accent GLOW) + complexity. mode picks the surface-generation lineage; seed varies
#   the individual deterministically (a local seeded RNG, no global randf/randi ever);
#   complexity scales detail and, for the fusion mode, the marching-cubes resolution.
# triggers: _ready() reads DNA metadata overrides, seeds the RNG from `seed`, and
#   branches on `mode` to a _build_<mode>() helper; apply_grid_config rewrites config
#   metas, clears children (remove BEFORE free, guarded by `_built`), and rebuilds.
# emerges: a row of these reads as a BESTIARY OF GENERATED FUSIONS — four ways a body
#   can be grown half-machine from surfaces rather than bolted together from parts.
#   Switch one mode and the room's idea of "what a surface is" shifts; reseed and the
#   specimen persists while its individual varies.
# needs: a seeded RNG for deterministic individuals [present]; four build branches each
#   using the morphology toolkit (MorphoSweep / MorphoPrimitive / MorphoModifier) for
#   surface generation [present]; flesh / metal / glow materials matching biomech's
#   proven recipes, driven by the colour triad [present]; the fusion shader on a
#   permanent path the fusion branch preloads [present]; bottom-centre floor origin.
# relationships: non-primitive counterpart to biomech (same genome shape + conventions;
#   biomech assembles primitives, biomech_ng grows surfaces); kin to the nature_system
#   morphology engine it is built on (MorphoPrimitive / MorphoSweep / MorphoModifier);
#   cousin to surreal_lab (both are mode-switchboards of one genome).
# truth: flesh and machine were never a clean border, and neither were "part" and
#   "surface". biomech_ng holds four organisms in one genome where the body is GROWN —
#   a tube lofted, a field marched, a superformula resolved, a shell paneled — and lets
#   a single parameter choose which generated fusion the viewer is invited to read. The
#   soft must stay soft, the steel must stay lit, the core must burn, and the seam
#   where surface meets surface is the whole point.

## A multi-mode generative biomech specimen grown from NON-PRIMITIVE surfaces.
##
## The non-primitive sibling of `biomech`. Built procedurally from DNA exports.
## Origin is at the BOTTOM CENTRE of the piece (floor-resting, Y up); it reads
## from +Z. The `mode` export selects one of FOUR surface-generation vocabularies,
## each ported faithfully from a verified trial:
## serpentloft (one continuous lofted swept-tube serpent + metal vertebra plates +
## bezier cables/feelers + glowing head pod), fusion (flesh+metal as one
## marching-cubes isosurface with a smooth per-vertex seam shader + socketed core +
## eyes + veins + legs), carapace (a Gielis superformula shell creature + recessed
## glow port + bezier legs + multi-tube sensor head + ridge studs), mech (a paneled
## revolution shell: inset/extrude/bevel plates + convex-hull armor + greebles +
## flesh underbelly + glowing optic + multi-tube legs).
##
## A seeded RNG makes every individual deterministic from its `seed`. The colour
## triad (color_a FLESH / color_b METAL / accent GLOW) re-registers the same anatomy
## between palettes. Shared material + geometry helpers live under the `_bng_` prefix.
## All surface generation REUSES the morphology toolkit statics (MorphoPrimitive,
## MorphoSweep, MorphoModifier) — no geometry is re-implemented here.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Form")
## serpentloft | fusion | carapace | mech
@export var mode: String = "serpentloft"
## Deterministic seed — same seed always yields the same form.
@export var seed: int = 0
## Detail / element count (vertebrae, legs, panels, veins scale with this). For the
## fusion mode it also scales marching-cubes resolution (4..8 -> ~44..60).
@export var complexity: int = 6
## Overall height in meters (nominal full height of the creature).
@export var sculpt_height: float = 1.6
## Footprint width scale in meters (1.0 = native trial proportions).
@export var sculpt_width: float = 1.0

@export_group("Material")
## FLESH primary — body / abdomen / segments / shell / underbelly. Keep it DEEP red:
## a light salmon washes pale under subsurface scattering.
@export var color_a: Color = Color(0.60, 0.11, 0.13)
## METAL primary — vertebrae / carapace / armour / legs / struts.
@export var color_b: Color = Color(0.13, 0.15, 0.18)
## GLOW — cores / eyes / veins / optic.
@export var accent: Color = Color(0.35, 0.95, 0.95)
@export var metallic_amt: float = 0.85
@export var rough_amt: float = 0.40
## Boost emissive energies (glow reads hotter when true).
@export var emissive: bool = true
## Surface FINISH — the material register. "matte" is the default living-tissue +
## lit-steel look. "latex" (a.k.a "wet"/"fetish") makes the skin a glossy wet
## latex/patent membrane (clearcoat sheen, low roughness, oil-slick iridescent rim)
## and the metal a chrome/patent shell — a queer/bio/fetish materiality where the
## boundary between body and gear is a question of finish, not just colour.
@export var finish: String = "matte"

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _rng := RandomNumberGenerator.new()

# Cool-steel emission-floor tint blended into the metal so it never reads black.
const _STEEL_TINT: Color = Color(0.16, 0.30, 0.34)
# Cool steel highlight used in the carapace metal emission lerp.
const _STEEL_SHEEN: Color = Color(0.40, 0.46, 0.56)
# Permanent path of the moved fusion seam shader (loaded by the fusion mode).
const _FUSION_SHADER_PATH: String = "res://commons/artifacts/biomech_ng/fusion.gdshader"


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k: Variant in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c: Node in get_children():
			remove_child(c)
			c.queue_free()
		_built = false
	_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_mode"):
		mode = str(get_meta("config_mode")).to_lower().strip_edges()
	if has_meta("config_seed"):
		seed = int(str(get_meta("config_seed")))
	if has_meta("config_complexity"):
		complexity = int(str(get_meta("config_complexity")))
	if has_meta("config_sculpt_height"):
		sculpt_height = float(str(get_meta("config_sculpt_height")))
	if has_meta("config_sculpt_width"):
		sculpt_width = float(str(get_meta("config_sculpt_width")))
	if has_meta("config_color_a"):
		color_a = _parse_color(str(get_meta("config_color_a")), color_a)
	if has_meta("config_color_b"):
		color_b = _parse_color(str(get_meta("config_color_b")), color_b)
	if has_meta("config_accent"):
		accent = _parse_color(str(get_meta("config_accent")), accent)
	if has_meta("config_metallic_amt"):
		metallic_amt = float(str(get_meta("config_metallic_amt")))
	if has_meta("config_rough_amt"):
		rough_amt = float(str(get_meta("config_rough_amt")))
	if has_meta("config_emissive"):
		emissive = str(get_meta("config_emissive")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_finish"):
		finish = str(get_meta("config_finish")).to_lower().strip_edges()


## True when the queer/bio/fetish wet-latex material register is selected.
func _bng_is_latex() -> bool:
	return finish == "latex" or finish == "wet" or finish == "fetish"


## Accepts an "r,g,b" / "r,g,b,a" string OR a colour name ("red", "cyan", …).
func _parse_color(raw: String, fallback: Color) -> Color:
	var s := raw.strip_edges()
	var parts := s.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	# Try a named colour (Godot's Color(name) constructor handles HTML + names).
	var named := Color(s.to_lower())
	if named != Color(0, 0, 0, 1) or s.to_lower() in ["black", "#000000", "000000"]:
		return named
	return fallback


# ── Build dispatch ─────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	_rng.seed = seed
	match mode:
		"serpentloft":
			_build_serpentloft()
		"fusion":
			_build_fusion()
		"carapace":
			_build_carapace()
		"mech":
			_build_mech()
		_:
			# Unknown mode falls back to the serpentloft vocabulary.
			_build_serpentloft()


# ── Shared `_bng_` material helpers (biomech's proven recipes, DNA-driven) ──────

## Energy multiplier for emissive elements, lifted when `emissive` is on.
func _bng_glow_energy(base: float) -> float:
	return base * (1.0 if emissive else 0.6)


## Soft organic FLESH (color_a family): subsurface scattering + a touch of backlight
## + a faint emissive vein floor in the flesh's OWN deep tone, so the tissue reads as
## soft and wet and never collapses to flat black or washes pale. `c` is the surface
## tint; `vein` is the inner-glow tint (defaults to `accent`).
func _bng_flesh_mat(c: Color, vein: Color = accent) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.88
	m.metallic = 0.0
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.30
	m.emission_enabled = true
	m.emission = c.lerp(vein, 0.12) * 0.7
	m.emission_energy_multiplier = _bng_glow_energy(0.18) if emissive else 0.10
	m.backlight_enabled = true
	m.backlight = c * 0.12
	m.rim_enabled = true
	m.rim = 0.24
	m.rim_tint = 0.5
	if _bng_is_latex():
		# Wet latex / fetish membrane: glossy with a clearcoat coat, tighter SSS
		# (latex is less translucent than raw meat but still reads wet), a hotter
		# own-tone glow, and a sharp wet-edge rim.
		m.roughness = 0.14
		m.subsurf_scatter_strength = 0.16
		m.clearcoat_enabled = true
		m.clearcoat = 0.9
		m.clearcoat_roughness = 0.04
		m.emission_energy_multiplier = _bng_glow_energy(0.26) if emissive else 0.12
		m.rim = 0.55
		m.rim_tint = 0.2
	return m


## EMISSION-FLOOR METAL (color_b family): metallic ≈ metallic_amt, roughness ≈
## rough_amt, with an emission floor of its own tint so dark steel reads as lit steel
## rather than black under flat / unlit capture light. `sheen` shifts the floor toward
## a cool steel highlight.
func _bng_metal_mat(c: Color, sheen: Color = _STEEL_TINT, energy: float = 0.20,
		rough_bias: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.roughness = clampf(rough_amt + rough_bias, 0.02, 1.0)
	m.emission_enabled = true
	m.emission = c.lerp(sheen, 0.6)
	m.emission_energy_multiplier = clampf(energy, 0.0, 1.0)
	m.rim_enabled = true
	m.rim = 0.4
	m.rim_tint = 0.5
	if _bng_is_latex():
		# Patent / chrome: a mirror-smooth wet shell with a clearcoat sheen.
		m.metallic = clampf(maxf(metallic_amt, 0.9), 0.0, 1.0)
		m.roughness = clampf(0.05 + rough_bias, 0.02, 1.0)
		m.clearcoat_enabled = true
		m.clearcoat = 0.7
		m.clearcoat_roughness = 0.05
		m.rim = 0.6
	return m


## Bright GLOW (accent family): saturated near-unshaded emission for cores, eyes,
## veins, optics. `energy` ~2-6; alpha < 1.0 turns on alpha transparency (halos).
func _bng_glow_mat(c: Color, energy: float = 3.0, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = _bng_glow_energy(energy)
	return m


## Soft rubbery cable / tendon (dark, matte, faint floor). Used by serpentloft cables.
func _bng_cable_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.10, 0.11, 0.13)
	m.metallic = clampf(metallic_amt * 0.8, 0.0, 1.0)
	m.roughness = clampf(rough_amt + 0.15, 0.02, 1.0)
	m.emission_enabled = true
	m.emission = Color(0.10, 0.11, 0.13)
	m.emission_energy_multiplier = 0.16
	return m


# ── Shared `_bng_` geometry helpers ────────────────────────────────────

## A Basis with +Y aligned to `up` (stable near-vertical and near-horizontal).
func _bng_basis_from_up(up: Vector3) -> Basis:
	var y: Vector3 = up.normalized()
	var ref: Vector3 = Vector3.RIGHT if absf(y.dot(Vector3.UP)) > 0.95 else Vector3.UP
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


## Wrap a Mesh in a MeshInstance3D with material + local transform, parented to `parent`.
func _bng_add_mesh(parent: Node3D, mesh: Mesh, mat: Material,
		xform: Transform3D = Transform3D.IDENTITY, node_name: String = "Part") -> MeshInstance3D:
	if mesh == null:
		return null
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xform
	parent.add_child(mi)
	return mi


## A small sphere helper (SphereMesh) at `pos`.
func _bng_sphere(parent: Node3D, radius: float, pos: Vector3, mat: Material,
		rings: int = 8, segs: int = 12) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = radius
	sph.height = radius * 2.0
	sph.radial_segments = segs
	sph.rings = rings
	return _bng_add_mesh(parent, sph, mat, Transform3D(Basis.IDENTITY, pos), "Sphere")


## Compute the world AABB of a node subtree (for footing the creature at y=0).
func _bng_subtree_aabb(node: Node3D) -> AABB:
	var total := AABB()
	var first: bool = true
	var stack: Array = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is MeshInstance3D and (current as MeshInstance3D).mesh != null:
			var mi := current as MeshInstance3D
			var a: AABB = mi.global_transform * mi.get_aabb()
			if first:
				total = a
				first = false
			else:
				total = total.merge(a)
		for child: Node in current.get_children():
			stack.append(child)
	return total


## Translate `body` so its lowest point sits at y=0 and its horizontal centre is at
## the origin (footed and centred for the AABB capture frame). Optionally rescale the
## whole subtree first so it stands ~target_h tall.
func _bng_settle_to_ground(body: Node3D, target_h: float = 0.0, width_scale: float = 1.0) -> void:
	if target_h > 0.0:
		var raw: AABB = _bng_subtree_aabb(body)
		var span_y: float = maxf(raw.size.y, 0.001)
		var k: float = target_h / span_y
		body.scale = Vector3(k * width_scale, k, k * width_scale)
	var aabb: AABB = _bng_subtree_aabb(body)
	if aabb.size == Vector3.ZERO:
		return
	var centre: Vector3 = aabb.get_center()
	body.position += Vector3(-centre.x, -aabb.position.y, -centre.z)


# =============================================================================
# MODE: serpentloft — one continuous lofted swept-tube serpent (trial v1)
# =============================================================================

const _SERP_BODY_SEGMENTS: int = 220   # rings along the path (smooth loft)
const _SERP_PROFILE_SIDES: int = 18    # fleshy cross-section
const _SERP_PROFILE_ASPECT: float = 0.86  # slightly elliptical (belly flatter)

# Seed-jittered coil parameters baked into locals before the path Callable uses them.
var _serp_coil_radius: float = 0.58
var _serp_coil_turns: float = 1.30
var _serp_coil_phase: float = 0.0
var _serp_rise_height: float = 1.92
var _serp_head_lunge: float = 0.92


func _build_serpentloft() -> void:
	# Seed-jitter the curl so each specimen differs but stays deterministic.
	_serp_coil_radius = 0.58 + _rng.randf_range(-0.05, 0.10)
	_serp_coil_turns = 1.22 + _rng.randf_range(-0.08, 0.16)
	_serp_coil_phase = _rng.randf_range(-0.35, 0.35)
	_serp_rise_height = 1.88 + _rng.randf_range(-0.06, 0.10)
	_serp_head_lunge = 0.88 + _rng.randf_range(-0.06, 0.12)

	# Build into a rig in native space, then foot + scale to sculpt size.
	var rig := Node3D.new()
	rig.name = "Serpentloft"
	add_child(rig)

	# Vertebra count scales with complexity (native 26 at complexity 6).
	var vertebrae: int = clampi(16 + complexity * 2, 18, 40)

	_serp_build_body(rig)
	_serp_build_spine(rig, vertebrae)
	_serp_build_belly_cores(rig)
	_serp_build_cables(rig)
	_serp_build_feelers(rig)
	_serp_build_head(rig)

	# Foot at y=0, centre at origin, and scale the whole serpent to sculpt size.
	_bng_settle_to_ground(rig, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2))


## THE PATH — tail low/back, body rises & coils, rears, head lunges forward + up.
func _serp_path(t: float) -> Vector3:
	var rise: float = _serp_rise_height * smoothstep(0.0, 0.92, t)
	var coil_env: float = sin(clampf(t, 0.0, 1.0) * PI)        # 0→1→0 bell
	var radius_here: float = _serp_coil_radius * (0.32 + 0.68 * coil_env)
	var ang: float = _serp_coil_phase + t * TAU * _serp_coil_turns
	var x: float = cos(ang) * radius_here
	var z: float = sin(ang) * radius_here
	# Tail anchor: pull the very start down and back so it grounds at ~y=0.
	var tail_pull: float = smoothstep(0.18, 0.0, t)
	rise -= tail_pull * 0.18
	# Head lunge: rear the neck up, push the strike forward, final up-kick at the tip.
	var rear: float = smoothstep(0.72, 0.90, t)
	var strike: float = smoothstep(0.86, 1.0, t)
	var kick: float = smoothstep(0.94, 1.0, t)
	rise += rear * 0.46 + strike * 0.20 + kick * 0.26
	z += strike * (_serp_head_lunge * 0.86)
	x += strike * (cos(_serp_coil_phase) * 0.10)
	return Vector3(x, rise, z)


## Pointed tail → thick belly → tapering neck/head, with a muscle-segment pulse.
func _serp_radius(t: float) -> float:
	var tail: float = smoothstep(0.0, 0.10, t)
	var belly: float = pow(sin(clampf(t, 0.0, 1.0) * PI), 0.85)
	var neck: float = lerpf(1.0, 0.46, smoothstep(0.62, 1.0, t))
	var base: float = 0.085 + 0.205 * belly
	base *= tail
	base *= neck
	var pulse: float = 0.018 * sin(t * TAU * 22.0)
	pulse *= tail
	return maxf(base + pulse, 0.012)


## PATH FRAME — centre + orthonormal {tangent, dorsal, side} at param t.
func _serp_path_frame(t: float) -> Dictionary:
	var dt: float = 0.0015
	var t0: float = maxf(t - dt, 0.0)
	var t1: float = minf(t + dt, 1.0)
	var center: Vector3 = _serp_path(t)
	var tangent: Vector3 = (_serp_path(t1) - _serp_path(t0))
	if tangent.length_squared() < 1.0e-6:
		tangent = Vector3.FORWARD
	tangent = tangent.normalized()
	var dorsal: Vector3 = Vector3.UP - tangent * tangent.dot(Vector3.UP)
	if dorsal.length_squared() < 1.0e-4:
		dorsal = Vector3.FORWARD - tangent * tangent.dot(Vector3.FORWARD)
	dorsal = dorsal.normalized()
	var side: Vector3 = tangent.cross(dorsal).normalized()
	dorsal = side.cross(tangent).normalized()
	return {"center": center, "tangent": tangent, "dorsal": dorsal, "side": side}


## BODY — one continuous swept tube + seeded noise skin ripple.
func _serp_build_body(rig: Node3D) -> void:
	var profile: Array[Vector2] = MorphoSweep.profile_ellipse(_SERP_PROFILE_SIDES, _SERP_PROFILE_ASPECT)
	var path_func: Callable = func(t: float) -> Vector3: return _serp_path(t)
	var radius_func: Callable = func(t: float) -> float: return _serp_radius(t)
	var base_mesh: Mesh = MorphoSweep.sweep(
		profile, path_func, radius_func, 36.0, _SERP_BODY_SEGMENTS, false)

	var noise := FastNoiseLite.new()
	noise.seed = int(_rng.randi())
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	noise.fractal_octaves = 4
	noise.frequency = 4.6
	var rippled: ArrayMesh = MorphoModifier.noise_displace(base_mesh, noise, 0.032)
	var body_mesh: Mesh = rippled if rippled != null else base_mesh

	_bng_add_mesh(rig, body_mesh, _bng_flesh_mat(color_a), Transform3D.IDENTITY, "SerpentBody")


## METAL SPINE — vertebra plates marching the SAME path, dorsal side.
func _serp_build_spine(rig: Node3D, vertebra_count: int) -> void:
	var steel := _bng_metal_mat(color_b, _STEEL_TINT, 0.28)
	var spine_root := Node3D.new()
	spine_root.name = "MetalSpine"
	rig.add_child(spine_root)

	for i: int in range(vertebra_count):
		var t: float = lerpf(0.07, 0.86, float(i) / float(maxi(vertebra_count - 1, 1)))
		var frame: Dictionary = _serp_path_frame(t)
		var center: Vector3 = frame["center"]
		var tangent: Vector3 = frame["tangent"]
		var dorsal: Vector3 = frame["dorsal"]
		var side: Vector3 = frame["side"]
		var r: float = _serp_radius(t)
		var plate_pos: Vector3 = center + dorsal * (r * 0.82)

		var bell: float = sin(clampf(t, 0.0, 1.0) * PI)
		var width: float = lerpf(0.045, 0.135, bell)
		var depth: float = lerpf(0.030, 0.072, bell)
		var tall: float = lerpf(0.030, 0.085, bell)
		var bm := BoxMesh.new()
		bm.size = Vector3(width, tall, depth)
		var basis := Basis(side, dorsal, tangent).orthonormalized()
		_bng_add_mesh(spine_root, bm, steel, Transform3D(basis, plate_pos), "Vertebra")

		if i % 3 == 0:
			var rivet := _bng_sphere(spine_root, 0.016,
				plate_pos + dorsal * (tall * 0.5 + 0.01), _bng_glow_mat(accent, 0.55), 4, 8)
			if rivet != null:
				rivet.name = "Rivet"


## BELLY CORES — a few glowing cores set into the ventral side.
func _serp_build_belly_cores(rig: Node3D) -> void:
	var glow := _bng_glow_mat(accent, 3.6)
	var cores_root := Node3D.new()
	cores_root.name = "BellyCores"
	rig.add_child(cores_root)

	var core_count: int = 5
	for i: int in range(core_count):
		var t: float = lerpf(0.20, 0.66, float(i) / float(core_count - 1))
		var frame: Dictionary = _serp_path_frame(t)
		var center: Vector3 = frame["center"]
		var dorsal: Vector3 = frame["dorsal"]
		var r: float = _serp_radius(t)
		var core_pos: Vector3 = center - dorsal * (r * 0.72)
		var rad: float = lerpf(0.030, 0.052, sin(clampf(t, 0.0, 1.0) * PI))
		_bng_sphere(cores_root, rad, core_pos, glow, 6, 12)


## CABLES — bezier_sweep tendrils drooping off the mid-body.
func _serp_build_cables(rig: Node3D) -> void:
	var cable_mat := _bng_cable_mat()
	var cables_root := Node3D.new()
	cables_root.name = "Cables"
	rig.add_child(cables_root)

	var cross: Array[Vector2] = MorphoSweep.profile_circle(7)
	var thin: Array[Vector2] = []
	for v: Vector2 in cross:
		thin.append(v * 0.022)

	var cable_count: int = 4
	for i: int in range(cable_count):
		var t: float = lerpf(0.30, 0.70, float(i) / float(cable_count - 1))
		var frame: Dictionary = _serp_path_frame(t)
		var center: Vector3 = frame["center"]
		var dorsal: Vector3 = frame["dorsal"]
		var side: Vector3 = frame["side"]
		var r: float = _serp_radius(t)
		var sgn: float = 1.0 if (i % 2 == 0) else -1.0
		var anchor: Vector3 = center - dorsal * (r * 0.4) + side * (r * 0.7 * sgn)
		var sway: float = _rng.randf_range(-0.12, 0.12)
		var droop: float = 0.34 + _rng.randf_range(0.0, 0.16)
		var control_points: Array[Vector3] = [
			anchor,
			anchor + side * (0.16 * sgn) + Vector3(sway, -droop * 0.45, sway * 0.5),
			anchor + side * (0.22 * sgn) + Vector3(-sway, -droop * 0.85, 0.08),
			anchor + side * (0.18 * sgn) + Vector3(sway * 0.5, -droop, -0.06),
		]
		var cable_mesh: Mesh = MorphoPrimitive.bezier_sweep(control_points, thin, 14, 0.0)
		_bng_add_mesh(cables_root, cable_mesh, cable_mat, Transform3D.IDENTITY, "Cable")


## FEELERS — short legs/feelers near the head (bezier_sweep).
func _serp_build_feelers(rig: Node3D) -> void:
	var steel := _bng_metal_mat(color_b, _STEEL_TINT, 0.28)
	var feelers_root := Node3D.new()
	feelers_root.name = "Feelers"
	rig.add_child(feelers_root)

	var cross: Array[Vector2] = MorphoSweep.profile_circle(6)
	var neck_t: float = 0.90
	var frame: Dictionary = _serp_path_frame(neck_t)
	var center: Vector3 = frame["center"]
	var tangent: Vector3 = frame["tangent"]
	var dorsal: Vector3 = frame["dorsal"]
	var side: Vector3 = frame["side"]
	var r: float = _serp_radius(neck_t)

	var feeler_count: int = 4
	for i: int in range(feeler_count):
		var sgn: float = 1.0 if (i % 2 == 0) else -1.0
		var pair: int = i / 2
		var fwd_off: float = 0.06 + float(pair) * 0.10
		var base_r: float = 0.030
		var thin: Array[Vector2] = []
		for v: Vector2 in cross:
			thin.append(v * base_r)
		var root_pos: Vector3 = center + tangent * fwd_off + side * (r * 0.65 * sgn) - dorsal * (r * 0.1)
		var jitter: float = _rng.randf_range(-0.04, 0.04)
		var control_points: Array[Vector3] = [
			root_pos,
			root_pos + side * (0.10 * sgn) + tangent * 0.10 + Vector3(0, -0.02, 0),
			root_pos + side * (0.17 * sgn) + tangent * (0.16 + jitter) + Vector3(0, -0.10, 0),
			root_pos + side * (0.19 * sgn) + tangent * (0.20 + jitter) + Vector3(0, -0.20, 0),
		]
		var leg_mesh: Mesh = MorphoPrimitive.bezier_sweep(control_points, thin, 12, 0.0)
		_bng_add_mesh(feelers_root, leg_mesh, steel, Transform3D.IDENTITY, "Feeler")


## HEAD — metal pod at the lunging tip: pod + 2 glowing eyes + sockets + maw + throat.
func _serp_build_head(rig: Node3D) -> void:
	var steel := _bng_metal_mat(color_b, _STEEL_TINT, 0.28)
	var glow := _bng_glow_mat(accent, 4.2)
	var head_root := Node3D.new()
	head_root.name = "HeadPod"
	rig.add_child(head_root)

	var tip_t: float = 1.0
	var aim_t: float = 0.965
	var frame: Dictionary = _serp_path_frame(aim_t)
	var tip: Vector3 = _serp_path(tip_t)
	var tangent: Vector3 = frame["tangent"]
	var dorsal: Vector3 = frame["dorsal"]
	var side: Vector3 = frame["side"]
	var basis := Basis(side, dorsal, tangent).orthonormalized()
	var head_pos: Vector3 = tip + tangent * 0.06

	# Pod: elongated capsule along the strike direction (+Y → tangent).
	var cap := CapsuleMesh.new()
	cap.radius = 0.105
	cap.height = 0.30
	cap.radial_segments = 16
	cap.rings = 6
	var pod_basis := Basis(side, tangent, -dorsal).orthonormalized()
	_bng_add_mesh(head_root, cap, steel, Transform3D(pod_basis, head_pos), "Pod")

	# Brow plate on the dorsal side (mechanical crown).
	var bm := BoxMesh.new()
	bm.size = Vector3(0.17, 0.045, 0.14)
	_bng_add_mesh(head_root, bm, steel,
		Transform3D(basis, head_pos + dorsal * 0.09 + tangent * 0.02), "Brow")

	# Two glowing eyes + steel socket rings.
	for sgn: float in [1.0, -1.0]:
		var eye_pos: Vector3 = head_pos + tangent * 0.10 + side * (0.058 * sgn) + dorsal * 0.03
		_bng_sphere(head_root, 0.034, eye_pos, glow, 6, 12)
		var tm := TorusMesh.new()
		tm.inner_radius = 0.034
		tm.outer_radius = 0.052
		tm.ring_segments = 8
		tm.rings = 14
		var socket_basis := Basis(side, tangent, -dorsal).orthonormalized()
		_bng_add_mesh(head_root, tm, steel, Transform3D(socket_basis, eye_pos), "Socket")

	# Maw: a short cone opening forward, glowing throat inside.
	var maw := CylinderMesh.new()
	maw.top_radius = 0.072
	maw.bottom_radius = 0.020
	maw.height = 0.12
	maw.radial_segments = 14
	var maw_basis := Basis(side, tangent, -dorsal).orthonormalized()
	_bng_add_mesh(head_root, maw, steel,
		Transform3D(maw_basis, head_pos + tangent * 0.165 - dorsal * 0.03), "Maw")
	_bng_sphere(head_root, 0.034, head_pos + tangent * 0.135 - dorsal * 0.03,
		_bng_glow_mat(accent, 2.8), 5, 10)


# =============================================================================
# MODE: fusion — flesh + metal as ONE marching-cubes skin (trial fusion_hero)
# =============================================================================

const _FUSION_FLESH_FLOOR: float = 0.25
const _FUSION_METAL_FLOOR: float = 0.20
const _FUSION_BLEND_WIDTH: float = 0.22


## complexity 4..8 → marching-cubes resolution ~44..60 (clamped; default 6 → ~52).
func _fusion_resolution() -> int:
	var c: int = clampi(complexity, 4, 8)
	var res: int = int(round(lerpf(44.0, 60.0, float(c - 4) / 4.0)))
	return clampi(res, 40, 64)


func _build_fusion() -> void:
	var rig := Node3D.new()
	rig.name = "Fusion"
	add_child(rig)

	# ── FLESH FIELD — a clustered organism, not one ball ──
	const FLESH_K: float = 0.30
	var flesh_centers: Array[Vector3] = []
	var flesh_radii: Array[float] = []
	flesh_centers.append(Vector3(0.16, 0.74, 0.02)); flesh_radii.append(0.45)
	flesh_centers.append(Vector3(0.30, 0.62, 0.20)); flesh_radii.append(0.33)
	flesh_centers.append(Vector3(0.26, 0.58, -0.18)); flesh_radii.append(0.31)
	flesh_centers.append(Vector3(0.06, 0.92, 0.08)); flesh_radii.append(0.33)
	flesh_centers.append(Vector3(0.46, 1.04, 0.12)); flesh_radii.append(0.23)
	flesh_centers.append(Vector3(0.72, 1.36, 0.18)); flesh_radii.append(0.26)
	flesh_centers.append(Vector3(0.74, 1.52, 0.16)); flesh_radii.append(0.16)
	for _i: int in range(2):
		var jc := Vector3(
			lerpf(0.18, 0.46, _rng.randf()),
			lerpf(0.58, 0.94, _rng.randf()),
			lerpf(-0.22, 0.24, _rng.randf()))
		flesh_centers.append(jc)
		flesh_radii.append(lerpf(0.22, 0.29, _rng.randf()))

	var flesh_field: Callable = MorphoPrimitive.sdf_sphere(flesh_centers[0], flesh_radii[0])
	for i: int in range(1, flesh_centers.size()):
		var s: Callable = MorphoPrimitive.sdf_sphere(flesh_centers[i], flesh_radii[i])
		flesh_field = MorphoPrimitive.sdf_smooth_union(flesh_field, s, FLESH_K)

	# ── METAL FIELD — a dorsal ARMOR SHELL the flesh flows over ──
	const METAL_K: float = 0.22
	var carapace_c := Vector3(-0.18, 1.06, 0.00)
	var carapace_h := Vector3(0.22, 0.26, 0.42)
	var spine_c := Vector3(-0.20, 0.86, 0.00)
	var spine_h := Vector3(0.12, 0.50, 0.12)
	var paul_l_c := Vector3(-0.06, 1.16, 0.34)
	var paul_l_h := Vector3(0.18, 0.18, 0.16)
	var paul_r_c := Vector3(-0.06, 1.16, -0.34)
	var paul_r_h := Vector3(0.18, 0.18, 0.16)
	var carapace: Callable = MorphoPrimitive.sdf_box(carapace_c, carapace_h)
	var spine: Callable = MorphoPrimitive.sdf_box(spine_c, spine_h)
	var paul_l: Callable = MorphoPrimitive.sdf_box(paul_l_c, paul_l_h)
	var paul_r: Callable = MorphoPrimitive.sdf_box(paul_r_c, paul_r_h)
	var metal_field: Callable = MorphoPrimitive.sdf_smooth_union(carapace, spine, METAL_K)
	metal_field = MorphoPrimitive.sdf_smooth_union(metal_field, paul_l, METAL_K)
	metal_field = MorphoPrimitive.sdf_smooth_union(metal_field, paul_r, METAL_K)

	# ── FUSION — flesh and metal as one continuous field ──
	const FUSE_K: float = 0.34
	var fused_base: Callable = MorphoPrimitive.sdf_smooth_union(flesh_field, metal_field, FUSE_K)
	var socket_c := Vector3(0.70, 0.84, 0.16)
	var socket_r: float = 0.19
	var socket: Callable = MorphoPrimitive.sdf_sphere(socket_c, socket_r)
	var fused_field: Callable = MorphoPrimitive.sdf_smooth_subtract(fused_base, socket, 0.05)
	var eye_socket_l: Callable = MorphoPrimitive.sdf_sphere(Vector3(0.90, 1.50, 0.36), 0.09)
	var eye_socket_r: Callable = MorphoPrimitive.sdf_sphere(Vector3(0.96, 1.42, 0.18), 0.09)
	fused_field = MorphoPrimitive.sdf_smooth_subtract(fused_field, eye_socket_l, 0.04)
	fused_field = MorphoPrimitive.sdf_smooth_subtract(fused_field, eye_socket_r, 0.04)
	var core_pos := Vector3(0.58, 0.83, 0.14)

	# ── PER-VERTEX BLEND FACTOR — the smooth seam (baked sub-fields + width) ──
	var cf_flesh: Callable = flesh_field
	var cf_metal: Callable = metal_field
	var bw: float = _FUSION_BLEND_WIDTH
	var color_func: Callable = func(p: Vector3) -> Color:
		var d_flesh: float = cf_flesh.call(p) as float
		var d_metal: float = cf_metal.call(p) as float
		var f: float = clampf(0.5 + 0.5 * (d_metal - d_flesh) / bw, 0.0, 1.0)
		return Color(f, 0.0, 0.0)

	# ── MESH THE UNIFIED FIELD (one watertight skin) ──
	var bounds := AABB(Vector3(-0.70, 0.12, -0.74), Vector3(1.74, 1.66, 1.48))
	var resolution: int = _fusion_resolution()
	var fused_mesh: Mesh = MorphoPrimitive.marching_cubes(fused_field, bounds, resolution, color_func)

	# ── ONE SHADER MATERIAL across the whole fused skin ──
	var shader: Shader = load(_FUSION_SHADER_PATH) as Shader
	var fusion_mat := ShaderMaterial.new()
	fusion_mat.shader = shader
	fusion_mat.set_shader_parameter("metal_albedo", color_b)
	fusion_mat.set_shader_parameter("flesh_albedo", color_a)
	fusion_mat.set_shader_parameter("accent", accent)
	fusion_mat.set_shader_parameter("metal_floor", _FUSION_METAL_FLOOR)
	fusion_mat.set_shader_parameter("flesh_floor", _FUSION_FLESH_FLOOR)
	fusion_mat.set_shader_parameter("char_depth", 0.55)
	fusion_mat.set_shader_parameter("char_width", 0.16)
	# Queer / bio / fetish register: wet latex skin + chrome shell + oil-slick rim.
	var latex: bool = _bng_is_latex()
	fusion_mat.set_shader_parameter("wet", 1.0 if latex else 0.0)
	fusion_mat.set_shader_parameter("iridescence", 0.6 if latex else 0.0)
	_bng_add_mesh(rig, fused_mesh, fusion_mat, Transform3D.IDENTITY, "FusedSkin")

	# ── GLOWING CORE in the carved chest socket ──
	var core_sphere := SphereMesh.new()
	core_sphere.radius = 0.13
	core_sphere.height = 0.26
	core_sphere.radial_segments = 24
	core_sphere.rings = 12
	_bng_add_mesh(rig, core_sphere, _bng_glow_mat(accent, 4.0),
		Transform3D(Basis.IDENTITY, core_pos), "Core")
	var pip_sphere := SphereMesh.new()
	pip_sphere.radius = 0.06
	pip_sphere.height = 0.12
	pip_sphere.radial_segments = 16
	pip_sphere.rings = 8
	_bng_add_mesh(rig, pip_sphere, _bng_glow_mat(accent.lerp(Color(0.72, 1.0, 1.0), 0.6), 5.5),
		Transform3D(Basis.IDENTITY, core_pos), "CorePip")

	# ── GLOWING EYES on the head lobe ──
	var eye_mat := _bng_glow_mat(accent.lerp(Color(0.58, 1.0, 1.0), 0.5), 5.0)
	var eye_positions: Array[Vector3] = [
		Vector3(0.84, 1.50, 0.34),
		Vector3(0.90, 1.42, 0.18),
	]
	for ep: Vector3 in eye_positions:
		var eye_sphere := SphereMesh.new()
		eye_sphere.radius = 0.046
		eye_sphere.height = 0.092
		eye_sphere.radial_segments = 14
		eye_sphere.rings = 7
		_bng_add_mesh(rig, eye_sphere, eye_mat, Transform3D(Basis.IDENTITY, ep), "Eye")

	# ── EMISSIVE VEIN CRACKS crossing the seam ──
	var vein_mat := _bng_glow_mat(accent, 2.6)
	var vein_seeds: Array[Vector3] = [
		Vector3(0.16, 1.10, 0.18),
		Vector3(0.10, 0.92, -0.04),
		Vector3(0.26, 1.18, 0.30),
		Vector3(0.04, 1.04, 0.06),
		Vector3(0.30, 1.06, -0.22),
	]
	for vseed: Vector3 in vein_seeds:
		_fusion_add_vein(rig, vseed, fused_field, vein_mat)

	# ── FOUR SHORT LIMBS so it stands as a creature ──
	var leg_mat := _bng_metal_mat(color_b, _STEEL_TINT, _FUSION_METAL_FLOOR)
	_fusion_add_leg(rig, Vector3(0.34, 0.50, 0.28), Vector3(0.60, 0.02, 0.50), leg_mat)
	_fusion_add_leg(rig, Vector3(0.30, 0.50, -0.26), Vector3(0.54, 0.02, -0.50), leg_mat)
	_fusion_add_leg(rig, Vector3(0.00, 0.56, 0.22), Vector3(-0.22, 0.02, 0.46), leg_mat)
	_fusion_add_leg(rig, Vector3(-0.02, 0.56, -0.22), Vector3(-0.26, 0.02, -0.44), leg_mat)

	# Centre horizontally + foot at y=0, then scale to sculpt size.
	_bng_settle_to_ground(rig, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2))


## A chitinous leg as a tapered bezier sweep from hip to foot, with a foot pad.
func _fusion_add_leg(rig: Node3D, hip: Vector3, foot: Vector3, mat: StandardMaterial3D) -> void:
	var mid: Vector3 = hip.lerp(foot, 0.5)
	var outward: Vector3 = Vector3(foot.x - hip.x, 0.0, foot.z - hip.z).normalized()
	var knee: Vector3 = mid + outward * 0.18 + Vector3(0.0, 0.16, 0.0)
	var control: Array[Vector3] = [hip, hip.lerp(knee, 0.6), foot.lerp(knee, 0.5), foot]
	var cross: Array[Vector2] = []
	var sides: int = 7
	var r: float = 0.06
	for si: int in range(sides):
		var a: float = TAU * float(si) / float(sides)
		cross.append(Vector2(cos(a) * r, sin(a) * r))
	var leg_mesh: Mesh = MorphoPrimitive.bezier_sweep(control, cross, 12, 0.0)
	_bng_add_mesh(rig, leg_mesh, mat, Transform3D.IDENTITY, "Leg")
	var pad_box := BoxMesh.new()
	pad_box.size = Vector3(0.12, 0.05, 0.16)
	_bng_add_mesh(rig, pad_box, mat,
		Transform3D(Basis.IDENTITY, Vector3(foot.x, 0.03, foot.z)), "Foot")


## A thin emissive crack crawling along the surface from a seed (multi_tube).
func _fusion_add_vein(rig: Node3D, seed_pos: Vector3, field: Callable,
		mat: StandardMaterial3D) -> void:
	var positions: Array[Vector3] = []
	var radii: Array[float] = []
	var p: Vector3 = _fusion_project_to_surface(seed_pos, field, 6)
	var dir := Vector3(
		lerpf(-1.0, 1.0, _rng.randf()),
		lerpf(-1.0, 1.0, _rng.randf()),
		lerpf(-1.0, 1.0, _rng.randf())).normalized()
	var seg_count: int = 7
	for i: int in range(seg_count):
		positions.append(p)
		var t: float = float(i) / float(seg_count - 1)
		radii.append(lerpf(0.020, 0.006, t))
		var n: Vector3 = _fusion_field_normal(field, p)
		var tangent: Vector3 = (dir - n * dir.dot(n)).normalized()
		if tangent.length_squared() < 0.001:
			tangent = n.cross(Vector3.UP).normalized()
		p = _fusion_project_to_surface(p + tangent * 0.085, field, 4)
		dir = (dir + Vector3(
			lerpf(-0.4, 0.4, _rng.randf()),
			lerpf(-0.4, 0.4, _rng.randf()),
			lerpf(-0.4, 0.4, _rng.randf()))).normalized()
	var vein_mesh: Mesh = MorphoPrimitive.multi_tube(positions, radii, 5)
	_bng_add_mesh(rig, vein_mesh, mat, Transform3D.IDENTITY, "Vein")


func _fusion_field_normal(field: Callable, p: Vector3, eps: float = 0.004) -> Vector3:
	var dx: float = (field.call(p + Vector3(eps, 0, 0)) as float) - (field.call(p - Vector3(eps, 0, 0)) as float)
	var dy: float = (field.call(p + Vector3(0, eps, 0)) as float) - (field.call(p - Vector3(0, eps, 0)) as float)
	var dz: float = (field.call(p + Vector3(0, 0, eps)) as float) - (field.call(p - Vector3(0, 0, eps)) as float)
	var g := Vector3(dx, dy, dz)
	if g.length_squared() < 0.0000001:
		return Vector3.UP
	return g.normalized()


func _fusion_project_to_surface(p: Vector3, field: Callable, iters: int) -> Vector3:
	var q: Vector3 = p
	for _i: int in range(iters):
		var d: float = field.call(q) as float
		var n: Vector3 = _fusion_field_normal(field, q)
		q = q - n * d
	return q


# =============================================================================
# MODE: carapace — a Gielis superformula shell creature (trial v3)
# =============================================================================

const _CARA_R_MAX: float = 6.0


## Carapace flesh material (slightly lower SSS, matching the v3 chitin recipe).
func _cara_flesh_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	m.metallic = 0.0
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.28
	m.emission_enabled = true
	m.emission = c.lerp(accent, 0.10) * 0.7
	m.emission_energy_multiplier = _bng_glow_energy(0.16) if emissive else 0.10
	m.backlight_enabled = true
	m.backlight = c * 0.12
	m.rim_enabled = true
	m.rim = 0.24
	m.rim_tint = 0.5
	if _bng_is_latex():
		# Wet lacquered chitin: a glossy carapace with a clearcoat shell.
		m.roughness = 0.12
		m.subsurf_scatter_strength = 0.14
		m.clearcoat_enabled = true
		m.clearcoat = 0.95
		m.clearcoat_roughness = 0.04
		m.rim = 0.55
		m.rim_tint = 0.2
	return m


## A 6-param superformula set drawn from the seeded RNG, returned as a Dictionary
## keyed for MorphoPrimitive.superformula_body (formula slot 1 or 2 chosen by `slot`).
## `sym_choices` supplies candidate integer symmetries; the two body formulae draw
## from DIFFERENT pools so their m values mismatch (the asymmetric-biomech trick).
func _cara_draw_formula(slot: int, sym_choices: Array[int],
		n1_lo: float, n1_hi: float, n_lo: float, n_hi: float) -> Dictionary:
	var m: float = float(sym_choices[_rng.randi_range(0, sym_choices.size() - 1)])
	var n1: float = _rng.randf_range(n1_lo, n1_hi)
	var n2: float = _rng.randf_range(n_lo, n_hi)
	var n3: float = _rng.randf_range(n_lo, n_hi)
	var a: float = _rng.randf_range(0.9, 1.15)
	var b: float = _rng.randf_range(0.9, 1.15)
	if slot == 1:
		return {"m1": m, "n1_1": n1, "n2_1": n2, "n3_1": n3, "a1": a, "b1": b}
	return {"m2": m, "n1_2": n1, "n2_2": n2, "n3_2": n3, "a2": a, "b2": b}


func _build_carapace() -> void:
	var creature := Node3D.new()
	creature.name = "Carapace"
	add_child(creature)

	# ─── 1. Carapace body (superformula spherical product) ───
	var f1: Dictionary = _cara_draw_formula(1, [4, 5, 6] as Array[int], 0.20, 0.42, 0.7, 1.5)
	var f2: Dictionary = _cara_draw_formula(2, [2, 3, 4] as Array[int], 0.85, 1.25, 0.9, 1.7)
	var body_params: Dictionary = f1.duplicate()
	body_params.merge(f2)
	body_params["scale"] = Vector3(0.70, 0.92, 0.70)
	var body_mesh: Mesh = MorphoPrimitive.superformula_body(body_params, 96, 56)

	var skin_noise := FastNoiseLite.new()
	skin_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	skin_noise.seed = int(_rng.randi())
	skin_noise.frequency = 2.4
	var body_displaced: ArrayMesh = MorphoModifier.noise_displace(body_mesh, skin_noise, 0.035)
	if body_displaced != null:
		body_mesh = body_displaced

	var body_mi := _bng_add_mesh(creature, body_mesh, _cara_flesh_mat(color_a),
		Transform3D(Basis.IDENTITY, Vector3(0.0, 0.92, 0.0)), "CarapaceShell")
	var body_aabb: AABB = body_mi.get_aabb()
	var body_center_local: Vector3 = body_aabb.get_center()
	var body_half_w: float = maxf(body_aabb.size.x, body_aabb.size.z) * 0.5
	var body_world_center: Vector3 = body_mi.position + body_center_local

	# ─── 2. Glow core in a recessed port ───
	var port_dir := Vector3(0.10, 0.18, 1.0).normalized()
	var port_pos: Vector3 = body_world_center + port_dir * (body_half_w * 0.66)
	var ring_mesh: Mesh = MorphoPrimitive.torus(0.035, 0.16, 10, 22)
	var ring_basis := Basis.looking_at(port_dir, Vector3.UP)
	var ring_mat := _bng_metal_mat(color_b.darkened(0.6), _STEEL_SHEEN, 0.05)
	_bng_add_mesh(creature, ring_mesh, ring_mat, Transform3D(ring_basis, port_pos), "CorePort")

	var core_center: Vector3 = port_pos - port_dir * 0.06
	var core_mesh: Mesh = MorphoPrimitive.sphere(0.115, 18, 12)
	_bng_add_mesh(creature, core_mesh, _bng_glow_mat(accent, 4.2),
		Transform3D(Basis.IDENTITY, core_center), "GlowCore")
	var halo_mesh: Mesh = MorphoPrimitive.sphere(0.21, 16, 10)
	_bng_add_mesh(creature, halo_mesh, _bng_glow_mat(accent, 1.2, 0.16),
		Transform3D(Basis.IDENTITY, core_center), "CoreHalo")

	# ─── 3. Splayed limbs (bezier_sweep, metal, tapering) ───
	var leg_count: int = clampi(4 + complexity / 3, 6, 8)
	var legs := Node3D.new()
	legs.name = "Legs"
	creature.add_child(legs)
	var leg_mat := _bng_metal_mat(color_b, _STEEL_TINT, 0.16)
	var foot_y: float = 0.0
	for i: int in range(leg_count):
		var ang: float = TAU * float(i) / float(leg_count) + _rng.randf_range(-0.08, 0.08)
		var dir := Vector3(cos(ang), 0.0, sin(ang))
		var hip: Vector3 = body_world_center + dir * (body_half_w * 0.85) + Vector3(0.0, -0.18, 0.0)
		var knee: Vector3 = hip + dir * 0.42 + Vector3(0.0, 0.16, 0.0)
		var ankle: Vector3 = hip + dir * 0.70 + Vector3(0.0, -0.55, 0.0)
		var tip: Vector3 = hip + dir * 0.86 + Vector3(0.0, -foot_y, 0.0)
		tip.y = foot_y + 0.01
		var ctrl: Array[Vector3] = [hip, knee, ankle, tip]
		var section: Array[Vector2] = _cara_ellipse_section(0.085, 0.06, 8)
		var leg_mesh: Mesh = MorphoPrimitive.bezier_sweep(ctrl, section, 14,
			_rng.randf_range(-25.0, 25.0))
		_bng_add_mesh(legs, leg_mesh, leg_mat, Transform3D.IDENTITY, "Leg_%d" % i)

		var claw_mesh: Mesh = MorphoPrimitive.cone(0.05, 0.16, 7)
		var claw_dir: Vector3 = (tip - ankle).normalized()
		# Cone points +Y by default; align +Y to claw_dir via a stable Basis.
		var aim := _bng_basis_from_up(claw_dir)
		_bng_add_mesh(legs, claw_mesh, leg_mat,
			Transform3D(aim, tip - claw_dir * 0.05), "Claw_%d" % i)

	# ─── 4. Sensor head / neck (multi_tube) with a superformula cranium + eyes ───
	var head := Node3D.new()
	head.name = "Sensor"
	creature.add_child(head)
	var neck_base: Vector3 = body_world_center + Vector3(0.0, body_half_w * 0.70, body_half_w * 0.30)
	var neck_mid: Vector3 = neck_base + Vector3(0.0, 0.30, 0.22)
	var neck_top: Vector3 = neck_base + Vector3(0.0, 0.44, 0.50)
	var neck_positions: Array[Vector3] = [neck_base, neck_mid, neck_top]
	var neck_radii: Array[float] = [0.14, 0.10, 0.075]
	var neck_mesh: Mesh = MorphoPrimitive.multi_tube(neck_positions, neck_radii, 10)
	_bng_add_mesh(head, neck_mesh, _bng_metal_mat(color_b, _STEEL_TINT, 0.18),
		Transform3D.IDENTITY, "Neck")

	var hf1: Dictionary = _cara_draw_formula(1, [4, 5] as Array[int], 0.4, 0.7, 0.9, 1.6)
	var hf2: Dictionary = _cara_draw_formula(2, [7, 8] as Array[int], 0.6, 1.0, 1.0, 2.0)
	var cranium_params: Dictionary = hf1.duplicate()
	cranium_params.merge(hf2)
	cranium_params["scale"] = Vector3(0.115, 0.13, 0.115)
	var cranium_mesh: Mesh = MorphoPrimitive.superformula_body(cranium_params, 48, 28)
	_bng_add_mesh(head, cranium_mesh, _cara_flesh_mat(color_a),
		Transform3D(Basis.IDENTITY, neck_top + Vector3(0.0, 0.04, 0.05)), "Cranium")

	for sgn: int in [-1, 1]:
		var eye_pos: Vector3 = neck_top + Vector3(float(sgn) * 0.075, 0.05, 0.13)
		var eye_mesh: Mesh = MorphoPrimitive.sphere(0.038, 12, 8)
		_bng_add_mesh(head, eye_mesh, _bng_glow_mat(accent.lerp(Color(0.98, 0.72, 0.20), 0.6), 4.5),
			Transform3D(Basis.IDENTITY, eye_pos), "Eye_%d" % (sgn + 1))

	# ─── 5. Biomech ridge / rivet accents on the shell ───
	var accents := Node3D.new()
	accents.name = "Accents"
	creature.add_child(accents)
	var rivet_mat := _bng_metal_mat(color_b, _STEEL_TINT, 0.28)
	var ridge_count: int = 7
	for i: int in range(ridge_count):
		var t: float = float(i) / float(ridge_count - 1)
		var along: float = lerpf(-0.55, 0.55, t)
		var lift: float = body_half_w * (0.78 - 0.10 * absf(along))
		var stud_pos: Vector3 = body_world_center + Vector3(0.0, lift, along)
		var stud_mesh: Mesh = MorphoPrimitive.cone(0.045, 0.11, 6)
		_bng_add_mesh(accents, stud_mesh, rivet_mat,
			Transform3D(Basis.IDENTITY, stud_pos), "Ridge_%d" % i)
	var rivet_count: int = 10
	for i: int in range(rivet_count):
		var ang: float = TAU * float(i) / float(rivet_count)
		var dir := Vector3(cos(ang), 0.0, sin(ang))
		var rivet_pos: Vector3 = body_world_center + dir * (body_half_w * 0.88) + Vector3(0.0, 0.02, 0.0)
		var rivet_mesh: Mesh = MorphoPrimitive.sphere(0.035, 8, 6)
		_bng_add_mesh(accents, rivet_mesh, rivet_mat,
			Transform3D(Basis.IDENTITY, rivet_pos), "Rivet_%d" % i)

	# ─── 6. Foot at y=0, centre at origin, scale to sculpt size ───
	_bng_settle_to_ground(creature, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2))


## A flat ellipse cross-section (binormal=x, normal=y) for limb sweeps.
func _cara_ellipse_section(rx: float, ry: float, sides: int) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for i: int in range(sides):
		var a: float = TAU * float(i) / float(sides)
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts


# =============================================================================
# MODE: mech — procedural hard-surface paneling over a revolution shell (trial v4)
# =============================================================================

## Mech metal material (emission lerps toward _STEEL_TINT at 0.45 like the v4 recipe).
func _mech_metal_mat(albedo: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.roughness = clampf(rough_amt, 0.02, 1.0)
	m.emission_enabled = true
	m.emission = albedo.lerp(_STEEL_TINT, 0.45)
	m.emission_energy_multiplier = clampf(energy, 0.0, 1.0)
	m.rim_enabled = true
	m.rim = 0.4
	m.rim_tint = 0.5
	return m


func _build_mech() -> void:
	var rig := Node3D.new()
	rig.name = "Mech"
	add_child(rig)

	# Body shell profile: Vector2(radius, height). Footed near y=0.06, apex near y=1.58.
	var profile: Array[Vector2] = [
		Vector2(0.04, 0.06),
		Vector2(0.30, 0.14),
		Vector2(0.46, 0.34),
		Vector2(0.56, 0.60),
		Vector2(0.52, 0.86),
		Vector2(0.40, 1.08),
		Vector2(0.30, 1.26),
		Vector2(0.255, 1.40),
		Vector2(0.235, 1.52),
		Vector2(0.20, 1.58),
	]
	var shell_mesh: Mesh = MorphoPrimitive.revolution(profile, 40)
	var metal_core_mat: StandardMaterial3D = _mech_metal_mat(color_b, 0.22)

	# The smooth curved CORE in metal — the substrate the panels sit proud of.
	_bng_add_mesh(rig, shell_mesh, metal_core_mat, Transform3D.IDENTITY, "BodyCore")

	# FLESH UNDERBELLY — a second, smaller noise-displaced revolution peeking through seams.
	_mech_build_underbelly(rig)
	# PROCEDURAL PANELS over the upper/outer body.
	_mech_build_panels(rig, profile)
	# CONVEX-HULL armor chunks as heavier shoulder / back masses.
	_mech_build_hull_armor(rig)
	# GREEBLES — bolts + hex vents oriented to the surface normal.
	_mech_build_greebles(rig, profile)
	# Glow vents / core peeking between the plates.
	_mech_build_glow_core(rig)
	# Sensor head with glowing optic on the narrowed neck.
	_mech_build_head(rig, Vector3(0.0, 1.62, 0.0))
	# Four mechanical legs so it stands, footed at y≈0.
	_mech_build_legs(rig, Vector3(0.0, 0.30, 0.0))

	# Centre + foot + scale to sculpt size.
	_bng_settle_to_ground(rig, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2))


func _mech_build_underbelly(rig: Node3D) -> void:
	var belly: Array[Vector2] = [
		Vector2(0.06, 0.05),
		Vector2(0.31, 0.15),
		Vector2(0.48, 0.36),
		Vector2(0.50, 0.58),
		Vector2(0.36, 0.80),
		Vector2(0.235, 1.00),
		Vector2(0.16, 1.18),
	]
	var belly_mesh: Mesh = MorphoPrimitive.revolution(belly, 28)
	var noise := FastNoiseLite.new()
	noise.seed = int(_rng.randi())
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 2.6
	var skinned: ArrayMesh = MorphoModifier.noise_displace(belly_mesh, noise, 0.035)
	var use_mesh: Mesh = skinned if skinned != null else belly_mesh
	_bng_add_mesh(rig, use_mesh, _bng_flesh_mat(color_a), Transform3D.IDENTITY, "FleshUnderbelly")


func _mech_build_panels(rig: Node3D, profile: Array[Vector2]) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)  # flat shading: keep every face in its own group (no averaging).

	var plate_total: int = clampi(12 + complexity, 16, 24)
	for _i: int in range(plate_total):
		var h: float = _rng.randf_range(0.30, 1.16)
		var ang: float = _rng.randf_range(0.0, TAU)
		var center: Vector3 = _mech_shell_point(profile, ang, h)
		var nrm: Vector3 = _mech_shell_normal(profile, ang, h)
		var tan_v: Vector3 = Vector3.UP - nrm * Vector3.UP.dot(nrm)
		if tan_v.length() < 0.01:
			tan_v = Vector3.FORWARD - nrm * Vector3.FORWARD.dot(nrm)
		tan_v = tan_v.normalized()
		var tan_u: Vector3 = nrm.cross(tan_v).normalized()
		var hu: float = _rng.randf_range(0.11, 0.19)
		var hv: float = _rng.randf_range(0.10, 0.17)
		var lift: float = 0.012
		var base: Vector3 = center + nrm * lift
		var c00: Vector3 = base - tan_u * hu - tan_v * hv
		var c10: Vector3 = base + tan_u * hu - tan_v * hv
		var c11: Vector3 = base + tan_u * hu + tan_v * hv
		var c01: Vector3 = base - tan_u * hu + tan_v * hv
		var inset_amt: float = _rng.randf_range(0.20, 0.34)
		var extrude_amt: float = _rng.randf_range(0.055, 0.10)
		_mech_add_panel(st, c00, c10, c11, c01, nrm, inset_amt, extrude_amt)

	var panels_mesh: ArrayMesh = st.commit()
	_bng_add_mesh(rig, panels_mesh, _mech_metal_mat(color_b.lightened(0.18), 0.20),
		Transform3D.IDENTITY, "ArmorPanels")


## Build one raised, bevelled plate into `st` (top face + 4 bevel walls, flat normals).
func _mech_add_panel(st: SurfaceTool, c00: Vector3, c10: Vector3, c11: Vector3,
		c01: Vector3, nrm: Vector3, inset: float, extrude: float) -> void:
	var centroid: Vector3 = (c00 + c10 + c11 + c01) * 0.25
	var t00: Vector3 = c00.lerp(centroid, inset) + nrm * extrude
	var t10: Vector3 = c10.lerp(centroid, inset) + nrm * extrude
	var t11: Vector3 = c11.lerp(centroid, inset) + nrm * extrude
	var t01: Vector3 = c01.lerp(centroid, inset) + nrm * extrude
	_mech_quad(st, t00, t10, t11, t01, nrm)
	_mech_bevel_wall(st, c00, c10, t10, t00, centroid)
	_mech_bevel_wall(st, c10, c11, t11, t10, centroid)
	_mech_bevel_wall(st, c11, c01, t01, t11, centroid)
	_mech_bevel_wall(st, c01, c00, t00, t01, centroid)


func _mech_bevel_wall(st: SurfaceTool, ba: Vector3, bb: Vector3, tb: Vector3,
		ta: Vector3, centroid: Vector3) -> void:
	var nrm: Vector3 = (bb - ba).cross(ta - ba)
	if nrm.length() < 0.0001:
		nrm = (ba - centroid)
	nrm = nrm.normalized()
	var mid: Vector3 = (ba + bb + tb + ta) * 0.25
	if nrm.dot(mid - centroid) < 0.0:
		nrm = -nrm
	_mech_quad(st, ba, bb, tb, ta, nrm)


func _mech_quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
		nrm: Vector3) -> void:
	st.set_normal(nrm); st.set_uv(Vector2(0, 0)); st.add_vertex(p0)
	st.set_normal(nrm); st.set_uv(Vector2(1, 0)); st.add_vertex(p1)
	st.set_normal(nrm); st.set_uv(Vector2(1, 1)); st.add_vertex(p2)
	st.set_normal(nrm); st.set_uv(Vector2(0, 0)); st.add_vertex(p0)
	st.set_normal(nrm); st.set_uv(Vector2(1, 1)); st.add_vertex(p2)
	st.set_normal(nrm); st.set_uv(Vector2(0, 1)); st.add_vertex(p3)


func _mech_build_hull_armor(rig: Node3D) -> void:
	var hull_mat: StandardMaterial3D = _mech_metal_mat(color_b.lightened(0.10), 0.18)
	var placements: Array = [
		[Vector3(0.46, 1.06, 0.0), Vector3(0.21, 0.18, 0.22), 0.05],
		[Vector3(-0.46, 1.06, 0.0), Vector3(0.21, 0.18, 0.22), 0.05],
		[Vector3(0.0, 0.96, -0.36), Vector3(0.26, 0.22, 0.17), 0.06],
	]
	for p: Array in placements:
		var center: Vector3 = p[0]
		var half: Vector3 = p[1]
		var jitter: float = p[2]
		var cloud: PackedVector3Array = _mech_angular_cloud(center, half, jitter, 14)
		var hull_mesh: ArrayMesh = _mech_solid_hull(cloud)
		_bng_add_mesh(rig, hull_mesh, hull_mat, Transform3D.IDENTITY, "HullArmor")


## A seeded angular point cloud (crystalline — biased to the box corners).
func _mech_angular_cloud(center: Vector3, half: Vector3, jitter: float,
		count: int) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				var corner := center + Vector3(
					sx * half.x + _rng.randf_range(-jitter, jitter),
					sy * half.y + _rng.randf_range(-jitter, jitter),
					sz * half.z + _rng.randf_range(-jitter, jitter))
				pts.append(corner)
	for _k: int in range(count):
		var f: float = _rng.randf_range(0.55, 1.04)
		var pt := center + Vector3(
			_rng.randf_range(-1.0, 1.0) * half.x,
			_rng.randf_range(-1.0, 1.0) * half.y,
			_rng.randf_range(-1.0, 1.0) * half.z) * f
		pts.append(pt)
	return pts


## Wrap a point cloud in a convex hull → a SOLID, flat-shaded ArrayMesh.
func _mech_solid_hull(cloud: PackedVector3Array) -> ArrayMesh:
	if cloud.size() < 4:
		return null
	var shape := ConvexPolygonShape3D.new()
	shape.points = cloud
	var debug: ArrayMesh = shape.get_debug_mesh()
	if debug == null or debug.get_surface_count() == 0:
		return null
	var arrays: Array = debug.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	if indices.size() >= 3:
		var tri: int = 0
		while tri + 2 < indices.size():
			_mech_flat_tri(st, verts[indices[tri]], verts[indices[tri + 1]], verts[indices[tri + 2]])
			tri += 3
	else:
		var v: int = 0
		while v + 2 < verts.size():
			_mech_flat_tri(st, verts[v], verts[v + 1], verts[v + 2])
			v += 3
	return st.commit()


func _mech_flat_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var nrm: Vector3 = (b - a).cross(c - a)
	if nrm.length() < 0.000001:
		nrm = Vector3.UP
	nrm = nrm.normalized()
	st.set_normal(nrm); st.set_uv(Vector2(0, 0)); st.add_vertex(a)
	st.set_normal(nrm); st.set_uv(Vector2(1, 0)); st.add_vertex(b)
	st.set_normal(nrm); st.set_uv(Vector2(1, 1)); st.add_vertex(c)


func _mech_build_greebles(rig: Node3D, profile: Array[Vector2]) -> void:
	var bolt_mat: StandardMaterial3D = _mech_metal_mat(color_b.lightened(0.30), 0.16)
	var vent_mat: StandardMaterial3D = _mech_metal_mat(color_b.darkened(0.15), 0.10)

	var bolt_total: int = clampi(12 + complexity, 16, 24)
	for _i: int in range(bolt_total):
		var h: float = _rng.randf_range(0.30, 1.20)
		var a: float = _rng.randf_range(0.0, TAU)
		var surf: Vector3 = _mech_shell_point(profile, a, h)
		var nrm: Vector3 = _mech_shell_normal(profile, a, h)
		var cyl := CylinderMesh.new()
		var r: float = _rng.randf_range(0.018, 0.030)
		cyl.top_radius = r
		cyl.bottom_radius = r * 1.08
		cyl.height = _rng.randf_range(0.020, 0.040)
		cyl.radial_segments = 6
		_bng_add_mesh(rig, cyl, bolt_mat,
			Transform3D(_bng_basis_from_up(nrm), surf + nrm * (cyl.height * 0.4)), "Bolt")

	var vent_total: int = 6
	for _i: int in range(vent_total):
		var h: float = _rng.randf_range(0.45, 1.10)
		var a: float = _rng.randf_range(0.0, TAU)
		var surf: Vector3 = _mech_shell_point(profile, a, h)
		var nrm: Vector3 = _mech_shell_normal(profile, a, h)
		var prism := CylinderMesh.new()
		var r: float = _rng.randf_range(0.05, 0.08)
		prism.top_radius = r
		prism.bottom_radius = r
		prism.height = 0.024
		prism.radial_segments = 6
		_bng_add_mesh(rig, prism, vent_mat,
			Transform3D(_bng_basis_from_up(nrm), surf - nrm * 0.006), "Vent")


func _mech_build_glow_core(rig: Node3D) -> void:
	var glow_mat: StandardMaterial3D = _bng_glow_mat(accent, 3.6)
	var sph := SphereMesh.new()
	sph.radius = 0.085
	sph.height = 0.17
	sph.radial_segments = 14
	sph.rings = 8
	_bng_add_mesh(rig, sph, glow_mat, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.74, 0.50)), "ReactorCore")

	var tor := TorusMesh.new()
	tor.inner_radius = 0.085
	tor.outer_radius = 0.12
	tor.rings = 20
	tor.ring_segments = 8
	_bng_add_mesh(rig, tor, _mech_metal_mat(color_b.darkened(0.1), 0.12),
		Transform3D(_bng_basis_from_up(Vector3.FORWARD), Vector3(0.0, 0.74, 0.49)), "CoreBezel")

	for s: float in [-1.0, 1.0]:
		for i: int in range(3):
			var slit := BoxMesh.new()
			slit.size = Vector3(0.016, 0.012, 0.10)
			_bng_add_mesh(rig, slit, glow_mat,
				Transform3D(Basis.IDENTITY, Vector3(0.50 * s, 0.58 + float(i) * 0.14, 0.10)), "Slit")


func _mech_build_head(rig: Node3D, base: Vector3) -> void:
	var metal_mat: StandardMaterial3D = _mech_metal_mat(color_b, 0.20)
	var dark_mat: StandardMaterial3D = _mech_metal_mat(color_b.darkened(0.25), 0.10)
	var optic_mat: StandardMaterial3D = _bng_glow_mat(accent.lerp(Color(0.98, 0.62, 0.22), 0.6), 4.4)

	var head_cloud: PackedVector3Array = _mech_angular_cloud(base + Vector3(0.0, 0.12, 0.04),
		Vector3(0.17, 0.15, 0.20), 0.03, 8)
	var head_mesh: ArrayMesh = _mech_solid_hull(head_cloud)
	_bng_add_mesh(rig, head_mesh, metal_mat, Transform3D.IDENTITY, "HeadPod")

	var bb := BoxMesh.new()
	bb.size = Vector3(0.26, 0.10, 0.04)
	_bng_add_mesh(rig, bb, dark_mat, Transform3D(Basis.IDENTITY, base + Vector3(0.0, 0.13, 0.22)), "Brow")

	var lens := SphereMesh.new()
	lens.radius = 0.062
	lens.height = 0.124
	lens.radial_segments = 16
	lens.rings = 8
	_bng_add_mesh(rig, lens, optic_mat, Transform3D(Basis.IDENTITY, base + Vector3(0.0, 0.13, 0.255)), "Optic")

	var tor := TorusMesh.new()
	tor.inner_radius = 0.062
	tor.outer_radius = 0.085
	tor.rings = 18
	tor.ring_segments = 6
	_bng_add_mesh(rig, tor, metal_mat,
		Transform3D(_bng_basis_from_up(Vector3.FORWARD), base + Vector3(0.0, 0.13, 0.25)), "OpticRing")

	for s: float in [-1.0, 1.0]:
		var ac := CylinderMesh.new()
		ac.top_radius = 0.004
		ac.bottom_radius = 0.014
		ac.height = 0.18
		ac.radial_segments = 6
		_bng_add_mesh(rig, ac, metal_mat,
			Transform3D(_bng_basis_from_up(Vector3(0.4 * s, 0.7, -0.6).normalized()),
				base + Vector3(0.10 * s, 0.22, -0.06)), "Antenna")


func _mech_build_legs(rig: Node3D, hip: Vector3) -> void:
	var leg_mat: StandardMaterial3D = _mech_metal_mat(color_b.darkened(0.05), 0.16)
	var joint_mat: StandardMaterial3D = _mech_metal_mat(color_b.lightened(0.25), 0.18)
	var dirs: Array[Vector2] = [
		Vector2(0.62, 0.55),
		Vector2(-0.62, 0.55),
		Vector2(0.55, -0.58),
		Vector2(-0.55, -0.58),
	]
	for d: Vector2 in dirs:
		var horiz := Vector3(d.x, 0.0, d.y)
		var attach := hip + horiz * 0.42 + Vector3(0.0, 0.04, 0.0)
		var knee := attach + horiz.normalized() * 0.26 + Vector3(0.0, -0.02, 0.0)
		var ankle := attach + horiz.normalized() * 0.40 + Vector3(0.0, -0.20, 0.0)
		var foot := attach + horiz.normalized() * 0.46
		foot.y = 0.0
		var positions: Array[Vector3] = [attach, knee, ankle, foot]
		var radii: Array[float] = [0.075, 0.058, 0.044, 0.030]
		var leg_mesh: Mesh = MorphoPrimitive.multi_tube(positions, radii, 8)
		_bng_add_mesh(rig, leg_mesh, leg_mat, Transform3D.IDENTITY, "Leg")

		_bng_sphere(rig, 0.072, attach, joint_mat, 6, 12)
		_bng_sphere(rig, 0.058, knee, joint_mat, 6, 12)

		var pc := CylinderMesh.new()
		pc.top_radius = 0.05
		pc.bottom_radius = 0.075
		pc.height = 0.05
		pc.radial_segments = 6
		_bng_add_mesh(rig, pc, joint_mat,
			Transform3D(Basis.IDENTITY, foot + Vector3(0.0, 0.025, 0.0)), "FootPad")


# ── Shell parametric helpers (mech) ────────────────────────────────────

## Point on the revolution surface at angle `ang` (radians) and height `y`.
func _mech_shell_point(profile: Array[Vector2], ang: float, y: float) -> Vector3:
	var r: float = _mech_profile_radius(profile, y)
	return Vector3(cos(ang) * r, y, sin(ang) * r)


## Approximate outward surface normal at (ang, y): radial + profile slope.
func _mech_shell_normal(profile: Array[Vector2], ang: float, y: float) -> Vector3:
	var dy: float = 0.02
	var r0: float = _mech_profile_radius(profile, y - dy)
	var r1: float = _mech_profile_radius(profile, y + dy)
	var dr_dy: float = (r1 - r0) / (2.0 * dy)
	var radial := Vector2(1.0, -dr_dy).normalized()
	return Vector3(cos(ang) * radial.x, radial.y, sin(ang) * radial.x).normalized()


## Linear-interpolated radius from a Vector2(radius, height) profile at height y.
func _mech_profile_radius(profile: Array[Vector2], y: float) -> float:
	if profile.size() == 0:
		return 0.1
	if y <= profile[0].y:
		return profile[0].x
	if y >= profile[profile.size() - 1].y:
		return profile[profile.size() - 1].x
	for i: int in range(profile.size() - 1):
		var a: Vector2 = profile[i]
		var b: Vector2 = profile[i + 1]
		if y >= a.y and y <= b.y:
			var t: float = (y - a.y) / maxf(b.y - a.y, 0.0001)
			return lerpf(a.x, b.x, t)
	return profile[profile.size() - 1].x
