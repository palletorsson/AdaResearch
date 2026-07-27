# dark_sphere.gd
# Atmospheric dark sphere — ambient decorative artifact for L-system maps.
# A semi-transparent dark orb with pulsing emission, slow rotation,
# and a faint shadow halo underneath.

# @identity
# essence: a dark semi-transparent sphere pulses with purple emission and wobbles slowly — it marks the inhabited space without asserting itself, a witness to the algorithms around it
# desire: to be always present but never dominant — the learner barely notices it, but its absence would make the space feel empty
# critical_parameter: presence (witness) — how much of the room it claims, from hush to eclipse; the old reading named pulse_speed (1.2) and emission range (0.05–0.35), but a rate is invisible in a still and was only ever standing in for this
# triggers: _ready builds sphere + flat halo disc; _process drives rotation wobble and sinusoidal emission pulse every frame; apply_grid_config rebuilds both shapes
# emerges: the halo ring beneath the sphere creates a soft shadow that anchors it to the ground without a hard collision plane
# needs: VR grab [missing — pure ambient, not interactive]; color config from map [has via apply_grid_config]; apply_grid_config [has]
# relationships: placed alongside primary artifacts in nearly every primitives map; pairs with CoordinateSystem3M as spatial markers; contrasts with laser_exploding_sphere (reactive vs contemplative)
# truth: some things in a space exist not to be used but to be sensed — dark_sphere is a mood, not a lesson

extends Node3D

class_name DarkSphere

## STAGE-2 DNA PROMOTION (2026-07-27). 312 placements across twenty-two sequences,
## and until now exactly one appearance: a 0.35 m purple orb, everywhere, forever.
##
## The identity block named pulse_speed as the critical parameter. That reading is
## wrong for this project — a rate cannot be seen in a rendered still, and stills are
## how anything here is judged. But look at WHY pulse_speed was called critical:
## "too fast and it competes with the artifact; too slow and it reads as static."
## That is not a claim about tempo. It is a claim about HOW MUCH OF THE ROOM THE
## SPHERE TAKES. The rate was a proxy for presence. So presence is the axis, and it
## is made of the things a still can hold: size, glow, opacity, the pool on the floor.
##
##   presence  how much of the room it claims    hush · witness · beacon · eclipse
##   body      the form the darkness takes       orb · swarm · cage · cairn
##
## presence=witness + body=orb is the old behaviour, byte for byte, and it is the
## default — all 312 existing placements are untouched.
##
## GRAMMAR FIX (2026-07-27). `body=caged` was a participle, and in this grammar values
## are nouns: `cage` names the apparatus, `caged` describes what happened to the sphere.
## The old spelling is still accepted — see BODY_ALIASES — because a spelling that was
## valid yesterday should not become an empty cell today. The default did not move.
##
## What it cost: eclipse and beacon are wider than one grid cell once their floor
## pool is counted (~1.5 cells). That is deliberate — a thing that claims the room
## has to overspill its cell to claim it — but it means those two lineages should be
## placed with a free neighbour, not shoulder to shoulder with a teaching artifact.
##
## Usage in map_data.json:
##   "dark_sphere"                                  → the legacy orb
##   "dark_sphere#presence:hush"                    → barely there
##   "dark_sphere#presence:beacon#body:swarm"       → six lit orbs, floor glowing
##   "dark_sphere#presence:eclipse"                 → a matte hole that eats light
##   "dark_sphere#body:cairn"                       → stacked marker, meets the ground

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")


# Spine-corridor contract — see doc/SPINE_HINTS_CONTRACT.md
# Left describing the legacy orb on purpose: the corridor builder lays out every
# placement from this one dictionary, so making it lineage-aware would re-flow maps
# that never opted into a lineage.
func spine_hints() -> Dictionary:
	return {
		"role":         "ambient",
		"footprint":    Vector2i(1, 1),
		"approach":     "any",
		"reading_dist": 0.0,
		"height":       -0.5,
		"budget_ms":    0.2,
		"tags":         ["visual"],
	}


## Display settings
@export var display_size: float = 0.5
@export var sphere_radius: float = 0.35
@export var float_height: float = 0.25
@export var rotation_speed: float = 0.15
@export var pulse_speed: float = 1.2
@export var pulse_min: float = 0.05
@export var pulse_max: float = 0.35

## Colors
@export var albedo_color: Color = Color(0.08, 0.04, 0.12)
@export var emission_color: Color = Color(0.18, 0.08, 0.28)

## AXIS 1 — how much of the room this thing claims. hush recedes to a smudge;
## witness is the legacy orb; beacon lights the floor around it; eclipse gives
## nothing back and drinks the light instead.
@export var presence: String = "witness"

## AXIS 2 — the form the darkness takes. orb is the single legacy sphere; swarm
## scatters the same mass into a ring of small ones; cage puts it in lab apparatus;
## cairn stacks it into a marker that meets the ground.
@export var body: String = "orb"

## Every multiplier is against the legacy numbers, so witness = all 1.0 = no change.
## The values are far apart on purpose: at 3 m the difference between two variants
## has to be obvious, not a nudge. radius alone moves silhouette area by 7x across
## the axis (0.55^2 to 1.5^2).
const PRESENCE: Dictionary = {
	"hush":    {"radius": 0.55, "emit": 0.20, "alpha": 0.50, "tint": 1.00, "halo_a": 0.35, "halo_r": 0.85, "lamp": "none"},
	"witness": {"radius": 1.00, "emit": 1.00, "alpha": 1.00, "tint": 1.00, "halo_a": 1.00, "halo_r": 1.00, "lamp": "none"},
	"beacon":  {"radius": 1.15, "emit": 3.60, "alpha": 1.00, "tint": 1.60, "halo_a": 2.60, "halo_r": 1.45, "lamp": "glow"},
	"eclipse": {"radius": 1.50, "emit": 0.00, "alpha": 1.00, "tint": 0.30, "halo_a": 2.20, "halo_r": 1.25, "lamp": "drink"},
}

## The forms this artifact builds. Nouns, lowercase, one word each.
const BODIES: Array[String] = ["orb", "swarm", "cage", "cairn"]

## Retired spellings, still accepted. Kept OUT of the match block on purpose: an alias
## resolved by a second case would be declared as its own variant when the registry is
## derived from this code, and a sweep would then render two identical frames and report
## the axis inert. Fold it here, dispatch on the canonical value only.
const BODY_ALIASES: Dictionary = {"caged": "cage"}

var _sphere_mesh: Node3D
var _halo_ring: MeshInstance3D
var _sphere_material: StandardMaterial3D
var _time_elapsed: float = 0.0

# Resolved from `presence` at build time and read every frame by _process. Held as
# plain floats rather than a dictionary lookup because this runs on 312 objects.
var _radius: float = 0.35
var _emit_mul: float = 1.0
var _alpha_mul: float = 1.0
var _tint_mul: float = 1.0
var _halo_lo: float = 0.08
var _halo_hi: float = 0.20
var _halo_seed: float = 0.15
var _halo_radius: float = 0.42
var _unlit_body: bool = false


func _ready() -> void:
	_create_sphere()
	_create_halo_ring()


func _process(delta: float) -> void:
	_time_elapsed += delta

	# Slow rotation around Y axis with slight wobble on X
	if _sphere_mesh:
		_sphere_mesh.rotation.y += rotation_speed * delta
		_sphere_mesh.rotation.x = sin(_time_elapsed * 0.4) * 0.05

	# Pulsing emission energy
	if _sphere_material:
		var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
		_sphere_material.emission_energy_multiplier = lerpf(pulse_min * _emit_mul, pulse_max * _emit_mul, pulse_t)

		# Subtle albedo brightness oscillation
		var brightness := lerpf(0.6, 1.0, pulse_t)
		_sphere_material.albedo_color = Color(
			albedo_color.r * brightness * _tint_mul,
			albedo_color.g * brightness * _tint_mul,
			albedo_color.b * brightness * _tint_mul,
			albedo_color.a * _alpha_mul
		)

	# Halo ring subtle pulse (opacity)
	if _halo_ring:
		var halo_mat := _halo_ring.material_override as StandardMaterial3D
		if halo_mat:
			var halo_t := (sin(_time_elapsed * pulse_speed * 0.7) + 1.0) * 0.5
			halo_mat.albedo_color.a = lerpf(_halo_lo, _halo_hi, halo_t)


## Turn `presence` into the numbers the build and the frame loop both read. Called
## from both builders so neither can run against a stale radius — which means it has
## to be idempotent, so the body's own halo widening lives here too rather than in
## _build_swarm, where the second call would have thrown it away.
func _resolve_presence() -> void:
	var p: Dictionary = PRESENCE.get(presence, PRESENCE["witness"])
	var halo_a: float = float(p["halo_a"])
	_radius = sphere_radius * float(p["radius"])
	_emit_mul = float(p["emit"])
	_alpha_mul = float(p["alpha"])
	_tint_mul = float(p["tint"])
	_halo_lo = 0.08 * halo_a
	_halo_hi = 0.20 * halo_a
	_halo_seed = 0.15 * halo_a
	_halo_radius = _radius * 1.2 * float(p["halo_r"])
	# a scattered body needs a pool wide enough to sit under all of it, or the ring
	# of orbs floats over a disc that only covers the empty middle. 1.35 is the ring's
	# own outer edge over the legacy 1.2 — the pool overhangs the swarm by exactly as
	# much as it overhangs the single orb, so the two lineages sit the same way.
	if body == "swarm":
		_halo_radius *= 1.35
	_unlit_body = str(p["lamp"]) == "drink"


## The dark material every lineage shares — one instance, so a swarm of six orbs
## pulses as one animal rather than six.
func _build_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(
		albedo_color.r * _tint_mul,
		albedo_color.g * _tint_mul,
		albedo_color.b * _tint_mul,
		0.85 * _alpha_mul
	)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.6
	m.metallic_specular = 0.7
	m.roughness = 0.25
	m.emission_enabled = true
	m.emission = emission_color
	m.emission_energy_multiplier = pulse_min * _emit_mul
	m.cull_mode = BaseMaterial3D.CULL_BACK

	# eclipse is not a dimmer setting — it is a different kind of object. The sheen
	# has to go too, because a black ball with a specular highlight still reads as a
	# ball; without it, it reads as a hole cut in the room.
	if _unlit_body:
		m.emission_enabled = false
		m.metallic = 0.0
		m.metallic_specular = 0.0
		m.roughness = 0.95
	return m


func _sphere_of(r: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r * 2.0
	mesh.radial_segments = 32
	mesh.rings = 16
	mi.mesh = mesh
	mi.material_override = _sphere_material
	return mi


## Fold a retired spelling onto the form it names, and anything unrecognised onto the
## legacy orb. Takes the raw string rather than reading `body` so the fold can never be
## mistaken for a dispatch table when the registry declaration is derived from this file.
func _canonical_body(raw: String) -> String:
	var b: String = str(BODY_ALIASES.get(raw, raw))
	return b if BODIES.has(b) else "orb"


func _create_sphere() -> void:
	# RESOLVE ONCE, before anything reads it. Two consumers below look at `body` — the
	# halo widening inside _resolve_presence() and the match that picks a builder — and
	# folding the alias at only one of them is how `caged` would build the apparatus over
	# an orb-sized pool of light, or the reverse.
	body = _canonical_body(body)
	_resolve_presence()
	_sphere_material = _build_material()

	match body:
		"swarm":
			_build_swarm()
		"cage":
			_build_cage()
		"cairn":
			_build_cairn()
		_:
			_build_orb()

	_add_presence_lamp()
	add_child(_sphere_mesh)


## LEGACY LINEAGE — one sphere floating over the halo, mesh named SphereDisplay.
## Do not touch: this is what 312 placements render, and any drift here rewrites the
## background of a fifth of the project's maps without anyone asking for it.
func _build_orb() -> void:
	_sphere_mesh = _sphere_of(_radius)
	_sphere_mesh.name = "SphereDisplay"
	_sphere_mesh.position = Vector3(0, float_height + _radius, 0)


## The witness made plural. Same dark, redistributed: six small orbs on a ring, so
## the thing marks a REGION rather than a point. Kept inside 0.95 m across at witness
## presence so it still occupies one cell; at eclipse it will overspill.
func _build_swarm() -> void:
	_sphere_mesh = Node3D.new()
	_sphere_mesh.name = "SphereDisplay"
	_sphere_mesh.position = Vector3(0, float_height + _radius, 0)
	var count: int = 6
	var ring: float = _radius * 0.95
	var small: float = _radius * 0.40
	for i in range(count):
		var ang: float = TAU * float(i) / float(count)
		var orb: MeshInstance3D = _sphere_of(small)
		orb.name = "Orb%d" % i
		# alternating height so the ring reads as a cloud in a still, not as a
		# flat carousel seen edge-on from the usual eye level
		var lift: float = (_radius * 0.42) if (i % 2 == 0) else (-_radius * 0.30)
		orb.position = Vector3(cos(ang) * ring, lift, sin(ang) * ring)
		_sphere_mesh.add_child(orb)


## The mood held by the lab. Three orthogonal rings and four legs in the hangar
## palette — deliberately NOT the sphere's own material, because the point of this
## lineage is that the apparatus and the thing it contains are different orders of
## object. The cage does not rotate with the sphere; only the sphere is alive.
func _build_cage() -> void:
	var centre: float = float_height + _radius
	_sphere_mesh = _sphere_of(_radius)
	_sphere_mesh.name = "SphereDisplay"
	_sphere_mesh.position = Vector3(0, centre, 0)

	var frame := Node3D.new()
	frame.name = "Cage"
	var metal: StandardMaterial3D = HangarKit.painted_metal(Color(0.46, 0.48, 0.53), 0.30, 0.55, 0.48)
	var cage_r: float = _radius * 1.34

	for axis in range(3):
		var hoop := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = cage_r - 0.014
		torus.outer_radius = cage_r + 0.014
		torus.rings = 6
		torus.ring_segments = 28
		hoop.mesh = torus
		hoop.material_override = metal
		hoop.position = Vector3(0, centre, 0)
		if axis == 1:
			hoop.rotation_degrees = Vector3(90, 0, 0)
		elif axis == 2:
			hoop.rotation_degrees = Vector3(0, 0, 90)
		frame.add_child(hoop)

	# Legs stop at the sphere's centre height so the cage looks welded to the lowest
	# hoop rather than spearing straight through the orb.
	for i in range(4):
		var ang: float = TAU * float(i) / 4.0 + PI * 0.25
		var leg := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.018
		cyl.bottom_radius = 0.018
		cyl.height = centre
		leg.mesh = cyl
		leg.material_override = metal
		leg.position = Vector3(cos(ang) * cage_r, centre * 0.5, sin(ang) * cage_r)
		frame.add_child(leg)

	var foot := MeshInstance3D.new()
	var foot_torus := TorusMesh.new()
	foot_torus.inner_radius = _radius * 1.30
	foot_torus.outer_radius = _radius * 1.48
	foot_torus.rings = 6
	foot_torus.ring_segments = 28
	foot.mesh = foot_torus
	foot.material_override = metal
	foot.position = Vector3(0, 0.035, 0)
	frame.add_child(foot)

	add_child(frame)


## Three spheres stacked, resting on the floor. The one lineage that gives up the
## float: a cairn is the oldest marker there is, and "marks the inhabited space" is
## the artifact's own first sentence. Roughly 1.35 m tall at witness presence, so it
## reads as a landmark from across the room rather than as scenery underfoot.
func _build_cairn() -> void:
	_sphere_mesh = Node3D.new()
	_sphere_mesh.name = "SphereDisplay"
	# The stack sits at origin and the stones carry their own heights, so the halo
	# (not a stone) stays the lowest geometry and auto-grounding leaves us alone.
	_sphere_mesh.position = Vector3.ZERO

	var radii: Array[float] = [_radius, _radius * 0.70, _radius * 0.46]
	var y: float = 0.02 + radii[0]
	for i in range(radii.size()):
		if i > 0:
			# 18% overlap — enough that they read as a stack under gravity instead of
			# three balls that happen to be in a line
			y += (radii[i - 1] + radii[i]) * 0.82
		var stone: MeshInstance3D = _sphere_of(radii[i])
		stone.name = "Stone%d" % i
		stone.position = Vector3(0, y, 0)
		_sphere_mesh.add_child(stone)


## presence=beacon and presence=eclipse are the two that touch the ROOM and not just
## the object — one pours its colour onto the floor, the other takes light away.
## Without this the two extremes are still just a bigger and a smaller ball; with it,
## you can tell which one is in a map from the far wall.
func _add_presence_lamp() -> void:
	var p: Dictionary = PRESENCE.get(presence, PRESENCE["witness"])
	var kind: String = str(p["lamp"])
	if kind == "none":
		return
	var lamp := OmniLight3D.new()
	lamp.name = "PresenceLamp"
	lamp.position = Vector3(0, float_height + _radius, 0)
	lamp.shadow_enabled = false  # ambient scenery has a 0.2 ms budget; shadows blow it
	if kind == "glow":
		lamp.light_color = emission_color
		lamp.light_energy = 2.4
		lamp.omni_range = 2.6
		lamp.omni_attenuation = 1.4
	else:
		# A negative light. Godot subtracts it, so the eclipse literally darkens its
		# own neighbourhood — the artifact's "witness" turned into a thing that
		# absorbs. Kept short-range so it pools rather than blacking out the map.
		lamp.light_negative = true
		lamp.light_color = Color(0.62, 0.58, 0.72)
		lamp.light_energy = 1.0
		lamp.omni_range = 2.2
		lamp.omni_attenuation = 1.8
	add_child(lamp)


func _create_halo_ring() -> void:
	_resolve_presence()
	_halo_ring = MeshInstance3D.new()
	_halo_ring.name = "HaloRing"

	# Flat cylinder acting as a shadow/halo disc beneath the sphere.
	# It is also the lowest geometry in every lineage, which is load-bearing: the
	# grid auto-grounds an artifact by snapping its AABB floor to the cell surface,
	# and at y=0.01 this disc is inside the 0.01 tolerance. Remove it and every
	# variant gets silently dropped onto the floor.
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = _halo_radius
	ring_mesh.bottom_radius = _halo_radius
	ring_mesh.height = 0.005
	ring_mesh.radial_segments = 24
	_halo_ring.mesh = ring_mesh

	var halo_mat := StandardMaterial3D.new()
	# _halo_seed is the legacy 0.15 scaled by the lineage — the disc's alpha for the
	# single frame before _process takes it over. Using _halo_lo here instead would
	# have made frame zero of every existing capture a shade lighter.
	halo_mat.albedo_color = Color(0.1, 0.04, 0.16, _halo_seed)
	halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_halo_ring.material_override = halo_mat

	# Sit just above the ground plane
	_halo_ring.position = Vector3(0, 0.01, 0)

	add_child(_halo_ring)


## Grid system integration
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("display_size"):
		display_size = float(config_data["display_size"])
	if config_data.has("sphere_radius"):
		sphere_radius = clampf(float(config_data["sphere_radius"]), 0.1, 1.0)
	if config_data.has("float_height"):
		float_height = clampf(float(config_data["float_height"]), 0.0, 1.0)
	if config_data.has("rotation_speed"):
		rotation_speed = clampf(float(config_data["rotation_speed"]), 0.0, 2.0)
	if config_data.has("pulse_speed"):
		pulse_speed = clampf(float(config_data["pulse_speed"]), 0.1, 5.0)
	if config_data.has("emission_color"):
		var c = config_data["emission_color"]
		if c is Color:
			emission_color = c
	if config_data.has("albedo_color"):
		var c = config_data["albedo_color"]
		if c is Color:
			albedo_color = c

	# Stage-2 axes. Unknown values fall back to the legacy lineage rather than
	# erroring, so a typo in a map token degrades to the old orb instead of an
	# empty cell.
	if config_data.has("presence"):
		var want_p: String = str(config_data["presence"])
		presence = want_p if PRESENCE.has(want_p) else "witness"
	if config_data.has("body"):
		body = _canonical_body(str(config_data["body"]))

	# Rebuild with new parameters
	for child in get_children():
		child.queue_free()
	_create_sphere()
	_create_halo_ring()
