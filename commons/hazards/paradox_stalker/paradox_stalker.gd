# @identity
# essence: self_reference(t) -> contradiction(t) -- creature that contradicts itself, two ghosts swapping
# desire: two ghostly forms alternating reality -- the liar paradox given a body and a lunge
# critical_parameter: _a_is_real -- which ghost is real; swap_timer oscillates; only real ghost can be hit
# triggers: swap_timer alternates real/ghost; lunge_timer drives attacks; wrong ghost is invulnerable
# emerges: self-reference as combat -- the paradox is not a puzzle to solve but a state to survive
# needs: HazardCreatureBase [has]; dual ghost nodes [has]; swap logic [has]; lunge [has]; VR interaction [missing]
# relationships: embodies foundationscrisis; pairs with escher_stairwalker (logical vs geometric paradox)
# truth: the creature that contradicts itself cannot be defeated by consistency -- act in paradox.

extends HazardCreatureBase
class_name ParadoxStalker
## Foundations Crisis hazard — a creature that contradicts itself.
## Two overlapping ghost silhouettes swap which is "real."
## Zeno's paradox: halves the distance but never arrives.
## Teaches paradoxes, Gödel, limits of formalization.

@export_group("Paradox")
@export var ghost_separation: float = 0.6
@export var swap_interval: float = 3.0
@export var zeno_chance: float = 0.15
@export var lunge_speed: float = 5.0
@export var lunge_duration: float = 0.4

@export_group("Appearance")
@export var ghost_a_color: Color = Color(0.8, 0.2, 0.9, 0.5)
@export var ghost_b_color: Color = Color(0.2, 0.8, 0.9, 0.5)
@export var real_emission: Color = Color(1.0, 0.4, 1.0)


# ── DNA (stage 2) ────────────────────────────────────────────────────────
# --- DNA (stage 2, promoted 2026-08-03) ---
# THE SWAP IS TIME-DOMAIN AND A STILL CANNOT SEE IT. swap_interval, zeno_chance,
# lunge_speed and lunge_duration are all rates and none of them is a photograph. What a
# photograph DOES see is how many bodies are standing there and whether anything in the
# frame says which of them is real. Those two are not decoration around the paradox —
# between them they ARE the paradox, and both were hard-coded.
@export_group("DNA")

## AXIS — HOW MANY BODIES CLAIM TO BE THE CREATURE? Two was written into _build_mesh three
## times over: two Node3Ds, two materials, two offsets at +/- separation/2. Two is the
## liar's minimum — the smallest number of positions between which a claim can alternate
## and never settle. It is not the only number, and every other number argues something
## else about what self-reference does to a thing.
##
##   one     a single silhouette at the origin. There is nothing to alternate between, so
##           there is no contradiction to survive: the creature is simply itself, and
##           _on_damaged's coin flip (1/n) resolves to "you always hit it"
##   pair    THE SHIPPED stalker, byte for byte: A at +sep/2 x, B at -sep/2 x, magenta
##           and cyan, one lit and one dim. This statement is false
##   triad   three, on a ring. A majority now exists — the contradiction stops being a
##           contradiction and becomes a VOTE, which is how formal systems usually escape
##           one, and it costs the paradox everything it had
##   chorus  five, on a ring. No claim can be located at all; the question "which is real"
##           has become a question about a crowd, which is not the same question
##
## Deterministic by construction: the ring is a cosine, not a randf, so four variants are
## four photographs of one creature. Two is special-cased to the literal shipped vectors
## rather than routed through the ring formula, so the default carries no float drift.
@export_enum("one", "pair", "triad", "chorus") var census: String = "pair"

## AXIS — HOW DOES THE CREATURE SAY WHICH BODY IS REAL? Today it says so three ways at
## once, all hard-coded: the real one glows, the false one drops to 30% alpha, and a
## billboard overhead reads `REAL: A`. That triple redundancy is a choice about how
## legible a contradiction is allowed to be, and it is the difference between a paradox
## posed and a paradox merely suffered.
##
## NOT the furniture family's `tell` (mark|none|ghost|exemplar), which asks how a puzzle
## reveals its SOLUTION. This artifact has no solution state to reveal — the answer it
## would be revealing is the one that changes every three seconds — so it takes its own
## word and its own ladder, and the two families are not comparable.
##
##   placard  THE SHIPPED stalker: glow on the real one, 30% alpha on the false one, and
##            the overhead billboard naming it. The contradiction, fully captioned
##   glow     the same lit/dim asymmetry, no billboard. You can see which one it means;
##            nothing in the world states it. Visible, unnamed
##   none     identical bodies. Same colour, same alpha, no emission, no text: the two
##            claimants are photographically indistinguishable and the creature declines
##            to adjudicate itself. This is the liar taken at its word
##   all      every body lit at full and a `REAL` placard over each. The contradiction is
##            not hidden and not resolved — it is asserted out loud, by everyone at once
@export_enum("placard", "glow", "none", "all") var claim: String = "placard"

## Allow-lists for the map-token path. An unrecognised token leaves the value alone.
const CENSUSES: PackedStringArray = ["one", "pair", "triad", "chorus"]
const CLAIMS: PackedStringArray = ["placard", "glow", "none", "all"]
const GHOST_LETTERS: PackedStringArray = ["A", "B", "C", "D", "E"]

# State
var _ghost_a: Node3D = null
var _ghost_b: Node3D = null
var _a_is_real: bool = true
var _real_index: int = 0
var _swap_timer: float = 0.0
var _lunge_timer: float = 0.0
var _is_lunging: bool = false
var _lunge_dir: Vector3 = Vector3.ZERO
var _mat_a: StandardMaterial3D
var _mat_b: StandardMaterial3D
var _label: Label3D = null
var _ghost_a_offset: Vector3 = Vector3.ZERO
var _ghost_b_offset: Vector3 = Vector3.ZERO

# The census, held as arrays. Under the default `pair` these are exactly two entries long
# and _ghost_a / _ghost_b / _mat_a / _mat_b alias entries 0 and 1, so nothing that reads
# the old names reads anything new.
var _ghosts: Array[Node3D] = []
var _mats: Array[StandardMaterial3D] = []
var _offsets: Array[Vector3] = []
var _labels: Array[Label3D] = []


func _on_ready() -> void:
	add_to_group("paradox_enemy")


func _create_materials() -> void:
	# EARLIEST subclass hook the base calls (before _build_collision and _build_mesh), so
	# the census is resolved here — _build_mesh reads _mats.size() and nothing else.
	var n: int = _ghost_count()
	_mats.clear()
	for i in range(n):
		var gi: int = int(i)
		var col: Color = _ghost_color(gi, n)
		var em: Color = real_emission if _is_lit(gi) else Color.BLACK
		_mats.append(_make_material(col, em, col.a))
	# Under `pair` this is precisely the two lines that used to be here:
	#   _mat_a = _make_material(ghost_a_color, real_emission, ghost_a_color.a)
	#   _mat_b = _make_material(ghost_b_color, Color.BLACK,  ghost_b_color.a)
	_mat_a = _mats[0] if _mats.size() > 0 else null
	_mat_b = _mats[1] if _mats.size() > 1 else null


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.35
	col.shape = shape
	col.position.y = 0.4
	add_child(col)


func _build_mesh() -> void:
	var n: int = _mats.size()
	var start: Array[Vector3] = _ghost_offsets(n)
	_ghosts.clear()
	_offsets.clear()
	for i in range(n):
		var gi: int = int(i)
		var g := Node3D.new()
		g.name = "Ghost%s" % _ghost_letter(gi)
		_mesh_root.add_child(g)
		_build_humanoid(g, _mats[gi])
		g.position = start[gi]
		_ghosts.append(g)
		_offsets.append(start[gi])

	_ghost_a = _ghosts[0] if n > 0 else null
	_ghost_b = _ghosts[1] if n > 1 else null
	_ghost_a_offset = _offsets[0] if n > 0 else Vector3.ZERO
	_ghost_b_offset = _offsets[1] if n > 1 else Vector3.ZERO

	_build_claim_marks()


func _build_humanoid(parent: Node3D, mat: StandardMaterial3D) -> void:
	# Torso
	var torso := BoxMesh.new()
	torso.size = Vector3(0.15, 0.2, 0.08)
	var t := MeshInstance3D.new()
	t.mesh = torso
	t.set_surface_override_material(0, mat)
	t.position = Vector3(0.0, 0.45, 0.0)
	parent.add_child(t)

	# Head
	var head := SphereMesh.new()
	head.radius = 0.06
	head.height = 0.12
	var h := MeshInstance3D.new()
	h.mesh = head
	h.set_surface_override_material(0, mat)
	h.position = Vector3(0.0, 0.62, 0.0)
	parent.add_child(h)

	# Legs
	var leg := CylinderMesh.new()
	leg.top_radius = 0.02
	leg.bottom_radius = 0.025
	leg.height = 0.25
	for side in [-1.0, 1.0]:
		var l := MeshInstance3D.new()
		l.mesh = leg
		l.set_surface_override_material(0, mat)
		l.position = Vector3(side * 0.05, 0.2, 0.0)
		parent.add_child(l)

	# Arms
	var arm := CylinderMesh.new()
	arm.top_radius = 0.015
	arm.bottom_radius = 0.02
	arm.height = 0.2
	for side in [-1.0, 1.0]:
		var a := MeshInstance3D.new()
		a.mesh = arm
		a.set_surface_override_material(0, mat)
		a.position = Vector3(side * 0.12, 0.45, 0.0)
		a.rotation.z = side * 0.3
		parent.add_child(a)


# ── DNA implementation ───────────────────────────────────────────────────
# The census and the claim, and nothing else, live below here.


func _ghost_count() -> int:
	match census:
		"one":
			return 1
		"triad":
			return 3
		"chorus":
			return 5
		_:
			return 2  # "pair", and anything unrecognised: never silently unbody a creature


func _ghost_letter(index: int) -> String:
	return GHOST_LETTERS[index % GHOST_LETTERS.size()]


## Where the bodies stand at rest. `pair` returns the two literal vectors _build_mesh used
## to write inline, NOT the ring formula evaluated at n=2 — cos(PI) is exact but sin(PI) is
## 1.2e-16, and the shipped placement is entitled to a clean zero.
func _ghost_offsets(n: int) -> Array[Vector3]:
	var pts: Array[Vector3] = []
	var r: float = ghost_separation * 0.5
	if n <= 1:
		pts.append(Vector3.ZERO)
		return pts
	if n == 2:
		pts.append(Vector3(r, 0.0, 0.0))
		pts.append(Vector3(-r, 0.0, 0.0))
		return pts
	for i in range(n):
		var ang: float = (float(int(i)) / float(n)) * TAU
		pts.append(Vector3(cos(ang) * r, 0.0, sin(ang) * r))
	return pts


## Where body i wants to be while chasing. `pair` is the shipped behaviour exactly: the
## first body walks the player's direction, the second walks its negation.
func _chase_offset(index: int, n: int, dir: Vector3, r: float) -> Vector3:
	if n <= 1:
		return Vector3.ZERO
	if n == 2:
		if index == 0:
			return dir * r
		return -dir * r
	return dir.rotated(Vector3.UP, (float(index) / float(n)) * TAU) * r


## Under `none` every body is the same colour, because nothing may distinguish them.
## Otherwise body 0 is A's colour and body n-1 is B's, which for n == 2 is exactly the
## pair of colours the shipped creature had.
func _ghost_color(index: int, n: int) -> Color:
	if claim == "none":
		return ghost_a_color
	if n <= 1 or index == 0:
		return ghost_a_color
	if index == n - 1:
		return ghost_b_color
	return ghost_a_color.lerp(ghost_b_color, float(index) / float(n - 1))


## Is body `index` lit right now? `all` lights everyone, `none` lights no one, and the two
## ladders in between light whichever body currently holds the claim — which at build time
## is body 0, exactly as the shipped materials had it.
func _is_lit(index: int) -> bool:
	match claim:
		"all":
			return true
		"none":
			return false
		_:
			return index == _real_index


## The text over the bodies. `placard` builds the one billboard the shipped creature had,
## in the same place with the same font; `all` gives every body its own; `glow` and `none`
## build no text at all.
func _build_claim_marks() -> void:
	if claim == "placard":
		_label = Label3D.new()
		_label.text = "REAL: %s" % _ghost_letter(_real_index)
		_label.font_size = 22
		_label.pixel_size = 0.002
		_label.modulate = _ghost_color(_real_index, _mats.size())
		_label.position = Vector3(0.0, 1.0, 0.05)
		_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_mesh_root.add_child(_label)
		return
	if claim == "all":
		for i in range(_ghosts.size()):
			var gi: int = int(i)
			var lb := Label3D.new()
			lb.text = "REAL"
			lb.font_size = 22
			lb.pixel_size = 0.002
			lb.modulate = _ghost_color(gi, _ghosts.size())
			lb.position = Vector3(0.0, 0.85, 0.05)
			lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			_ghosts[gi].add_child(lb)
			_labels.append(lb)


## Re-mark the bodies after a swap. Under `none` this returns before touching anything —
## the whole point of that value is that a swap leaves no trace in the frame.
func _refresh_claim() -> void:
	if claim == "none":
		return
	var n: int = _mats.size()
	for i in range(n):
		var gi: int = int(i)
		var lit: bool = _is_lit(gi)
		_mats[gi].emission_enabled = lit
		_mats[gi].albedo_color.a = 0.7 if lit else 0.3
	if _label:
		_label.text = "REAL: %s" % _ghost_letter(_real_index)
		_label.modulate = _ghost_color(_real_index, n)


## Tear the bodies down and stand them back up on a new census or a new claim. Only the
## ghosts and their text are touched; the collision shape and the creature's state machine
## are the same objects throughout.
func _rebuild_ghosts() -> void:
	for g in _ghosts:
		if is_instance_valid(g):
			g.queue_free()   # per-body placards are children and go with them
	_ghosts.clear()
	_offsets.clear()
	_labels.clear()
	if is_instance_valid(_label):
		_label.queue_free()
	_label = null
	_ghost_a = null
	_ghost_b = null
	_real_index = 0
	_a_is_real = true
	_swap_timer = 0.0
	_create_materials()
	_build_mesh()


## Reachable configuration. The base forwards health / speed / damage and knew nothing
## about either axis, so a map token could not reach one. Both branches are CHANGE-GUARDED
## and BUILD-GUARDED: a word outside the allow-list, a word the creature already holds, or
## a call that arrives before _ready has built the bodies tears nothing down. Arriving
## early is fine on its own — the export is assigned and _ready then builds with it.
func apply_grid_config(config: Dictionary) -> void:
	super.apply_grid_config(config)
	var dirty: bool = false
	if config.has("census"):
		var c: String = str(config["census"]).strip_edges().to_lower()
		if CENSUSES.has(c) and c != census:
			census = c
			dirty = true
	if config.has("claim"):
		var k: String = str(config["claim"]).strip_edges().to_lower()
		if CLAIMS.has(k) and k != claim:
			claim = k
			dirty = true
	if dirty and _mesh_root != null:
		_rebuild_ghosts()


# ── Behaviour ────────────────────────────────────────────────────────────


func _process_visual(delta: float) -> void:
	_swap_timer += delta

	# Swap which body holds the claim
	if _swap_timer >= swap_interval:
		_swap_timer = 0.0
		_real_index = (_real_index + 1) % maxi(1, _mats.size())
		_a_is_real = _real_index == 0
		_refresh_claim()

		# Zeno chance
		if randf() < zeno_chance and is_instance_valid(_player_node):
			_zeno_halve()

	# Ghost movement: one approaches, the others take the rest of the ring
	if _state == BaseState.CHASE and is_instance_valid(_player_node):
		var dir: Vector3 = _get_player_direction()
		var n: int = _ghosts.size()
		var r: float = ghost_separation * 0.5
		for i in range(n):
			var gi: int = int(i)
			_offsets[gi] = _offsets[gi].lerp(_chase_offset(gi, n, dir, r), delta * 2.0)
		_ghost_a_offset = _offsets[0] if n > 0 else Vector3.ZERO
		_ghost_b_offset = _offsets[1] if n > 1 else Vector3.ZERO

	for i in range(_ghosts.size()):
		var gj: int = int(i)
		var g: Node3D = _ghosts[gj]
		if g:
			g.position = g.position.lerp(_offsets[gj], delta * 3.0)

	# Lunge handling
	if _is_lunging:
		_lunge_timer -= delta
		velocity = _lunge_dir * lunge_speed
		if _lunge_timer <= 0.0:
			_is_lunging = false
			velocity = Vector3.ZERO


func _process_attack(delta: float) -> void:
	if not _is_lunging and _state_time < 0.1:
		_is_lunging = true
		_lunge_timer = lunge_duration
		_lunge_dir = _get_player_direction()
	if _state_time >= lunge_duration + 0.5:
		_set_state(BaseState.CHASE)


func _process_chase(delta: float) -> void:
	super._process_chase(delta)
	# Periodically lunge
	if _state_time > 2.0 and fmod(_state_time, 3.5) < delta:
		_set_state(BaseState.ATTACK)


func _zeno_halve() -> void:
	# Halve the distance to the player (teleport closer)
	if is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - global_position
		global_position += to_player * 0.5


func _on_damaged(amount: float) -> void:
	# Only take damage if the hit matches the "real" body. There is no way to know which
	# side was struck, so the odds are one in however many bodies are standing there —
	# which for the shipped pair is `randf() > 0.5`, the literal line this replaces, and
	# for a lone body is a coin that never comes up wrong.
	if randf() > 1.0 / float(maxi(1, _mats.size())):
		# Missed the real one — restore health
		_health += amount
	_set_state(BaseState.STUNNED)
