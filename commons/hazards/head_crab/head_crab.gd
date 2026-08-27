extends MeshInstance3D
# NO class_name — preloaded by path (the loader-thread class_name race).

# ── THE HEAD CRAB (2026-08-26, Palle: "There is already a walking leg critter
# octapod other numbers of legs that can walk procedurally. use that the make
# the small head crab") ──────────────────────────────────────────────────────
#
# The octapod has eight FABRIK legs and NO GAIT — its own `_update_legs()` is a
# `pass`, so its feet are SpringArm markers that slide with the body while the
# solver bends the legs to reach them. It skates.
#
# The four-leg critter is the opposite: `four_leg_critter.gd:137 _update_gait`
# is the only true plant-and-step locomotion in this corpus. A foot PLANTS in
# world space and stays planted while the body walks away from it; when it is
# stretched past `step_threshold` it lifts, arcs over a parabola and re-plants
# ahead of its home. One leg at a time. That gait is the thing worth keeping,
# and it is what this crab walks on — the same rig scene, the same arithmetic.
#
# Two things change. It is SMALL: the authored critter is 4.4 m across the
# shoulders, and a head crab is a thing that fits on a face, so the whole rig
# is scaled and every world-space gait number is scaled with it — the gait
# constants are distances, not ratios, and leaving them alone would give a
# 40 cm animal a 1.5 m stride. And it is STEERED BY HUNGER rather than by the
# keyboard: the leg critters read Input.get_vector("move_left", ...) — the
# PLAYER's own WASD actions — so placed in a map they walk off the visitor's
# movement keys. This one looks for the visitor instead.

## THE HEAD CRAB ALREADY EXISTS (2026-08-26, Palle: "there are better
## versions"). csg_walker.gd subclasses four_leg_critter, hides its boxy body
## and builds a CSG creature through CSGBodyBuilder — and its creature_form
## DEFAULTS to "headcrab", with the leg geometry bone-skinned to the FABRIK
## chain so body and gait share one skeleton. Hand-building a dome on the bare
## rig was rebuilding what the repo had already made better.
const RIG := "res://commons/hazards/octapod_crawler/csg_four_leg_walker.tscn"

## the authored rig is 4.4 m across; 0.13 puts the crab at ~57 cm
@export var crab_scale: float = 0.15
@export var body_colour: Color = Color(0.42, 0.14, 0.20)
@export var eye_colour: Color = Color(1.0, 0.22, 0.16)
@export var detect_m: float = 9.0
@export var chase_speed: float = 0.95
@export var patrol_speed: float = 0.3
@export var turn_speed_deg: float = 150.0

@export_group("Way round")
## IT HAS NO COLLIDER AND IT NEVER WILL. This family moves by writing position;
## giving it a body would put it on a different clock from its own gait. So
## avoidance is three whiskers rather than a physics response: cast where it
## means to go, and if that is wall, go the freer way round. A wall it cannot
## get round is a wall it turns away from, which is what an animal does.
@export var avoid_on: bool = true
@export var avoid_range: float = 1.35     ## how far ahead it looks, in metres
@export var avoid_spread_deg: float = 42.0
@export var avoid_turn_deg: float = 65.0  ## how hard it steers off a blocked line
@export var avoid_eye: float = 0.14       ## whisker height above its own floor
## AS BIG AS THE LEG (2026-08-27, Palle: "add a collider to the spider that is
## as big as the leg, now it walk into to the walls"). The step test was ONE ray
## from the body's centre, so the body cleared a wall while half a metre of leg
## went through it. The animal is a DISC now, as wide as its own feet reach, and
## a step is a shape cast rather than a line — which is what a collider would
## have bought, without putting a position-driven animal on the physics clock
## where its own gait would fight it.
##
## Zero means MEASURE IT: the widest a foot ever stands from the body, taken
## from the rig once it is up, so a rescaled or re-legged spider is right
## without anybody editing a number.
@export var body_radius: float = 0.0
@export var body_radius_min: float = 0.14  ## never so fat it cannot enter a room

## IT PATHS (2026-08-27, Palle: "yes make it path"). Whiskers round an obstacle;
## they do not get out of a room. A U-shaped alcove traps a whisker-steered
## animal until it happens to wander out, which is fine for an open hall and
## wrong for anything with a corner in it.
##
## The map is a GRID, so the path is A* over a grid — Godot's own AStarGrid2D,
## on an occupancy lattice measured by ONE ray per cell. Cast down the cell's
## column: a hit near the floor is floor, a hit well above it is the top of a
## wall, and no hit at all is a hole. That single test tells the three apart
## because a grid wall is three cubes tall.
##
## The whiskers stay underneath it. A path says which way to go; the whiskers
## and the slide keep the body out of what the lattice was too coarse to see.
@export var path_on: bool = true
@export var path_cell: float = 0.45       ## lattice pitch, metres
@export var path_extent: int = 14         ## half-width in cells: 28 x 28 = 784 rays
@export var path_period: float = 0.8      ## seconds between rebuilds
@export var path_reach: float = 0.40      ## how near a waypoint counts as reached

@export_group("Bite")
## IT COULD NOT TOUCH ANYTHING (2026-08-27, Palle: "so I can see it walk, attack
## and kill the player"). The registry filed this artifact as a hazard and it
## instantiated no collider, no area and no physics body of any kind: it walked
## through the visitor and always had. The whole contract already exists one
## directory up, written and proven on octapod_crawler — proximity damage with
## a cooldown, a lunge that hits harder, three damage method names tried in
## order, then GameManager — so head_crab signs THAT rather than inventing one.
@export var can_bite: bool = true
@export var contact_damage: float = 18.0
@export var lunge_damage: float = 34.0
@export var lunge_range: float = 1.9      ## how close before it commits
@export var lunge_speed: float = 4.2      ## metres per second during the leap
@export var lunge_duration: float = 0.42
## IT DOES NOT JUMP (2026-08-27, Palle: "spider most walk around colliders and
## can not jump (at least not the first spider)"). The lunge stays — it is how
## the animal commits to a bite — but it is a flat DASH now, not a leap. Left as
## an export at zero rather than deleted, because a later spider may earn one.
@export var lunge_rise: float = 0.0       ## body lift mid-lunge; zero is a dash
@export var bite_range: float = 0.72      ## contact distance, measured FLAT
## THE BITE IS MEASURED FLAT (2026-08-27, field failure in Point_One). The first
## version used a 3-D distance and the animal crossed the room, closed to 0.78 m
## and never bit — because its own root rides BELOW the floor by design
## (position.y = _floor_y + _ride, and ride is negative), while a player body's
## origin sits above it. Almost the whole of that 0.78 m was vertical. On a bare
## bench floor the fixture happened to put both at the same height, so the
## fixture passed and the map failed. Horizontal distance decides the bite;
## height only decides whether the target is on the same storey.
@export var bite_height: float = 2.2      ## vertical reach, so it cannot bite a balcony
@export var bite_cooldown: float = 0.95

@export_group("Graft")
## THE MUSHROOM (2026-08-27, Palle: "let me throw mushrooms ... that the spider
## rather eats. And that makes it get metamorphosed in a spider plant where the
## leg becomes branched" / "it stops hunting and roots, branch by degrees").
##
## A landed mushroom outranks the visitor: the animal breaks off the hunt and
## walks to it. The FIRST one it eats roots it — it stops hunting, stops
## biting, and never moves again. Every further mushroom that lands within
## reach of the rooted plant adds ONE DEGREE of branching.
##
## The branching is the project's own L-system, not a new one: LSystemSim
## rewrites the axiom `degree` times and LSystemTurtle walks it into a single
## MultiMeshInstance3D per leg. `iterations` IS the degree, which is why the
## mechanic and the instrument fit without an adaptor.
@export var eats_mushrooms: bool = true
@export var graft_max: int = 5
@export var bait_range: float = 16.0     ## how far it will notice a mushroom
@export var feed_radius: float = 1.9     ## once rooted, what it can still reach
## EATING TAKES TIME (2026-08-27, Palle: "Let the spider look for mushrooms,
## eat, consume the mushrooms of 2 sec, loop, if no mushroom play is also
## food"). It stands over the mushroom for two seconds and then it is gone.
## Without the pause the whole loop is invisible: five mushrooms vanish in the
## time it takes to walk between them and the visitor never sees an animal
## FEEDING, only mushrooms disappearing.
@export var feed_time: float = 2.0
## IT WALKS OVER THE MUSHROOM (2026-08-27, Palle: "the spider should walk over
## the mush a suck up the mushroom though this body"). It used to stop a metre
## short and stand there, which read as an animal ignoring its dinner. It closes
## until the mushroom is UNDER it, and then the mushroom rises into the body
## over the two seconds — swallowed through the underside rather than nibbled
## from a polite distance.
@export var feed_reach: float = 0.26     ## how far it stands off before feeding
@export var mouth_height: float = 0.11   ## where the mushroom disappears into
## THE FEEDING ITSELF. Standing perfectly still for two seconds reads as a
## stalled animal, not a busy one — the mushroom moved and nothing else did.
## Three motions, all on the body and none on the feet, because the legs are
## planted and should stay planted: it settles DOWN over the food, noses into
## it, and gulps. The dip and the pitch both run on sin(u*PI), so they return
## the animal exactly to its walking pose at the end of the meal.
@export var feed_dip: float = 0.055      ## how far the body settles onto the food
@export var feed_pitch_deg: float = 11.0 ## how far it noses down
@export var feed_gulps: float = 3.0      ## swallows per meal
@export var feed_gulp: float = 0.055     ## how much the body swells on each
## IT CANNOT SEE THROUGH A WALL (2026-08-27, Palle: "The spider should not be
## able to see through the wall, they are colliders, not the spider trying to
## get to a mushroom that is on the other side of the wall but the collider
## blocks the spider and the spider is stuck in a loop"). Food is only food if
## there is a clear line to it. A mushroom behind a wall is not a target, so
## the animal never sets off toward one it cannot reach.
@export var needs_line_of_sight: bool = true
@export var sight_eye: float = 0.20      ## eye height above its own floor
## IT DOES NOT FORGET INSTANTLY. Walking round a pillar breaks the line for a
## moment; without a memory the animal would drop its food and re-choose every
## few frames, which reads as dithering rather than as hunting.
@export var sight_memory: float = 1.6
## AND THE VISITOR IS FOOD LIKE ANY OTHER ("Also the player is equally
## interesting for the spider, the nearest food object"). No ranking: it goes to
## whichever piece of food is nearest and in sight, mushroom or visitor.
@export var give_up_after: float = 4.5   ## seconds of not getting closer
@export var give_up_for: float = 7.0     ## then ignore that one for this long
## FEWER AND FATTER. The first tuning used a 0.62 step, 0.74 shrink and a
## 0.055 width, and five degrees of it came out as a pale flat comb — 243
## segments so thin and so short that the eye read one fan per leg instead of a
## branching limb. A branch is legible when its FIRST fork is as thick as the
## thing it grew out of: the leg shaft it erupts from is 0.0564 in rig units at
## bone 2, so the sprout starts at 0.11 and keeps four fifths of its width each
## level instead of three quarters.

# the gait, in the authored rig's own units — scaled to world in _ready
@export_group("Gait")
@export var step_threshold_local: float = 1.25
@export var step_height_local: float = 0.85
@export var step_duration: float = 0.08
@export var step_overshoot_local: float = 0.55
## POSTURE, exported so a variant can be handed in from outside (2026-08-26,
## Palle: "iterate and improve with multi agent many different versions").
## ride_local is the body height in RIG units; stance is how far out the feet
## plant as a fraction of the authored shoulder ring. Together with the chain
## length (6 bones, 5.00 units) they decide whether the leg bends or reaches
## straight — which is the whole open question.
@export var ride_local: float = -1.2
@export var stance: float = 1.25
## forwarded to the CSG rig BEFORE it builds itself, since its _ready reads its
## own exports once: creature_* and leg_* keys from csg_walker.gd
## THE CHOSEN ANIMAL (2026-08-26, Palle: "all black spider 3 look good! use
## that as a start and deploy it in to the game"). Variant 3 of eight —
## graphite body, brass joints, long fine legs — is the shipped default now.
## ride_local is NEGATIVE on purpose: the rig bakes a 2.2-unit shoulder height
## into its .tscn, so the only route to a low-slung body is to sink the root
## beneath the floor. Nothing is drawn at the root and position.y is re-pinned
## every frame, so it is safe — and it is what puts the knees above the shell.
@export var csg_params: Dictionary = {
	"leg_joint_style": "cylinder",
	"leg_shaft_radius": 0.075,
	"leg_hub_radius": 0.15,
	"leg_foot_radius": 0.115,
	"leg_taper": 0.62,
	"creature_atom_radius": 0.3,
	"creature_bulge_factor": 2.0,
	"creature_atom_count": 9,
	"creature_pack": 0.42,
	"creature_knee_at": 0.3,
	"creature_post_knee_drop": 2.2,
	"creature_initial_lift": 0.95,
	"creature_seed": 7,
	"creature_base_color": Color("#0f0f10"),
	"creature_accent_color": Color("#b78e47"),
}
## ── THE FINISH (2026-08-26, Palle: "make them look artificial very beautiful,
## other dark color, like fetch object") ─────────────────────────────────────
## csg_body_builder hardcodes its materials at metallic 0.15 / roughness 0.6 —
## the numbers of something grown. A manufactured object is the opposite: a
## dark body that is almost a mirror, and joints that are a different metal.
## Applied AFTER the rig has built, over every CSG shape it made, because the
## builder gives no way to hand a material in.
@export var finish_on: bool = true
@export var finish_base: Color = Color(0.062, 0.062, 0.065)     # graphite, all but black
@export var finish_accent: Color = Color(0.72, 0.56, 0.28)      # brass at every joint
@export var finish_metallic: float = 0.94
@export var finish_roughness: float = 0.16
@export var finish_accent_metallic: float = 1.0
@export var finish_accent_roughness: float = 0.12
@export var finish_glow: float = 0.0                             # accent emission

const LEG_COUNT := 4
## the authored shoulder ring: 45/135/225/315 degrees at radius 2.2, body y 2.2
const SHOULDERS: Array = [
	Vector3(1.5556, -2.2, -1.5556),
	Vector3(-1.5556, -2.2, -1.5556),
	Vector3(-1.5556, -2.2, 1.5556),
	Vector3(1.5556, -2.2, 1.5556),
]

var _rig: Node3D = null
## THE RIG'S ROOT IS NOT THE RIG (2026-08-26, found by two independent design
## agents reading the .tscn while I was tuning numbers against it). In
## csg_four_leg_walker.tscn the root CSGFourLegWalker is a bare Node3D and
## EVERYTHING — the script, the four IK chains, the SpringArms and their
## FootTargets — hangs off a "Body" child. Three consequences, all silent:
##   the foot paths resolved against the root and returned null four times, so
##   _update_gait wrote to nothing and every gait number here was inert;
##   csg_params were set() on a scriptless node, so every creature_/leg_ key
##   was dropped without a word (the typed/absent set() this repo has been
##   bitten by before);
##   set_process(false) stopped the root, not the script, so four_leg_critter
##   kept walking on its OWN defaults — a 1.5 METRE step threshold against a
##   57 cm animal, which is exactly why the legs never stepped and the body
##   dragged them straight. THAT was the stilts, not the posture numbers.
var _body: Node3D = null
var _feet: Array = []
var _planted: Array = []
var _stepping: Array = []
var _from: Array = []
var _to: Array = []
var _t: Array = []
var _step_threshold: float = 0.2
var _step_height: float = 0.13
var _step_overshoot: float = 0.07
var _target: Node3D = null
var _look_t: float = 0.0
var _patrol_angle: float = 0.0
var _patrol_t: float = 0.0
var _rng := RandomNumberGenerator.new()
var _degree: int = 0          # mushrooms eaten; 0 is an animal, 5 is a garden
var _meal: Node3D = null      # the mushroom under it right now
var _meal_t: float = 0.0      # seconds left of this meal
var _chase: Node3D = null     # the food it is walking to, whatever kind
var _chase_best: float = 1e9  # the closest it has got to it
var _chase_t: float = 0.0     # seconds since it last got closer
var _ignore: Dictionary = {}  # food it gave up on -> seconds left
var _seen_t: float = 99.0     # since it last had eyes on anything
var _sweep_shape: SphereShape3D = null
var _span_cache: float = 0.0
var _span_settled: float = 0.0
var _blocked_t: float = 0.0
var _rooted: bool = false     # the first mushroom ends the hunt, permanently
var _bait: Node3D = null      # the mushroom it is walking to
var _path: Array = []         # world waypoints, nearest first
var _path_t: float = 0.0      # time until the next rebuild
var _path_goal: Vector3 = Vector3.INF
var _bite_t: float = 0.0      # cooldown, counts down
var _lunge_t: float = 0.0     # >0 while committed to a leap
var _lunge_dir: Vector3 = Vector3.ZERO
var _floor_y: float = 0.0     # the height the artifact was PLACED at
var _floor_learned: bool = false
var _floor_settle: float = 0.0   # keeps probing until the world answers
var _ride: float = 0.29   # body height above the floor, set from crab_scale
var _stance: float = 1.0  # how far out the feet plant, as a fraction of the rig's


func _ready() -> void:
	_rng.randomize()
	# THE WHOLE ANIMAL SCALES, NOT THE RIG. Scaling the rig alone put its
	# SpringArms and FootTargets in a shrunken frame while the gait drove them
	# by WORLD position: the solver chased targets it read as fifteen units
	# away and the legs came out as metre-long spikes. Scaling the ROOT keeps
	# one frame — global_transform carries the scale into every home, and the
	# feet, the carapace and the bones all shrink together.
	scale = Vector3.ONE * crab_scale
	_patrol_angle = _rng.randf_range(0.0, TAU)
	# THE GAIT NUMBERS ARE DISTANCES. They are measured in world space by
	# distance_to, so they must shrink with the animal or a 57 cm crab takes a
	# metre-and-a-half stride and never plants a foot.
	_step_threshold = step_threshold_local * crab_scale
	_step_height = step_height_local * crab_scale
	_step_overshoot = step_overshoot_local * crab_scale
	# THE BODY RIDES AT SHOULDER HEIGHT. The rig is authored with its shoulders
	# 2.2 units above the feet; placed with its origin ON the floor, the legs
	# have to reach DOWN to a ground they are already standing on, so FABRIK
	# extends them straight and the crab drags four spikes behind it. That is
	# what the first walk frames photographed. The gait's own flat-ground
	# assumption (homes.y = 0, four_leg_critter.gd:142) makes the ride height
	# a constant, not a raycast.
	# 2.2 is the shoulder height of the AUTHORED rig, and at that ride the legs
	# reach their feet dead straight — the crab stands on four rigid stilts.
	# A crab crouches: the body comes down so the chain has to BEND, which is
	# what makes a joint read as a joint. Measured by eye against the stilts.
	_ride = ride_local * crab_scale
	_stance = stance
	_build_rig()
	set_process(true)


## Everything that is DERIVED from crab_scale, in one place so it can be run
## twice. GridInteractablesComponent calls apply_grid_config AFTER the node is
## in the tree, so _ready has already run: a token that set crab_scale changed
## the number and nothing else, and #scale:0.11 shipped an animal of 0.15 with
## the right accent. Measured before the fix: 0.882 of default size where
## 0.733 was asked for.
func _apply_scale() -> void:
	scale = Vector3.ONE * crab_scale
	_step_threshold = step_threshold_local * crab_scale
	_step_height = step_height_local * crab_scale
	_step_overshoot = step_overshoot_local * crab_scale
	_ride = ride_local * crab_scale
	_stance = stance


## Map tokens: `head_crab:0:0#scale:0.18#speed:1.2#detect:12`
func apply_grid_config(config: Dictionary) -> void:
	# A map token tunes the animal:
	#   head_crab:0:0#scale:0.11#speed:1.2#detect:12#accent:7fd8cf
	#
	# THE ACCENT HEX CARRIES NO '#'. That character is the token's own config
	# separator, so a value written as `accent:#7fd8cf` is split BEFORE the
	# parser ever sees it and arrives as two junk keys ("accent:" and "7fd8cf",
	# both true) — the colour is dropped in silence, exactly the failure mode
	# the typed-set() audit found in 54 artifacts. Bare hex is the only form
	# that survives the split, and a leading '#' is accepted anyway for a hand
	# that types one.
	if config.has("scale"):
		crab_scale = clampf(_cfg_num(config["scale"], crab_scale), 0.03, 1.0)
	if config.has("speed"):
		chase_speed = _cfg_num(config["speed"], chase_speed)
	# BOTH SPELLINGS. `detect` is not in the grid's CONFIG_PARAM_NAMES, so
	# `#detect:16` is read as a rotation of 16 degrees and the range never
	# changes — measured on this artifact's own placement in Point_One. `detect`
	# could not simply be added to that list because six origami_droideka
	# placements already use it and would change behaviour; `detection` was free.
	if config.has("detection"):
		detect_m = _cfg_num(config["detection"], detect_m)
	elif config.has("detect"):
		detect_m = _cfg_num(config["detect"], detect_m)
	if config.has("patrol"):
		patrol_speed = _cfg_num(config["patrol"], patrol_speed)
	if config.has("glow"):
		finish_glow = _cfg_num(config["glow"], finish_glow)
	if config.has("accent"):
		finish_accent = _cfg_colour(config["accent"], finish_accent)
	if config.has("damage"):
		contact_damage = _cfg_num(config["damage"], contact_damage)
		lunge_damage = contact_damage * 1.9
	if config.has("bite"):
		can_bite = str(config["bite"]).strip_edges().to_lower() not in ["0", "false", "off", "no"]
	# already built? then re-derive, or the token changed a number nobody reads
	if is_inside_tree():
		_apply_scale()
		if _body != null and is_instance_valid(_body):
			_apply_finish()


## a token value is always TEXT, and a valueless key arrives as `true` —
## float("true") is 0.0, which would silently shrink the animal to nothing
func _cfg_num(v: Variant, fallback: float) -> float:
	var s := str(v).strip_edges()
	return float(s) if s.is_valid_float() else fallback


func _cfg_colour(v: Variant, fallback: Color) -> Color:
	var s := str(v).strip_edges()
	if s.begins_with("#"):
		s = s.substr(1)
	if not Color.html_is_valid(s):
		push_warning("head_crab: '%s' is not a colour — accent unchanged" % s)
		return fallback
	return Color.html(s)


func _build_rig() -> void:
	if not ResourceLoader.exists(RIG):
		push_warning("head_crab: the four-leg rig is missing — no legs")
		return
	var ps: PackedScene = load(RIG) as PackedScene
	_rig = ps.instantiate() as Node3D
	if _rig == null:
		return
	# KEEP the rig's own script: its _ready skins the four leg chains, and
	# hand-rolling that skin produced folded garbage. Only its _process is
	# unwanted — that is the one that reads the player's WASD — so it is
	# switched off the frame after it has built itself.
	_rig.name = "Rig"
	# the node that actually carries the script and the legs
	_body = _rig.get_node_or_null("Body") as Node3D
	if _body == null:
		for c in _rig.get_children():
			if c is Node3D and (c as Node).get_script() != null:
				_body = c as Node3D
				break
	if _body == null:
		_body = _rig
	# BEFORE the tree: csg_walker._ready reads its own exports once and builds
	# the body from them, so a param set handed in afterwards shapes nothing
	for k in csg_params:
		_body.set(String(k), csg_params[k])
	add_child(_rig)
	# _ready has run for the rig by now: stop ITS gait, keep its geometry
	_body.set_process(false)
	call_deferred("_quiet_rig")
	for i in range(LEG_COUNT):
		var foot: Node = _body.get_node_or_null("SpringArm3D_%d/FootTarget_%d" % [i, i])
		if foot == null:
			push_warning("head_crab: no FootTarget_%d — the gait has nothing to drive" % i)
		_feet.append(foot)
	_planted.resize(LEG_COUNT)
	_stepping.resize(LEG_COUNT)
	_from.resize(LEG_COUNT)
	_to.resize(LEG_COUNT)
	_t.resize(LEG_COUNT)
	for i in range(LEG_COUNT):
		_stepping[i] = false
		_from[i] = Vector3.ZERO
		_to[i] = Vector3.ZERO
		_t[i] = 0.0
		_planted[i] = _home(i)


## A tapered tube down the leg's bones, skinned so FABRIK bends it. The rig
## ships bare skeletons; four_leg_critter._add_skinned_mesh does the same job
## for the big critter.
## The rig has built itself by now: stop it walking, take its body box (this
## crab has a carapace instead) and put out the orange debug foot markers.
## Every shape the builder made, re-finished. The base and the accent are told
## apart by the albedo the builder gave them — the accent is whatever is not
## the base colour — so the joint beads stay joints and the shell stays shell.
func _apply_finish() -> void:
	if not finish_on or _rig == null or not is_instance_valid(_rig):
		return
	var was_base: Color = csg_params.get("creature_base_color", Color("#d8a878"))
	var base := StandardMaterial3D.new()
	base.albedo_color = finish_base
	base.metallic = finish_metallic
	base.roughness = finish_roughness
	base.metallic_specular = 0.85
	var accent := StandardMaterial3D.new()
	accent.albedo_color = finish_accent
	accent.metallic = finish_accent_metallic
	accent.roughness = finish_accent_roughness
	accent.metallic_specular = 1.0
	if finish_glow > 0.001:
		accent.emission_enabled = true
		accent.emission = finish_accent
		accent.emission_energy_multiplier = finish_glow
	var n_base := 0
	var n_acc := 0
	for node in _rig.find_children("*", "", true, false):
		var cur: Material = null
		if node is CSGShape3D:
			cur = (node as CSGShape3D).material
		elif node is MeshInstance3D:
			cur = (node as MeshInstance3D).material_override
		else:
			continue
		var is_accent := false
		if cur is StandardMaterial3D:
			var a: Color = (cur as StandardMaterial3D).albedo_color
			# the builder tints accents away from the base; anything that is not
			# the base colour is a joint, a bead or a mark
			is_accent = (absf(a.r - was_base.r) + absf(a.g - was_base.g) + absf(a.b - was_base.b)) > 0.12
		var m: Material = accent if is_accent else base
		if node is CSGShape3D:
			(node as CSGShape3D).material = m
		else:
			(node as MeshInstance3D).material_override = m
		if is_accent:
			n_acc += 1
		else:
			n_base += 1
	print("[head_crab] finish: %d body shape(s), %d joint(s)" % [n_base, n_acc])


func _quiet_rig() -> void:
	if _rig == null or not is_instance_valid(_rig):
		return
	_rig.set_process(false)
	_rig.set_physics_process(false)
	if _body != null and is_instance_valid(_body):
		_body.set_process(false)
		_body.set_physics_process(false)
	_apply_finish()
	# the rig hangs an orange debug sphere on every foot marker; find them by
	# their PARENT rather than by a path, so a renamed rig node cannot leave
	# four glowing dots on the floor
	for m in _rig.find_children("*", "Marker3D", true, false):
		for c in (m as Node).get_children():
			if c is MeshInstance3D:
				(c as MeshInstance3D).visible = false


func _skin_leg_unused(sk: Skeleton3D, mat: Material, idx: int) -> void:
	var n: int = sk.get_bone_count()
	if n < 2:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 5
	for b in range(n - 1):
		var a: Vector3 = sk.get_bone_global_rest(b).origin
		var c: Vector3 = sk.get_bone_global_rest(b + 1).origin
		var r0: float = lerpf(0.18, 0.06, float(b) / float(maxi(1, n - 1)))
		var r1: float = lerpf(0.18, 0.06, float(b + 1) / float(maxi(1, n - 1)))
		var d: Vector3 = c - a
		if d.length() < 0.0001:
			continue
		var yv: Vector3 = d.normalized()
		var ref: Vector3 = Vector3.UP if absf(yv.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
		var xv: Vector3 = ref.cross(yv).normalized()
		var zv: Vector3 = yv.cross(xv).normalized()
		for s in range(sides):
			var a0: float = TAU * float(s) / float(sides)
			var a1: float = TAU * float(s + 1) / float(sides)
			var p00: Vector3 = a + (xv * cos(a0) + zv * sin(a0)) * r0
			var p01: Vector3 = a + (xv * cos(a1) + zv * sin(a1)) * r0
			var p10: Vector3 = c + (xv * cos(a0) + zv * sin(a0)) * r1
			var p11: Vector3 = c + (xv * cos(a1) + zv * sin(a1)) * r1
			for tri in [[p00, p10, p11], [p00, p11, p01]]:
				for v in tri:
					st.set_bones([b, 0, 0, 0])
					st.set_weights([1.0, 0.0, 0.0, 0.0])
					st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "LegSkin_%d" % idx
	mi.mesh = st.commit()
	mi.material_override = mat
	var skin := Skin.new()
	for b2 in range(n):
		skin.add_bind(b2, sk.get_bone_global_rest(b2).affine_inverse())
	sk.add_child(mi)
	mi.skin = skin
	mi.skeleton = mi.get_path_to(sk)


## The carapace: a low dome with a pair of lit eyes at the front. A head crab
## reads as a body that is mostly shell, close to the ground.
func _build_carapace() -> void:
	var dome := MeshInstance3D.new()
	dome.name = "Carapace"
	var sm := SphereMesh.new()
	sm.radius = 1.75
	sm.height = 2.35
	sm.radial_segments = 20
	sm.rings = 10
	dome.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = body_colour
	m.roughness = 0.42
	m.metallic = 0.1
	dome.material_override = m
	dome.scale = Vector3(1.0, 0.62, 1.15)
	dome.position = Vector3(0, 2.30, 0)
	add_child(dome)
	var em := StandardMaterial3D.new()
	em.albedo_color = eye_colour
	em.emission_enabled = true
	em.emission = eye_colour
	em.emission_energy_multiplier = 2.0
	for sx in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.28
		es.height = 0.56
		eye.mesh = es
		eye.material_override = em
		eye.position = Vector3(0.42 * sx, 2.42, -1.62)
		add_child(eye)


func _home(i: int) -> Vector3:
	var sh: Vector3 = SHOULDERS[i] as Vector3
	var h: Vector3 = global_transform * Vector3(sh.x * _stance, sh.y, sh.z * _stance)
	h.y = _ground_at(h)
	return h


## THE FLOOR IS NOT ALWAYS AT ZERO. Every plant used to be written to y = 0.0
## absolute, which is only correct on a map whose floor happens to sit there.
## Both arena crabs stand on structure cells of height 1 — seated at 0.5 m by
## GridCommon.surface_world_y — so their feet planted half a metre THROUGH the
## deck they were placed on. Four SpringArm3D probes hang under the body,
## unread, and this is the two-line version of what they were for: cast down,
## take the hit, fall back to the height the artifact was placed at.
func _ground_at(p: Vector3) -> float:
	return _probe_floor(p, 1.2, 3.0, _floor_y)


## cast down through p and report where the world is, or fall back
func _probe_floor(p: Vector3, up: float, down: float, fallback: float) -> float:
	if not is_inside_tree():
		return fallback
	var w := get_world_3d()
	if w == null:
		return fallback
	var space := w.direct_space_state
	if space == null:
		return fallback
	var base: float = _floor_y if _floor_learned else p.y
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(p.x, base + up, p.z), Vector3(p.x, base - down, p.z))
	q.collision_mask = 1
	var hit: Dictionary = space.intersect_ray(q)
	if hit.is_empty():
		return fallback
	return float((hit["position"] as Vector3).y)


## THE WAY TO A PLACE, as a list of world waypoints. Rebuilt at most every
## path_period, and immediately when the goal has moved more than one cell.
## Returns the heading to steer, or INF when it has no opinion and the caller
## should aim straight at the goal.
func _path_yaw(goal: Vector3, delta: float) -> float:
	if not path_on:
		return INF
	_path_t -= delta
	var moved: bool = _path_goal == Vector3.INF or Vector2(goal.x - _path_goal.x, goal.z - _path_goal.z).length() > path_cell
	if _path_t <= 0.0 or moved:
		_path_t = path_period
		_path_goal = goal
		_repath(goal)
	# drop waypoints already reached
	while not _path.is_empty():
		var wp: Vector3 = _path[0]
		if Vector2(wp.x - global_position.x, wp.z - global_position.z).length() < path_reach:
			_path.remove_at(0)
		else:
			break
	if _path.is_empty():
		return INF
	var to: Vector3 = _path[0] - global_position
	to.y = 0.0
	if to.length() < 0.01:
		return INF
	return atan2(-to.x, -to.z)


## ONE RAY PER CELL. Down the column from well above the floor to well below it:
## a hit near the floor is floor, a hit well above is the top of a wall, and no
## hit is a hole. A grid wall is three cubes tall, which is what makes the three
## distinguishable by height alone.
func _repath(goal: Vector3) -> void:
	_path.clear()
	if not is_inside_tree():
		return
	var w := get_world_3d()
	if w == null:
		return
	var space := w.direct_space_state
	if space == null:
		return
	var here := Vector2i(int(floor(global_position.x / path_cell)), int(floor(global_position.z / path_cell)))
	var there := Vector2i(int(floor(goal.x / path_cell)), int(floor(goal.z / path_cell)))
	var half := path_extent
	var region := Rect2i(here.x - half, here.y - half, half * 2 + 1, half * 2 + 1)
	if not region.has_point(there):
		# the goal is outside what it can see; walk toward it and rebuild later
		return
	var grid := AStarGrid2D.new()
	grid.region = region
	grid.cell_size = Vector2(path_cell, path_cell)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var solid := 0
	for cx in range(region.position.x, region.end.x):
		for cy in range(region.position.y, region.end.y):
			var wx: float = (float(cx) + 0.5) * path_cell
			var wz: float = (float(cy) + 0.5) * path_cell
			var q := PhysicsRayQueryParameters3D.create(
				Vector3(wx, _floor_y + 1.6, wz), Vector3(wx, _floor_y - 1.0, wz))
			q.collision_mask = 1
			var hit: Dictionary = space.intersect_ray(q)
			var ok: bool = not hit.is_empty() and absf(float((hit["position"] as Vector3).y) - _floor_y) < 0.35
			if not ok:
				grid.set_point_solid(Vector2i(cx, cy), true)
				solid += 1
	# the cell it is standing in and the one it is going to are never solid,
	# or A* refuses before it starts — the animal is not the obstacle
	grid.set_point_solid(here, false)
	grid.set_point_solid(there, false)
	var ids: Array = grid.get_id_path(here, there)
	for i in range(1, ids.size()):
		var c: Vector2i = ids[i]
		_path.append(Vector3((float(c.x) + 0.5) * path_cell, _floor_y, (float(c.y) + 0.5) * path_cell))


## THE STEP ITSELF IS REFUSED, not just the heading. Steering alone left the
## animal inside the wall on 31 of 218 samples — 14 per cent — because the turn
## is a lerp and it keeps walking forward while it comes about, so it clips the
## corner it is turning away from. This is collide-and-slide without a body:
## cast the step, and if it would end in a wall, slide ALONG the wall instead of
## stopping dead, which is what keeps it moving round a corner rather than
## grinding into it.
func _slide(step: Vector3) -> Vector3:
	if not avoid_on or step.length() < 0.0001 or not is_inside_tree():
		return step
	var w := get_world_3d()
	if w == null:
		return step
	var space := w.direct_space_state
	if space == null:
		return step
	var r: float = _span()
	if r <= 0.0:
		return step
	# THE BALL MUST CLEAR THE FLOOR. Centred at avoid_eye + r/2 a 0.40 m sphere
	# reaches from -0.06 to 0.74 — it starts INSIDE the ground, and cast_motion
	# on a shape that already overlaps returns zero every time. The animal read
	# as blocked in every direction and spent its life crab-walking sideways: it
	# stopped getting round a plain wall and started passing THROUGH one, which
	# is how a fix for walking into walls became a fix for walking through them.
	var from := Vector3(global_position.x, _floor_y + r + 0.03, global_position.z)
	var free: float = _sweep(space, from, step, r)
	# HUGGING IS ITS OWN LOOP. Sliding along a wall is right for getting round a
	# corner and wrong as a way of life: measured in a pocket, the animal spent
	# 55.8% of its samples pressed against the back wall, sliding one way then
	# the other. If it has not been able to go where it is pointing for a couple
	# of seconds it turns around, which is what an animal does at a dead end.
	if free >= 0.999:
		_blocked_t = 0.0
		return step
	_blocked_t += get_process_delta_time()
	if _blocked_t > 1.8:
		_blocked_t = 0.0
		_patrol_angle = rotation.y + PI * _rng.randf_range(0.6, 1.4)
		_path.clear()
	# most of the way is still forward, and forward is what makes progress
	if free > 0.35:
		return step * free * 0.9
	# properly blocked: take whichever way along the wall gets further, which is
	# what carries it round a corner instead of grinding into one
	var side := Vector3(-step.z, 0.0, step.x).normalized() * step.length()
	var l: float = _sweep(space, from, side, r)
	var rgt: float = _sweep(space, from, -side, r)
	var best: float = maxf(l, rgt)
	if best <= free:
		return step * free        # an inside corner: creep, and keep turning
	return (side if l > rgt else -side) * best * 0.9


## How far along `motion` the animal's own disc can go, as a fraction. A sphere
## the width of its stance, swept — the whole point being that the LEGS are what
## hits a wall first, not the body.
func _sweep(space: PhysicsDirectSpaceState3D, from: Vector3, motion: Vector3, r: float) -> float:
	if _sweep_shape == null:
		_sweep_shape = SphereShape3D.new()
	_sweep_shape.radius = r
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _sweep_shape
	q.transform = Transform3D(Basis(), from)
	q.motion = motion
	q.collision_mask = 1
	var res: Array = space.cast_motion(q)
	if res.size() < 2:
		return 1.0
	return float(res[0])


## HOW WIDE THE ANIMAL IS, from the shoulders rather than from the feet.
##
## The first version measured the live feet and kept the widest it had seen —
## which grows. For the first seconds after a spawn the legs are still folding
## out, so the disc was the 0.14 minimum, the animal walked to within 0.14 m of
## a wall, and THEN the disc inflated to 0.40 around it. It was inside the wall
## without ever having moved into one, and a sweep from inside reports blocked
## in every direction, so it could only crab sideways along the face. Seven
## samples in a pocket, and no way to explain them from the movement code.
##
## The shoulder ring is a constant of the rig — 1.5556 in x and z, so 2.2 out
## from the middle — and the feet plant under it. Scale it and it is right from
## the first frame and never changes.
const SHOULDER_R: float = 2.2

func _span() -> float:
	if body_radius > 0.0:
		return body_radius
	return maxf(body_radius_min, SHOULDER_R * _stance * crab_scale)


## THREE WHISKERS. Cast along the heading it wants and 42 degrees either side;
## if the middle is clear it keeps its heading, and if it is not it takes
## whichever side sees further. Both sides blocked is a corner, and a corner is
## a turn away rather than a nudge.
##
## Returns the yaw it should actually steer to.
func _way_round(want_yaw: float) -> float:
	if not avoid_on or not is_inside_tree():
		return want_yaw
	# A PATH OUTRANKS A WHISKER. Measured in the U trap: with A* on, the animal
	# left the pocket and then never arrived — 40 s of steering against its own
	# route, because a whisker reading 1.35 m ahead sees the arm it has to hug
	# and turns off the gap it was heading for. While a path is held the
	# whiskers are pulled in to near-contact, where they do the job the lattice
	# is too coarse for and nothing else.
	var look: float = avoid_range * (0.42 if not _path.is_empty() else 1.0)
	var w := get_world_3d()
	if w == null:
		return want_yaw
	var space := w.direct_space_state
	if space == null:
		return want_yaw
	var from := Vector3(global_position.x, _floor_y + avoid_eye, global_position.z)
	var spread: float = deg_to_rad(avoid_spread_deg)
	var ahead: float = _free(space, from, want_yaw, look)
	if ahead >= look:
		return want_yaw
	var left: float = _free(space, from, want_yaw + spread, look)
	var right: float = _free(space, from, want_yaw - spread, look)
	if left < look * 0.5 and right < look * 0.5:
		return want_yaw + PI * 0.55        # a corner: come about
	var turn: float = deg_to_rad(avoid_turn_deg)
	return want_yaw + (turn if left > right else -turn)


## how far it can see along a heading, capped at avoid_range
func _free(space: PhysicsDirectSpaceState3D, from: Vector3, yaw: float, look: float) -> float:
	var dir := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * look)
	q.collision_mask = 1
	var hit: Dictionary = space.intersect_ray(q)
	if hit.is_empty():
		return look
	return from.distance_to(hit["position"] as Vector3)


## CAN IT SEE THAT. One ray, eye height to eye height, against the world only.
## A wall between the animal and a thing means the thing is not there as far as
## the animal is concerned — which is the whole of the fix for walking into a
## wall forever because a mushroom was visible through it.
func _sees(at: Vector3) -> bool:
	if not needs_line_of_sight or not is_inside_tree():
		return true
	var w := get_world_3d()
	if w == null:
		return true
	var space := w.direct_space_state
	if space == null:
		return true
	var from := Vector3(global_position.x, _floor_y + sight_eye, global_position.z)
	var to := Vector3(at.x, _floor_y + sight_eye, at.z)
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1
	return space.intersect_ray(q).is_empty()


## THE NEAREST FOOD IN SIGHT, of any kind. Returns {node, bait}.
##
## The visitor sits at the same table as the mushrooms now: there is no ranking
## left, only distance and line of sight. That is a smaller rule than the one it
## replaced and it says the same thing about the animal — it is not choosing
## between a meal and a hunt, it is going to the nearest thing it can eat.
func _nearest_food() -> Dictionary:
	var tree := get_tree()
	if tree == null:
		return {}
	_seen_t += get_process_delta_time()
	var reach: float = maxf(detect_m, bait_range)
	var best: Node3D = null
	var best_d: float = reach
	var best_bait := false
	if eats_mushrooms and not _rooted:
		for n in tree.get_nodes_in_group("spider_bait"):
			if not (n is Node3D) or not is_instance_valid(n) or _ignore.has(n):
				continue
			if n.has_method("is_bait") and not bool(n.call("is_bait")):
				continue
			var p: Vector3 = (n as Node3D).global_position
			var d: float = global_position.distance_to(p)
			if d < best_d and _sees(p):
				best_d = d
				best = n as Node3D
				best_bait = true
	if not _rooted:
		for g in ["player", "player_body", "em_walker"]:
			for n2 in tree.get_nodes_in_group(g):
				if not (n2 is Node3D) or not is_instance_valid(n2) or _ignore.has(n2):
					continue
				var p2: Vector3 = (n2 as Node3D).global_position
				var d2: float = global_position.distance_to(p2)
				if d2 < best_d and _sees(p2):
					best_d = d2
					best = n2 as Node3D
					best_bait = false
	if best != null:
		_seen_t = 0.0
		return {"node": best, "bait": best_bait, "dist": best_d}
	# nothing in sight: hold what it was already going to, briefly
	if _chase != null and is_instance_valid(_chase) and _seen_t < sight_memory:
		if global_position.distance_to(_chase.global_position) < reach:
			return {"node": _chase, "bait": _chase.is_in_group("spider_bait"), "dist": 0.0}
	return {}


## GIVE UP ON WHAT IT CANNOT REACH. Line of sight stops it setting off toward a
## mushroom through a wall; this stops it grinding at one it CAN see and cannot
## get to — across a pit, behind glass, up a step. If it has not got closer for
## give_up_after seconds it ignores that one for a while and looks elsewhere,
## which is what breaks the loop Palle watched.
func _watch_progress(food: Node3D, delta: float) -> void:
	if food == null:
		_chase = null
		return
	var d: float = global_position.distance_to(food.global_position)
	if food != _chase:
		_chase = food
		_chase_best = d
		_chase_t = 0.0
		return
	if d < _chase_best - 0.30:
		_chase_best = d
		_chase_t = 0.0
		return
	_chase_t += delta
	if _chase_t > give_up_after:
		_ignore[food] = give_up_for
		print("[head_crab] gave up on %s — no closer than %.2f m in %.1f s"
			% [food.name, _chase_best, give_up_after])
		_chase = null
		_chase_t = 0.0


func _age_grudges(delta: float) -> void:
	if _ignore.is_empty():
		return
	for k in _ignore.keys():
		if not is_instance_valid(k):
			_ignore.erase(k)
			continue
		_ignore[k] = float(_ignore[k]) - delta
		if float(_ignore[k]) <= 0.0:
			_ignore.erase(k)


## Stand over it and start feeding. Nothing is consumed yet — a mushroom being
## eaten is still on the floor, and a visitor who is quick can walk over and
## take it back out from under the animal.
func _begin_meal(m: Node3D) -> void:
	if m == null or not is_instance_valid(m):
		return
	_meal = m
	_meal_t = feed_time
	_lunge_t = 0.0
	if m.has_method("begin_absorb"):
		m.call("begin_absorb")


## Draw it up through the underside. Not a tween: the animal is still standing
## on its own gait and may shuffle, and a tween to a fixed point would leave the
## mushroom hanging in the air behind it.
func _swallow(delta: float) -> void:
	var m: Node3D = _meal
	if m == null or not is_instance_valid(m):
		return
	var mouth := Vector3(global_position.x, _floor_y + mouth_height, global_position.z)
	var k: float = 1.0 - exp(-5.0 * delta)
	m.global_position = m.global_position.lerp(mouth, k)
	var left: float = clampf(_meal_t / maxf(0.01, feed_time), 0.0, 1.0)
	m.scale = Vector3.ONE * maxf(0.04, left * left)

	# and the animal feeds. `u` runs 0 -> 1 across the meal; every motion is
	# shaped by sin(u*PI) so it begins and ends at the walking pose with no
	# snap, whatever the meal is interrupted by.
	var u: float = 1.0 - left
	var arc: float = sin(u * PI)
	position.y = _floor_y + _ride - feed_dip * arc
	rotation.x = -deg_to_rad(feed_pitch_deg) * arc
	var gulp: float = sin(u * TAU * feed_gulps) * feed_gulp * arc
	scale = Vector3.ONE * crab_scale * (1.0 + gulp)


## Two seconds later. THE ROOTING MOVED TO THE END: Palle's earlier ruling was
## that a mushroom roots it, and the new one is that it eats, loops, and hunts
## the visitor when there is nothing left — which cannot both be true of the
## FIRST mushroom, because a rooted animal cannot walk to a second. So it eats
## its way up the degrees on its feet and roots when it is full. A garden is
## what a fed spider becomes, not what one mushroom makes.
func _finish_meal() -> void:
	# back to the walking pose, exactly, whatever the meal ended as
	rotation.x = 0.0
	scale = Vector3.ONE * crab_scale
	position.y = _floor_y + _ride
	var m: Node3D = _meal
	_meal = null
	_bait = null
	if m == null or not is_instance_valid(m) or not m.has_method("consume"):
		return                       # somebody picked it up while it fed
	var got: int = int(m.call("consume", self))
	if got <= 0:
		return
	_degree = mini(graft_max, _degree + got)
	if _degree >= graft_max:
		_root()
	print("[head_crab] ate a mushroom — degree %d of %d%s" % [
		_degree, graft_max, " — rooted, it is a plant now" if _rooted else ""])


## IT STOPS HUNTING, PERMANENTLY. Not a mode it can leave: no path sets these
## back. can_bite goes first because the bite is a pure distance test and would
## otherwise keep firing at a visitor who walks up to look at the plant.
func _root() -> void:
	_rooted = true
	can_bite = false
	_target = null
	_lunge_t = 0.0
	patrol_speed = 0.0
	chase_speed = 0.0


## THE BRANCHES ARE GONE (2026-08-27, Palle: "remove the branches from the
## spider add eating animation"). The L-system sprouts — one MultiMeshInstance3D
## per leg, 3^degree segments, rebuilt at every meal — were removed rather than
## switched off, because an export nobody sets is a way of carrying a feature
## around without admitting it is not in the game. The degrees themselves stay:
## they still count the meals and they still decide when it roots. Recovering
## the branching is one revert of this commit.


## THE BITE. Proximity, not a collider: this animal moves by writing position
## every frame and owns no physics body, so a contact test is a distance test —
## the same technique octapod_crawler uses for the same reason.
func _try_bite() -> void:
	if not can_bite or _bite_t > 0.0:
		return
	if _target == null or not is_instance_valid(_target):
		return
	if not _bites(_target):
		return
	var off: Vector3 = _target.global_position - global_position
	if absf(off.y) > bite_height:
		return
	off.y = 0.0
	if off.length() > bite_range:
		return
	var dmg: float = lunge_damage if _lunge_t > 0.0 else contact_damage
	if _damage(_target, dmg):
		_bite_t = bite_cooldown
		_lunge_t = 0.0


## IT BITES ON BOTH LANES NOW (2026-08-27, Palle: "we should put the spider in
## the museum"). It used to hunt the museum's walker and deal nothing, because
## damage routes through GameManager.apply_health_damage, which REPOSITIONS the
## target to the map's spawn point — and a 4.8 km building has no such spawn.
## The museum turned out to own a death of its own already (on_lethal_touch,
## the same one the burning pools call), so the exemption is gone: on the grid
## it takes health, in the museum it calls the museum.
func _bites(node: Node) -> bool:
	return node is Node3D


func _damage(target: Node, amount: float) -> bool:
	if target is Node3D and (target as Node3D).is_in_group("em_walker"):
		var m: Node = _museum_over(target)
		if m != null:
			m.call("walker_bitten", global_position)
			return true
		return false      # a walker with no museum over it is a probe, not a visitor
	for meth in ["take_damage", "apply_damage", "apply_health_damage"]:
		if target.has_method(meth):
			target.call(meth, amount)
			return true
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("apply_health_damage"):
		gm.call("apply_health_damage", amount)
		return true
	return false


## the museum is whichever ancestor of the walker answers to a bite — found by
## walking up rather than by group, because the walker is parented under it
func _museum_over(node: Node) -> Node:
	var cur: Node = node
	while cur != null:
		if cur.has_method("walker_bitten"):
			return cur
		cur = cur.get_parent()
	for n in get_tree().root.get_children():
		if n.has_method("walker_bitten"):
			return n
	return null


## The visitor, on whichever lane is running. The museum's walker is in group
## em_walker ONLY and is deliberately not a player_body, so it is named here.
func _find_target() -> void:
	var tree := get_tree()
	if tree == null:
		return
	# only what it can actually see — _nearest_food is the usual route in, and
	# this stays as the fallback for a frame where nothing was chosen
	for g in ["player", "player_body", "em_walker"]:
		for n in tree.get_nodes_in_group(g):
			if n is Node3D and _sees((n as Node3D).global_position):
				_target = n as Node3D
				return
	_target = null


func _process(delta: float) -> void:
	# THE FLOOR IS LEARNED ON FRAME ONE, NOT IN _ready. Artifacts are seated on
	# the floor surface by the grid AFTER instantiation (GridCommon.surface_world_y),
	# so a height read in _ready is the height before placement — zero.
	if not _floor_learned:
		_floor_learned = true
		# LOOK FOR THE FLOOR, do not assume the placed height IS the floor.
		# Two things defeat that assumption, and both bit. A token written
		# `head_crab:180:0` sets an explicit y-offset of zero, and the grid's
		# auto-grounding is gated on the override being ABSENT rather than on
		# its value — so the artifact is never grounded at all. And even when
		# it IS grounded, grounding happens on a deferred call while this
		# _process pins position.y every frame, so the animal overwrites its
		# own grounding on the next tick. Measured in Point_One: body at
		# -0.18 on a floor whose surface is 0.5, feet correctly on the floor,
		# body two thirds of a metre under them.
		_floor_y = global_position.y
	# AND KEEP LOOKING, for two seconds. The grid's structure bodies are not in
	# the physics space on the frame this artifact first runs: a ray cast then
	# hits nothing and the fallback is the placed height, which in Point_One is
	# zero against a floor whose surface is 0.5. Measured: body -0.180, feet
	# 0.000, floor 0.500 — the animal a half metre into the ground it stands on.
	if _floor_settle < 2.0:
		_floor_settle += delta
		var found: float = _probe_floor(global_position, 2.5, 5.0, INF)
		if found < INF:
			_floor_y = found
			_floor_settle = 99.0
	_look_t += delta
	if _look_t > 0.5:
		_look_t = 0.0
		if _target == null or not is_instance_valid(_target):
			_find_target()
	# ── steer: toward the visitor if it is near, otherwise wander ──────────
	var want_yaw: float = rotation.y
	var speed: float = patrol_speed
	_bite_t = maxf(0.0, _bite_t - delta)

	# ── A MEAL STOPS EVERYTHING ───────────────────────────────────────────
	if _meal_t > 0.0:
		_meal_t -= delta
		_swallow(delta)              # the mushroom rises into the body
		_update_gait(delta)          # and the legs keep their stance over it
		if _meal_t <= 0.0:
			_finish_meal()
		return

	# ── ONE TABLE. A mushroom and a visitor are both food, and the nearest one
	# in sight wins — no ranking, and nothing behind a wall is on the table.
	_age_grudges(delta)
	var pick: Dictionary = _nearest_food()
	var food: Node3D = pick.get("node")
	var is_bait: bool = bool(pick.get("bait", false))
	_watch_progress(food, delta)
	if food != null and not is_bait:
		_target = food            # the visitor: the hunt below takes it from here
	if food != null and is_bait and not _rooted:
		_bait = food
		if true:
			var bd: Vector3 = _bait.global_position - global_position
			bd.y = 0.0
			if bd.length() <= feed_reach:
				_begin_meal(_bait)
				return
			else:
				# break off the hunt and go for it, by whatever way round there is
				var byaw: float = _path_yaw(_bait.global_position, delta)
				if byaw == INF:
					byaw = atan2(-bd.x, -bd.z)
				rotation.y = lerp_angle(rotation.y, _way_round(byaw),
					minf(1.0, deg_to_rad(turn_speed_deg) * delta))
				position += _slide(-basis.z.normalized() * chase_speed * delta)
				position.y = _floor_y + _ride
				_update_gait(delta)
				return
	if _rooted:
		# A ROOTED PLANT DOES NOT WALK. The gait is left running on purpose:
		# with no movement no home drifts past the step threshold, so no foot
		# ever lifts, and the legs hold exactly the stance they rooted in.
		_update_gait(delta)
		return

	if _target != null and is_instance_valid(_target):
		var to: Vector3 = _target.global_position - global_position
		to.y = 0.0
		var d: float = to.length()
		if d < detect_m and d > 0.30:
			# A PATH FIRST, the straight line only if there is none. The whiskers
			# still run underneath: a lattice at 0.45 m cannot see a table leg.
			var pyaw: float = _path_yaw(_target.global_position, delta)
			want_yaw = pyaw if pyaw != INF else atan2(-to.x, -to.z)
			speed = chase_speed
			# IT USED TO STOP AT 0.35 m AND STAND THERE. That was the whole
			# attack: walk up to the visitor and wait. Inside lunge_range it
			# now commits — a fixed-duration leap along the direction it had
			# when it decided, so a visitor who steps aside is missed.
			if can_bite and _lunge_t <= 0.0 and _bite_t <= 0.0 and d <= lunge_range and _bites(_target):
				_lunge_t = lunge_duration
				_lunge_dir = to.normalized()
		elif d <= 0.30:
			speed = 0.0
	if _lunge_t > 0.0:
		_lunge_t = maxf(0.0, _lunge_t - delta)
		want_yaw = atan2(-_lunge_dir.x, -_lunge_dir.z)
		speed = lunge_speed
	if is_equal_approx(speed, patrol_speed):
		_patrol_t += delta
		if _patrol_t >= 3.0:
			_patrol_t = 0.0
			_patrol_angle += _rng.randf_range(-PI * 0.5, PI * 0.5)
		want_yaw = _patrol_angle
	want_yaw = _way_round(want_yaw)
	rotation.y = lerp_angle(rotation.y, want_yaw, minf(1.0, deg_to_rad(turn_speed_deg) * delta))
	if speed > 0.0:
		# NORMALIZE. basis carries the root's 0.13 scale, so -basis.z is 0.13
		# long and the crab walked at an eighth of its speed — measured: 0.79 m
		# where it should have covered four.
		position += _slide(-basis.z.normalized() * speed * delta)
	position.y = _floor_y + _ride
	if lunge_rise > 0.0 and _lunge_t > 0.0 and lunge_duration > 0.0:
		# only if something ever sets a rise: sin over the whole duration peaks
		# in the middle and returns the body to its ride height
		var u: float = 1.0 - (_lunge_t / lunge_duration)
		position.y += sin(u * PI) * lunge_rise
	_update_gait(delta)
	_try_bite()


## PLANT AND STEP — four_leg_critter.gd:137, faithfully. A foot holds its world
## position while the body walks off it; the one that is furthest past the
## threshold lifts, arcs, and re-plants ahead of its home. One at a time, which
## is what makes it read as walking rather than sliding.
func _update_gait(delta: float) -> void:
	if _feet.size() < LEG_COUNT:
		return
	var homes: Array = []
	for i in range(LEG_COUNT):
		homes.append(_home(i))
	for i in range(LEG_COUNT):
		if _stepping[i]:
			_t[i] += delta / maxf(0.01, step_duration)
			if _t[i] >= 1.0:
				_t[i] = 1.0
				_stepping[i] = false
				_planted[i] = _to[i]
	var any := false
	for i in range(LEG_COUNT):
		if _stepping[i]:
			any = true
			break
	if not any:
		# DIAGONAL PAIRS — the trot. four_leg_critter steps ONE leg at a time,
		# and at this size that is arithmetically impossible: a cycle of four
		# single steps takes 0.88 s, in which a hunting crab covers 1.3 m, six
		# times its own stride. The legs can never catch up, and the first walk
		# frames photographed exactly that — four spikes dragged behind the
		# body. The file's OWN identity block already says what the answer is:
		#   "quadruped_gait(t) = diagonal_pairs(FL+BR, FR+BL)"
		#   "diagonal pairing discovered not designed"
		# The claim was in the header and never in the code. Opposite corners
		# swing together, which halves the cycle and is what a trotting animal
		# actually does.
		var pairs: Array = [[0, 2], [1, 3]]
		var best_pair: Array = []
		var best_d := 0.0
		for pr in pairs:
			var d: float = maxf((_planted[pr[0]] as Vector3).distance_to(homes[pr[0]]),
				(_planted[pr[1]] as Vector3).distance_to(homes[pr[1]]))
			if d > _step_threshold and d > best_d:
				best_d = d
				best_pair = pr
		if not best_pair.is_empty():
			var fwd: Vector3 = -global_transform.basis.z.normalized()
			for li in best_pair:
				_stepping[li] = true
				_t[li] = 0.0
				_from[li] = _planted[li]
				var tgt: Vector3 = (homes[li] as Vector3) + fwd * _step_overshoot
				tgt.y = _ground_at(tgt)
				_to[li] = tgt
	for i in range(LEG_COUNT):
		var foot: Node = _feet[i]
		if foot == null or not is_instance_valid(foot):
			continue
		var pos: Vector3
		if _stepping[i]:
			var t: float = _t[i]
			pos = (_from[i] as Vector3).lerp(_to[i], t * t * (3.0 - 2.0 * t))
			pos.y += _step_height * (4.0 * t * (1.0 - t))   # the parabola
		else:
			pos = _planted[i]
		(foot as Node3D).global_position = pos
