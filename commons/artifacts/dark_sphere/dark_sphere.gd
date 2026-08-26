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

# ── THE GESTATION (2026-08-24, Palle: "it could be inert form from the
# beginning. If we shoot the DS in point a point appears and falls to the
# ground. If we shoot the DS in line a line falls out and breaks to pieces
# ... a weaver's logic, before it can take another form") ────────────────────
#
# The dark sphere has stood beside the walk since Point_One, 305 of them as
# bare tokens, decorative. It is an EGG: shoot it with the catalyst and it
# yields what the walk has taught by the place it stands in — a point where
# the walk has only learned points, a line where it has learned lines. The
# creature is assembled out of what the visitor has induced, which is the
# project's own thesis wearing a body.
#
# NOTHING CHANGES UNTIL IT IS SHOT. Every existing placement looks and behaves
# exactly as before; the sphere gains a hit body on the catalyst's own layer
# and one duck-typed method. The catalyst dispatches by NAME
# (catalyst_projectile.gd:107 — `if body.has_method("hit_by_catalyst_mode")`),
# never by class, so this needs no registration anywhere.
#
# THE STAGE IS DERIVED, NOT REMEMBERED. It is read from the hall or map the
# sphere stands in, so one bare token is gestational everywhere and the ladder
# follows the spine by itself. Nothing persists: a yield lives in its hall for
# that visit, and the VISITOR carries the continuity from room to room.
# `#stage:` overrides the derivation for a placement that wants a specific rung.

## "" derives from where this sphere stands. Otherwise: point, line (rungs one
## and two), or inert to refuse the gestation for this placement.
@export var stage: String = ""
## THE YIELD READS AT EYE LEVEL (2026-08-24, Palle: "the point is too small,
## make it bigger"). The first try took its size from the project's own points
## — but those are MARKS, 4 mm and 20 mm, drawn to be looked at closely on a
## bench. A thing that falls out of an egg onto a museum floor and is meant to
## be seen from standing height is a different object, and there was no
## precedent for it in the corpus. 0.22 m radius is a 44 cm body: read from
## across the hall, still small enough to be a POINT rather than a boulder.
@export var yield_point_radius: float = 0.22
## the line's pieces, sized off the same body so the two rungs stay siblings
@export var yield_line_piece_m: float = 0.30
## The catalyst's hit layer. Its projectiles carry collision_mask = 2 and the
## receiver contract in this corpus is layer 2 / mask 0 — mask 0 on purpose,
## so a hit body never pushes the world's cubes around.
const HIT_LAYER := 2
var _gest_body: StaticBody3D = null
var _gest_spent: bool = false


## Where does this sphere stand? The museum stamps em_pearl / em_chapter on the
## segment; the grid hands its map name down from GridSystem. Either answers
## "what has the walk taught here", and the ladder reads the same words.
func _gest_where() -> String:
	var n: Node = self
	for _i in range(24):
		if n == null:
			break
		if n.has_meta("em_pearl") and String(n.get_meta("em_pearl")) != "":
			return String(n.get_meta("em_pearl")).to_lower()
		if n.has_meta("em_chapter") and String(n.get_meta("em_chapter")) != "":
			return String(n.get_meta("em_chapter")).to_lower()
		var mn: Variant = n.get("map_name")
		if mn != null and String(mn) != "":
			return String(mn).replace("_", " ").to_lower()
		n = n.get_parent()
	return ""


## The rung this place stands on. Only the first two are built; every other
## place answers "" and the sphere stays what it has always been.
func _gest_stage() -> String:
	var want := stage.strip_edges().to_lower()
	if want != "":
		return "" if want == "inert" else want
	var w := _gest_where()
	if w == "":
		return ""
	# "line" is tested FIRST: "point lines" carries both words, and it is a line
	if w.contains("line"):
		return "line"
	if w == "point" or w.contains("point one"):
		return "point"
	return ""


## The catalyst's own call. Duck-typed by the projectile, so the sphere needs
## no class, no group and no registration to receive a shot.
func hit_by_catalyst_mode(colour: Color, _mode_id: String = "") -> void:
	_gest_yield(colour)


func hit_by_projectile(colour: Color) -> void:
	_gest_yield(colour)


func _gest_yield(colour: Color) -> void:
	if _gest_spent:
		return
	var rung := _gest_stage()
	if rung == "":
		return                      # this place has taught nothing to yield yet
	_gest_spent = true
	match rung:
		"point":
			_gest_point(colour)
		"line":
			_gest_line(colour)
		_:
			_gest_spent = false     # a rung that is not built yet leaves the egg whole
			return
	print("[dark_sphere] gestation: %s yielded a %s" % [_gest_where(), rung])


func _gest_mat(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.emission_enabled = true
	m.emission = colour
	m.emission_energy_multiplier = 1.4
	m.roughness = 0.4
	return m


func _gest_host() -> Node:
	# the yield belongs to the ROOM, not to the egg: a sphere that shrinks or
	# is freed must not take the thing it produced with it
	var p: Node = get_parent()
	return p if p != null else self


## RUNG ONE. A point appears and falls to the ground.
func _gest_point(colour: Color) -> void:
	var b := RigidBody3D.new()
	b.name = "YieldPoint"
	var r: float = maxf(0.02, yield_point_radius)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	mi.material_override = _gest_mat(colour)
	b.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = r
	cs.shape = sh
	b.add_child(cs)
	_gest_host().add_child(b)
	# born at the egg's own centre, so it drops OUT of the sphere
	b.global_position = global_position


## RUNG TWO. A line falls out of the sphere and breaks to pieces — it leaves as
## one line and lands as several, which is the whole argument of the rung.
func _gest_line(colour: Color) -> void:
	var pieces: int = 5
	var seg_len: float = maxf(0.04, yield_line_piece_m)
	var host: Node = _gest_host()
	var here: Vector3 = global_position
	var mat: StandardMaterial3D = _gest_mat(colour)
	for i in range(pieces):
		var b := RigidBody3D.new()
		b.name = "YieldLine%d" % i
		var mi := MeshInstance3D.new()
		var thick: float = clampf(seg_len * 0.17, 0.02, 0.09)
		var bm := BoxMesh.new()
		bm.size = Vector3(seg_len * 0.86, thick, thick)
		mi.mesh = bm
		mi.material_override = mat
		b.add_child(mi)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(seg_len * 0.86, thick, thick)
		cs.shape = sh
		b.add_child(cs)
		host.add_child(b)
		# laid out as ONE line through the sphere, then let go
		b.global_position = here + Vector3((float(i) - float(pieces - 1) * 0.5) * seg_len, 0.0, 0)
		# the break: each piece leaves with its own small push, so the line
		# comes apart in the air instead of landing as a rod
		# the break scales with the body: a bigger line comes apart wider
		var k: float = seg_len / 0.13
		b.apply_central_impulse(Vector3(
			(float(i) - float(pieces - 1) * 0.5) * 0.045 * k, 0.02 * k, randf_range(-0.02, 0.02) * k))


## The body the catalyst can hit. Added late (deferred, after the artifact has
## built) so it wraps whatever presence/body the DNA chose, and sized to it.
func _gest_arm() -> void:
	if _gest_body != null and is_instance_valid(_gest_body):
		return
	_gest_body = StaticBody3D.new()
	_gest_body.name = "GestationHit"
	_gest_body.collision_layer = HIT_LAYER
	_gest_body.collision_mask = 0          # never push the world
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.42
	var ab: AABB = AABB()
	var got := false
	for m in find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var box: AABB = mi.transform * mi.get_aabb()
		ab = box if not got else ab.merge(box)
		got = true
	if got:
		sh.radius = clampf(maxf(ab.size.x, ab.size.z) * 0.5, 0.12, 2.0)
		_gest_body.position = ab.get_center()
	cs.shape = sh
	_gest_body.add_child(cs)
	add_child(_gest_body)


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

## THE FINISH (2026-08-07). tools/render_lint.py measured this artifact FLAT — tonal
## spread under 0.055 and fewer than forty distinct colours across the subject, which is
## the numeric signature of one albedo, one roughness and one metallic over a whole
## object. It was exactly that, on 317 placements: metallic 0.6, roughness 0.25, no
## roughness map, no normal map, and a floor pool painted one uniform alpha out to a hard
## circular edge.
##
## metallic 0.6 is the tell. Nothing is 0.6 metallic; the middle of that range is not a
## material, it is a knob turned until the sheen looked right. What the knob was reaching
## for is a DIELECTRIC WITH A FILM OVER IT — a dark glass ball has a broad specular lobe
## from its own surface and a tighter one from the coat on top, and two lobes of different
## width is most of what makes a sphere read as a sphere and not as a disc. The body is
## metallic 0 now and the sheen comes from where it actually comes from.
##
## A sphere is the hardest surface there is: no edge to catch a highlight, no flat face to
## hide a wrong roughness on, and a terminator that shows a mis-sized normal map as orange
## peel before anything else does. Every number below is sized against that.
##
## ECLIPSE, AND THE ONE LINE THIS PASS REVERSES (2026-08-07, second look). The first render
## came back with eclipse as a flat black circle: no rim, no terminator, no sheen, nothing
## separating the sphere from the pool it stands in. The darkness was not the fault — an
## artifact called dark_sphere whose value is `eclipse` is supposed to be black, and a
## checker calling it CRUSHED is measuring the design working. The fault was that it had
## stopped being an OBJECT. `metallic_specular = 0.0` was the line that did it: F0 = 0 means
## the surface has no Fresnel at all, and Fresnel is the whole of a dark ball's limb. So the
## old note here — "the sheen has to go too, because a black ball with a specular highlight
## still reads as a ball" — is exactly backwards, and it is reversed on purpose. A black
## sphere in a lit room HAS a grazing sheen around its limb, a terminator lifted a shade by
## light wrapping past it, and one small specular the size of the lamp. Take those away and
## you do not get a darker sphere, you get a hole. The albedo did not move a digit; the
## darkness is untouched. Only the physics of the surface came back.
##
## GRAIN SCALE — the number that costs the most when it is wrong. The body is a sphere
## 0.70 m across at witness (radius 0.35), 1.05 m at eclipse, 0.385 m at hush, and it sits
## in an AABB about 0.95 m tall, so in a 760 px capture the ball itself lands near 300 px
## whichever lineage is built. Now run the kit's rule of thumb on that. scale_detail's
## factor ~= 1 / longest dimension is a MULTIPLIER on whatever tiling the builder already
## chose, and at a 0.95 m body it comes out at almost exactly 1.0 — so it leaves both
## builders where they are: 5 repeats per metre for hard_plastic, 9 for rubber. Carry it
## through. Micro grain is about 24 features per repeat, so 3.7 repeats across the ball is
## ~90 features over 300 px, three pixels each and already at the edge. Flake is about 107
## per repeat, so 9.9 repeats is over a THOUSAND features across the same 300 px — a
## quarter of a pixel each. That is not detail; that is the television static three rounds
## of critics blamed on six different post-process settings.
##
## So the tiling here is stated as REPEATS ACROSS THE SILHOUETTE and nothing else: about
## two for the micro grain, about one for the flake. Both land a feature near six screen
## pixels at the working distance, and both are computed from _radius, so hush and eclipse
## get the same surface at different sizes rather than the same numbers at different sizes.
## _fit_grain() is where that happens; GRAIN_ACROSS_* are the numbers.
##
## WHAT DID NOT CHANGE. Every mesh, every radius, every position, both lamps, the pulse
## rates, the halo's peak alpha, and both axes. presence=witness + body=orb builds the
## silhouette it has always built. The floor pool is the one place a shape moved: it was a
## uniform wash out to a hard circular edge, which is a flat region as surely as a flat
## sphere is, and it now carries a radial falloff that peaks at the legacy alpha under the
## ball and reaches zero at the same rim. The disc, its radius and its y = 0.01 seat — the
## auto-grounding contract documented at _create_halo_ring — are byte for byte.
##
## MeshKit was read and deliberately not called. The geometry is exactly as it shipped
## (this pass re-finishes surfaces), and every mesh in play — SphereMesh, CylinderMesh,
## TorusMesh — is a Godot primitive that already carries the UVs and TANGENTS a normal map
## needs, so there is nothing for it to fix. The one thing it would have been for,
## replacing a mesh, is the thing this pass must not do.
const PBR := preload("res://commons/render/pbr_kit.gd")


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
##
## The three finish columns were folded into THIS table rather than a parallel one on
## purpose: a second const keyed by the same four names would read, to anything deriving
## the registry from this file, like a second dispatch table for the same axis. One row
## per value, all of it, is the shape that cannot be misread.
##   gloss     into PbrKit.hard_plastic — how tight the base specular lobe sits
##   rim       fresnel strength at the limb. The line that makes a sphere not a circle,
##             and the line PbrKit.edge_light warns is a filter when it is on everything.
##   rim_tint  0 = the rim carries the light's own colour, 1 = the albedo's
const PRESENCE: Dictionary = {
	"hush":     {"radius": 0.55, "emit": 0.20, "alpha": 0.50, "tint": 1.00, "halo_a": 0.35, "halo_r": 0.85, "lamp": "none",  "gloss": 0.46, "rim": 0.20, "rim_tint": 0.40},
	"witness":  {"radius": 1.00, "emit": 1.00, "alpha": 1.00, "tint": 1.00, "halo_a": 1.00, "halo_r": 1.00, "lamp": "none",  "gloss": 0.62, "rim": 0.26, "rim_tint": 0.35},
	"beacon":   {"radius": 1.15, "emit": 3.60, "alpha": 1.00, "tint": 1.60, "halo_a": 2.60, "halo_r": 1.45, "lamp": "glow",  "gloss": 0.70, "rim": 0.16, "rim_tint": 0.55},
	"eclipse":  {"radius": 1.50, "emit": 0.00, "alpha": 1.00, "tint": 0.30, "halo_a": 2.20, "halo_r": 1.25, "lamp": "drink", "gloss": 0.00, "rim": 0.46, "rim_tint": 0.22},
	"becoming": {"radius": 1.20, "emit": 2.40, "alpha": 0.55, "tint": 1.30, "halo_a": 2.00, "halo_r": 1.90, "lamp": "kin",   "gloss": 0.34, "rim": 0.52, "rim_tint": 0.65},
}

## BECOMING — the fifth value, and the only one that is not a quantity of presence
## (2026-08-10). The other four answer "how much of the room does it claim". This one
## answers a different question: what happens when the witness is ATTENDED.
##
## The argument is in doc/VR_VR_PT_2023.md and on /the-dark-spot. dark_sphere is the
## situated witness — present in 748 maps, "sensed, not used, a mood not a lesson",
## Haraway's partial observer standing in nearly every room and attended by nobody. The
## catalyst is the project's tool of "transformation, becoming, boundary dissolution",
## and catalyst_orb states its own nature as "capability-as-relation ... felt before it
## is seen. No numbers on screen. Ever." Put those two next to each other and the
## witness is simply the DORMANT catalyst. `becoming` is the hinge where it wakes.
##
## So the row reads as a transformation and not as a size:
##   alpha 0.55   the body gives up its edge — boundary dissolution, the one lineage
##                whose silhouette is deliberately less certain than witness's
##   rim 0.52     the highest Fresnel in the table. As the body dissolves the LIMB is
##                what survives — a thing becoming is brightest where it ends
##   halo_r 1.90  the widest pool here by a third. Not a bigger shadow: a REACH. This
##                is the make-kin gesture written in the one channel the floor has
##   lamp "kin"   it gives light outward, where eclipse drinks it. Kin, not capture
##
## It overspills its cell by more than beacon does — see the placement note above; that
## is the cost of a value whose whole content is relation to what is around it.
##
## WHAT IT IS NOT: it is not measured, and it must not become so. There is no score
## here, no completion, no state that resolves — the ring reaches and fades and reaches
## again, and nothing anywhere records that it did. That is the point of it, and the
## reason it is presence and not a new axis: an axis called "state" would be a scoreboard
## for a thing whose argument is that the un-reconciled remainder is what keeps a system
## becoming. Reconciliation is death. This value stays hot.

## GRAIN SIZE, stated the only way that survives a change of radius: how many times the
## detail texture repeats ACROSS THE SPHERE'S OWN SILHOUETTE. See the grain note at the
## top of the file. The kit's builders ship tilings authored for small parts — 5 per metre
## for hard_plastic, 9 for rubber — and on a body this size those are a tenth of a feature
## per pixel. _fit_grain converts these into the tiling each material actually gets.
##
## MICRO is SIMPLEX_SMOOTH at frequency 0.095, so about 24 features per repeat: two repeats
## across ~300 screen pixels puts a feature near 6 px. FLAKE is 1-octave value noise at
## 0.42, about 107 features per repeat, so it needs roughly a fifth as many repeats to land
## in the same place. Same look, different noise — which is exactly why one global tiling
## number would have been wrong for both.
const GRAIN_ACROSS_MICRO: float = 2.0
const GRAIN_ACROSS_FLAKE: float = 0.9

## The cage is the other scale in this file and it runs the reasoning the other way. Its
## hoops are a 28 mm tube and its legs 36 mm — about 12 screen pixels of cross-section — so
## a tiling that suits the sphere never repeats across them at all and reads as flat paint.
## An eighth of a repeat across 28 mm is three features on the tube, four pixels each.
const GRAIN_ACROSS_TUBE: float = 0.12
const CAGE_TUBE_M: float = 0.028

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

# presence=becoming only. Null for every other lineage, which is what keeps the frame
# loop's new branch free for the 312 placements that never asked for it.
var _kin_ring: MeshInstance3D
var _kin_mat: StandardMaterial3D
var _kin_base_r: float = 0.4

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
var _gloss: float = 0.62
var _rim: float = 0.26
var _rim_tint: float = 0.35


func _ready() -> void:
	call_deferred("_gest_arm")   # the catalyst can hit it once it has a body
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

	# The reach. Widens out to the pool's rim and thins as it goes, then begins again —
	# a relation that is never concluded. Alpha never reaches zero (see _add_kin_ring).
	if _kin_ring and _kin_mat:
		var reach_t: float = fposmod(_time_elapsed * 0.30, 1.0)
		var span: float = maxf(_halo_radius, _kin_base_r * 1.2) / _kin_base_r
		var s: float = lerpf(1.0, span, reach_t)
		_kin_ring.scale = Vector3(s, 1.0, s)
		_kin_mat.albedo_color.a = lerpf(0.42, 0.10, reach_t)

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
	# Defaulted rather than indexed: a row that predates the finish columns degrades to the
	# legacy witness surface instead of throwing during a build.
	_gloss = float(p.get("gloss", 0.62))
	_rim = float(p.get("rim", 0.26))
	_rim_tint = float(p.get("rim_tint", 0.35))


## Re-tile an already-built kit material so its grain lands at `repeats` texture repeats
## across `span` metres of the thing wearing it — the sphere's diameter, the cage tube's
## width. PbrKit.scale_detail() multiplies, so the factor is target over current; reading
## uv1_scale back rather than assuming the builder's number means this keeps working if the
## kit retunes its own tilings.
func _fit_grain(m: StandardMaterial3D, span: float, repeats: float) -> void:
	if m == null:
		return
	var want: float = repeats / maxf(span, 0.02)
	PBR.scale_detail(m, want / maxf(m.uv1_scale.x, 0.001))


## The dark material every lineage shares — one instance, so a swarm of six orbs
## pulses as one animal rather than six.
##
## Two builders, because eclipse and the rest are not the same substance. The lit lineages
## are dark glass: a dielectric with a film on it, one broad lobe from the body and one
## tight lobe from the coat, which is what hard_plastic() builds and what metallic 0.6
## was fumbling toward. eclipse is matte stone — rubber() is the kit's own name for "the
## surface that eats light and shows only a broad soft sheen", which is eclipse's argument
## written out in a material.
##
## NOTHING HERE TOUCHES ALBEDO OR EMISSION BEYOND THE LEGACY EXPRESSIONS, deliberately.
## _process rewrites albedo every frame from the same formula it always did, so a brightened
## base would be undone within one frame anyway — and the brief for this pass was that the
## darkness is correct. Every change lives in the fields the frame loop never writes:
## roughness, normal, specular, coat, rim, backlight.
func _build_material() -> StandardMaterial3D:
	var m: StandardMaterial3D
	if _unlit_body:
		m = PBR.rubber(albedo_color, 0.18)
		_fit_grain(m, _radius * 2.0, GRAIN_ACROSS_FLAKE)
		# rubber authors its tooth against a tiling ten times finer than a body this size
		# wants, and a normal is not re-tiled by stretching — the slopes stay, the bumps get
		# bigger. Left at 0.51 the flake stops being matte grain and becomes dents in a ball.
		# This is the grain SIZED WRONG failure of the kit's own note, not a reason to
		# flatten it: the tooth stays, it is just no longer authored for a cable jacket.
		m.normal_scale = 0.30
		# THE REVERSAL. F0 = 0.08 * specular, so the old 0.0 meant no Fresnel anywhere,
		# and Fresnel at grazing incidence is the entire limb of a dark ball. 0.5 is the
		# ordinary dielectric value — obsidian's, glass's — and it costs the albedo nothing.
		m.metallic_specular = 0.50
		# The second lobe. A broad 0.89 base and a 0.18 coat are far enough apart that the
		# coat reads as one small specular the size of the lamp sitting inside a sheen the
		# size of the sphere. One lobe is a disc; two is a ball.
		m.clearcoat_enabled = true
		m.clearcoat = 0.24
		m.clearcoat_roughness = 0.18
		# The terminator. Backlight is a per-pixel wrap term — no subsurface, nothing the
		# Quest cannot afford — and at this size it lifts the dark side by a shade instead
		# of letting it fall off a cliff into the background. Kept under the albedo so it
		# cannot become a glow.
		m.backlight_enabled = true
		m.backlight = Color(0.030, 0.024, 0.046)
	else:
		m = PBR.hard_plastic(albedo_color, _gloss, 0.05)
		_fit_grain(m, _radius * 2.0, GRAIN_ACROSS_MICRO)
	PBR.edge_light(m, _rim, _rim_tint)

	# --- everything below is the legacy material, unchanged ---
	m.albedo_color = Color(
		albedo_color.r * _tint_mul,
		albedo_color.g * _tint_mul,
		albedo_color.b * _tint_mul,
		0.85 * _alpha_mul
	)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_BACK
	if _unlit_body:
		# eclipse gives nothing back. It still has to be a thing that gives nothing back.
		m.emission_enabled = false
	else:
		m.emission_enabled = true
		m.emission = emission_color
		m.emission_energy_multiplier = pulse_min * _emit_mul
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
	_add_kin_ring()
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
	# HangarKit -> PbrKit, same four arguments and the same house grey. What arrives now is
	# a dielectric coat over metal with a roughness texture and a clear film, instead of one
	# albedo at one metallic; wear stays at 0.30, one notch under painted_metal's grime
	# threshold, because a multiply-darkening pass over a dark scene is how three subtle
	# darkenings agree on black. Then the tube-sized tiling, which is the whole reason a
	# thin part looks painted rather than finished.
	var metal: StandardMaterial3D = PBR.painted_metal(Color(0.46, 0.48, 0.53), 0.30, 0.55, 0.48)
	_fit_grain(metal, CAGE_TUBE_M, GRAIN_ACROSS_TUBE)
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
	elif kind == "kin":
		# Reaches further than beacon and lands softer: attenuation 0.9 is a slower
		# falloff, so the light is still doing something at the edge of the pool rather
		# than dying at the ball. A relation extends; a beacon announces.
		lamp.light_color = emission_color.lerp(Color(0.72, 0.52, 0.95), 0.5)
		lamp.light_energy = 1.9
		lamp.omni_range = 3.4
		lamp.omni_attenuation = 0.9
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


## The make-kin gesture, and the only geometry in this file that exists for one presence
## value. Guarded on `becoming` and nowhere else, so the other four lineages — and the 312
## placements that never named a presence — cannot see it: the early return IS the contract.
##
## A thin ring lying on the floor that widens outward from the body and thins as it goes.
## It reaches; it does not enclose. It is unshaded and additive so it reads on a dark floor
## without lighting the room, and it carries no state — nothing anywhere records that a
## reach completed, because a completed relation is a measured one.
##
## Its alpha floor is 0.10 rather than 0: a still is how this project judges anything, and a
## gesture that is invisible at one phase of its cycle would be a variant the DNA critic
## calls INERT for a reason that has nothing to do with the design. It is always mid-reach.
func _add_kin_ring() -> void:
	# Cleared FIRST, before the guard. apply_grid_config() rebuilds by queue_free'ing every
	# child and calling _create_sphere() again, so a placement re-configured from becoming to
	# any other value would otherwise leave these pointing at a freed node for the frame loop
	# to write into.
	_kin_ring = null
	_kin_mat = null
	if presence != "becoming":
		return
	_kin_base_r = maxf(_radius * 1.15, 0.05)
	var ring := TorusMesh.new()
	ring.inner_radius = _kin_base_r - 0.012
	ring.outer_radius = _kin_base_r + 0.012
	ring.rings = 6
	ring.ring_segments = 40
	_kin_mat = StandardMaterial3D.new()
	_kin_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_kin_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_kin_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_kin_mat.albedo_color = Color(emission_color.r * 1.8, emission_color.g * 1.5, emission_color.b * 1.9, 0.42)
	_kin_ring = MeshInstance3D.new()
	_kin_ring.name = "KinReach"
	_kin_ring.mesh = ring
	_kin_ring.material_override = _kin_mat
	# just above the halo disc, below everything else — it belongs to the floor, not the body
	_kin_ring.position = Vector3(0, 0.02, 0)
	add_child(_kin_ring)


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
	# THE POOL'S EDGE. The alpha above is still the peak, directly under the ball, and
	# _process still drives it; the texture only says how that alpha falls off with radius.
	# A disc painted one flat value out to a hard circle is a flat region — the same fault
	# as a flat sphere, on the largest single surface this artifact owns — and it is also
	# what let the ball merge into its own shadow, because the two were the same tone with
	# a rule drawn between them. A falloff gives the floor a gradient to sit the sphere in.
	halo_mat.albedo_texture = _pool_falloff()
	halo_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Triplanar in LOCAL space, exactly one repeat across the disc's own diameter. The disc
	# spans local x,z in [-r, r], so at this scale its UV spans [-0.5, 0.5] — which wraps to
	# the texture's four CORNERS meeting at the centre of the disc. That is why the falloff
	# in _pool_falloff() is built around the corner and not the middle: it makes the pattern
	# seamless, and it keeps the mapping independent of how Godot happens to lay out a
	# CylinderMesh cap's UVs, which is not a thing to build a shipped surface on.
	halo_mat.uv1_triplanar = true
	halo_mat.uv1_world_triplanar = false
	var pool_uv: float = 1.0 / maxf(_halo_radius * 2.0, 0.02)
	halo_mat.uv1_scale = Vector3(pool_uv, pool_uv, pool_uv)
	halo_mat.uv1_triplanar_sharpness = 1.0
	halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_halo_ring.material_override = halo_mat

	# Sit just above the ground plane
	_halo_ring.position = Vector3(0, 0.01, 0)

	add_child(_halo_ring)


# One 64 px image for every placement in the project. Built on the first _ready and never
# again — 317 copies of the same gradient is the kind of cost that hides.
static var _pool_tex: ImageTexture = null

## Radial falloff for the floor pool. White RGB so the disc keeps its own colour and only
## the alpha channel is doing anything.
##
## Centred on the texture's CORNER, so it is periodic in both axes and the wrapped triplanar
## mapping in _create_halo_ring lands its peak at the middle of the disc with no seam. The
## radius comes out exact rather than approximate: at that tiling min(u, 1 - u) IS
## |x| / (2 * radius), so the two axes together give true radial distance in units of the
## disc's own radius, and the pattern is symmetric under every wrap.
##
## The curve is a smoothstep times a linear ramp rather than a plain smoothstep. Smoothstep
## alone is flat near its peak, which would have traded one uniform region for a slightly
## smaller uniform region; the ramp keeps a gradient running the whole way out while the
## smoothstep keeps the rim from ending in a visible ring.
static func _pool_falloff() -> ImageTexture:
	if _pool_tex != null:
		return _pool_tex
	var px: int = 64
	var img: Image = Image.create(px, px, false, Image.FORMAT_RGBA8)
	for y in range(px):
		for x in range(px):
			var u: float = (float(x) + 0.5) / float(px)
			var v: float = (float(y) + 0.5) / float(px)
			var dx: float = minf(u, 1.0 - u)
			var dy: float = minf(v, 1.0 - v)
			var rad: float = clampf(sqrt(dx * dx + dy * dy) * 2.0, 0.0, 1.0)
			var a: float = 1.0 - rad
			a = a * a * (3.0 - 2.0 * a)
			a = a * (0.42 + 0.58 * (1.0 - rad))
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(a, 0.0, 1.0)))
	img.generate_mipmaps()
	_pool_tex = ImageTexture.create_from_image(img)
	return _pool_tex


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
