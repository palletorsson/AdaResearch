extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name EntropyFan

## @identity
## name: Entropy Fan
## truth: more ways to be is more entropy — possibility itself is what S measures.
##
## E as POSSIBILITY SPACE (QFE = F − λE(S) + φΔE(S,t)). From a single root state, a
## branching fan of futures multiplies outward: 1 → few → many. An ordered, low-entropy
## state is one thin path; a disordered, high-entropy state is a wide fan. Entropy is
## shown as log(number of futures), climbing as the fan opens. The tree is rebuilt as the
## branching factor breathes, so you watch possibility itself grow and contract — the fan
## is the size of the future, and that size is exactly S.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var levels: int = 4
@export var max_branch: int = 3        # branches per node when fully open
@export var fan_period: float = 9.0    # seconds for a full narrow→wide→narrow cycle
@export var span_height: float = 0.95  # vertical reach of the fan (root→leaves)
@export var fan_spread: float = 0.34   # lateral half-spread at the widest level
@export var path_color: Color = Color(0.5, 0.65, 1.0)    # cool blue branches
@export var leaf_color: Color = Color(0.6, 0.95, 1.0)    # bright cyan futures
@export var root_color: Color = Color(0.7, 0.6, 1.0)     # purple root state

# ══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA AXIS — #prospect:fan
# ══════════════════════════════════════════════════════════════════════════

## prospect — how many futures are actually built from the single root, and
## whether any of them were closed off rather than never opened.
##
##   breath  the shipped look, untouched: the branching factor keeps cycling
##           1 → 3 → 1 on the 9 s cosine, the tree rebuilding over the 0.95 m
##           rise whenever it changes, the whole fan turning slowly on its
##           0.4 m base. The count of futures is whatever the timer says.
##   thread  pinned at branch 1: a single 0.95 m stem of four nodes rising from
##           the 0.045 m purple root sphere to one 0.03 m cyan leaf. Silhouette
##           0.06 m wide. FUTURES = 1, S = 0.00.
##   fan     pinned at branch 3: the whole tree at once — 81 leaf spheres in the
##           crown at the top of the 0.95 m rise, 120 branch tubes tapering
##           0.018 → 0.008 m. FUTURES = 81, S = 4.39.
##   pruned  built at branch 3, but two of every three subtrees at the third row
##           are terminated there with a flat 0.03 m amber cap instead of growing
##           on: 27 leaves survive under 18 visible stumps, in the same crown.
##           The futures that were CLOSED, left standing as evidence.
##           FUTURES = 27 of 81.
##
## The three pinned values also latch the branch factor — see _process. Without
## the latch the cosine would overwrite them inside 0.25 s and all four values
## would render the same breathing tree.
@export_enum("breath", "thread", "fan", "pruned") var prospect: String = "breath"

## Accepted spellings. A typo has to fall back to the shipped look rather than
## strand a placement with no tree at all.
const PROSPECTS: PackedStringArray = ["breath", "thread", "fan", "pruned"]

## `pruned`: the _grow_branch level whose children are capped instead of grown.
## Level 2 is the call that creates the 27 penultimate nodes, so keeping one child
## in three leaves 9 subtrees × 3 = 27 leaves under 18 stumps.
const PRUNE_ROW: int = 2
const CAP_COLOR: Color = Color(1.0, 0.68, 0.22)   # amber — a cut, not a future
const CAP_RADIUS: float = 0.03
const CAP_THICKNESS: float = 0.006

## No randf/randi is read during the build; the seed is fixed anyway so that any
## later use cannot make two placements of the same map differ.
const FAN_SEED: int = 20260729

var _fan_root: Node3D
var _title: Label3D
var _readout: Label3D
## Where the readout board stands, measured rather than eyeballed.
##
## The widest thing the canopy swings is a level-2 node: orbit radius 0.352 m plus a
## 0.022 m sphere = 0.374 m of reach. The board is 0.556 m wide with its bezel, so its
## inner edge sits at BOARD_X - 0.278. At the old 0.62 that edge was 0.342 — inside the
## sweep — and the nodes ploughed through the panel on every rotation. 0.70 puts the
## edge at 0.422, clear by 0.048 m.
const BOARD_X: float = 0.70
const BOARD_HALF_W: float = 0.278
const NODE_REACH: float = 0.374

var _screen: Node3D               # TextScreen carrying the readout on a real board
var _t: float = 0.0
var _rebuild_at: float = 0.0
var _branch_now: int = 1          # current branching factor (1..max_branch)
var _leaf_count: int = 1          # number of leaf futures currently drawn
var _max_futures: int = 1         # branch^levels — what an unpruned tree would hold
var _stump_count: int = 0         # futures closed off (pruned only)

var _built: bool = false
var _pinned: bool = false         # branch factor latched — _process must not recompute it
var _prune: bool = false
var _prune_parent: int = 0        # deterministic which-child-survives rotation
var _owned: Array[Node] = []      # ONLY the nodes this script created


func _ready() -> void:
	_rng.seed = FAN_SEED
	prospect = _pick_axis(prospect, PROSPECTS, "breath")
	_build_all()
	_built = true
	set_process(not Engine.is_editor_hint())


# ------------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------------

func apply_grid_config(config_data: Dictionary) -> void:
	var before_prospect: String = prospect
	if config_data.has("prospect"):
		prospect = _pick_axis(str(config_data["prospect"]), PROSPECTS, prospect)

	# `emissive` is applied IN PLACE, before every early return. curation_station
	# calls apply_grid_config({"emissive": false}) with no axis key, one line after
	# framing the labels — an unconditional rebuild there would free the framing.
	if config_data.has("emissive"):
		var want: bool = bool(config_data["emissive"])
		if want != emissive:
			emissive = want
			_apply_emissive_in_place()

	if not _built:
		return
	if prospect == before_prospect:
		return
	_rebuild_now()
	print("[EntropyFan] Config applied — prospect=%s" % [prospect])


## Accept an axis value only if it names something we actually build.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _own(n: Node) -> Node:
	_owned.append(n)
	add_child(n)
	return n


func _rebuild_now() -> void:
	# Free ONLY what this script made — grid-added plates and framing live here too.
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_fan_root = null
	_title = null
	_readout = null
	_screen = null
	_branch_now = 1
	_leaf_count = 1
	_stump_count = 0
	_build_all()          # SYNCHRONOUS — a deferred rebuild would hand auto-grounding a zero AABB


func _build_all() -> void:
	_pinned = prospect != "breath"
	_prune = prospect == "pruned"

	# --- floor base (y ~ 0) ---
	_own(_cylinder(Vector3(0.0, 0.04, 0.0), 0.4, 0.08, _steel_mat(Color(0.16, 0.18, 0.28))))
	_own(_cylinder(Vector3(0.0, 0.1, 0.0), 0.32, 0.05, _matte_mat(Color(0.2, 0.24, 0.36), 0.6, 0.3)))

	# --- the fan container (rebuilt as branching factor changes) ---
	_fan_root = Node3D.new()
	_fan_root.name = "Fan"
	_fan_root.position = Vector3(0.0, 0.16, 0.0)
	_own(_fan_root)
	_rebuild_fan(_start_branch())

	# --- title (hangs above the crown; the framer's plate lands at y 1.395–1.605) ---
	_title = _billboard_label("ENTROPY FAN", Vector3(0.0, 1.5, 0.0), 28, leaf_color)
	_own(_title)

	# --- readout on a real board, beside the tree ---
	_build_readout_screen()
	_update_readout()

	_tag_emission_bases()


func _start_branch() -> int:
	match prospect:
		"thread":
			return 1
		"fan", "pruned":
			return maxi(max_branch, 1)
	return 1     # breath — the shipped build starts thin and opens on the cosine


# ------------------------------------------------------------------
# Readout — a board, not a hanging slab
# ------------------------------------------------------------------
#
# The readout used to be a _billboard_label at (0, 1.28, 0), font 19, three lines.
# Framed, that is a ~1.50 x 0.36 m opaque plate spanning y 1.10–1.46 — hanging
# directly across the leaf plane (y 1.11) of a crown that is well under a metre
# wide, hiding the exact thing it is counting, and clipping the title plate.
# It moves onto a TextScreen standing BESIDE the tree, at the height where the
# branching happens, so the crown is visible for the first time.

func _build_readout_screen() -> void:
	# Configure BEFORE add_child — TextScreen's setters rebuild only when already
	# in-tree, so driving them after the add costs one rebuild each.
	var ts := TextScreenScript.new()
	ts.name = "ProspectReadout"
	ts.mode = 0                       # Mode.SCREEN — a framed panel, no post
	ts.width_m = 0.52                 # board 0.556 x 0.358 m with its bezel
	ts.title_color = leaf_color
	# Stood clear of the canopy's sweep, not merely beside it. At x 0.62 the board's
	# inner edge fell at 0.342 while the level-2 nodes orbit to radius 0.352 with a
	# 0.022 m sphere — reaching 0.374 — so under `breath` (the DEFAULT, where
	# _fan_root spins) the nodes passed THROUGH the readout on every turn. Two solid
	# things cannot occupy one place, and a still catches it at an arbitrary phase, so
	# it read as a glitch rather than as an instrument beside a tree.
	ts.position = Vector3(BOARD_X, 0.86, 0.02)
	_screen = ts
	_own(ts)

	# The Label3D survives as the text source, so anything that live-updates
	# `.text` keeps working. Billboard DISABLED so LabelFramer skips it (it only
	# frames hanging labels), glyphs scaled to nothing and alpha zero so it adds
	# no silhouette of its own — the board above carries the text.
	_readout = _billboard_label("", Vector3.ZERO, 19, leaf_color)
	_readout.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_readout.outline_size = 0
	_readout.modulate = Color(leaf_color.r, leaf_color.g, leaf_color.b, 0.0)
	_readout.scale = Vector3.ONE * 0.001
	_screen.add_child(_readout)


func _update_readout() -> void:
	# S = log(number of futures). Show the count and its log; name the regime.
	var futures: int = maxi(_leaf_count, 1)
	var s_val: float = log(float(futures))
	var regime: String = "ONE THIN PATH — low entropy (ordered)"
	if _prune:
		regime = "%d FUTURES CLOSED — the fan was cut back" % [_stump_count]
	elif _branch_now >= max_branch and max_branch > 1:
		regime = "WIDE FAN — high entropy (many futures)"
	elif _branch_now > 1:
		regime = "FAN OPENING — possibility multiplying"

	var head: String = "FUTURES = %d   (branch %d)" % [futures, _branch_now]
	if _prune:
		head = "FUTURES = %d of %d   (branch %d)" % [futures, _max_futures, _branch_now]
	var body: String = "S = log(futures) = %.2f\n%s" % [s_val, regime]

	if _readout != null:
		_readout.text = "%s\n%s" % [head, body]
	if _screen != null and _screen.has_method("set_text"):
		_screen.call("set_text", head, body)


# ------------------------------------------------------------------
# Animation
# ------------------------------------------------------------------

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# branching factor breathes 1 → max_branch → 1 (a thin path widening to a fan)
	var phase: float = 0.5 - 0.5 * cos(_t * TAU / maxf(fan_period, 0.5))

	# THE LATCH. thread / fan / pruned assert a number of futures; recomputing the
	# target here would overwrite that within 0.25 s and every value would converge
	# on the same breathing tree.
	if not _pinned:
		var target_branch: int = 1 + int(round(phase * float(max_branch - 1)))
		target_branch = clampi(target_branch, 1, max_branch)

		# rebuild the fan only when the branching factor actually changes (on a small cadence)
		_rebuild_at -= delta
		if target_branch != _branch_now and _rebuild_at <= 0.0:
			_rebuild_at = 0.25
			_rebuild_fan(target_branch)
			_update_readout()

	if _fan_root != null:
		# slow ceremonial rotation so the fan's breadth is legible from all sides.
		# Frozen when pinned, so a still of an asserted tree is the same still twice.
		if not _pinned:
			_fan_root.rotation.y = _t * 0.35
		# leaves shimmer with possibility
		var pulse: float = 0.5 + 0.5 * sin(_t * 2.4)
		for child in _fan_root.get_children():
			if child is MeshInstance3D and child.has_meta("is_leaf"):
				var mi: MeshInstance3D = child as MeshInstance3D
				var m: StandardMaterial3D = mi.material_override as StandardMaterial3D
				if m != null:
					m.emission_energy_multiplier = (2.0 + 1.4 * pulse) if emissive else 0.6

	if _title != null and not _pinned:
		_title.modulate = leaf_color.lerp(Color(1.0, 1.0, 1.0), 0.2 * phase)


# ------------------------------------------------------------------
# Fan construction — branching tubes + nodes from a single root
# ------------------------------------------------------------------

func _rebuild_fan(branch: int) -> void:
	_branch_now = branch
	if _fan_root == null:
		return
	for c in _fan_root.get_children():
		_fan_root.remove_child(c)
		c.queue_free()

	# root state node at the bottom (the single present)
	var root_pos: Vector3 = Vector3.ZERO
	_fan_root.add_child(_sphere(root_pos, 0.045, _glow_mat(root_color, 2.2)))

	_leaf_count = 0
	_stump_count = 0
	_prune_parent = 0
	# grow recursively; each level spreads laterally as it climbs.
	# Leaves are COUNTED as they are built, so a pruned tree reports what it has.
	_grow_branch(root_pos, 0, branch, 0.0, fan_spread)
	_leaf_count = maxi(_leaf_count, 1)

	# what an unpruned tree of this branch factor would have held: branch^levels
	var n: int = 1
	var lv: int = 0
	while lv < levels:
		n *= maxi(branch, 1)
		lv += 1
	_max_futures = maxi(n, 1)

	# tag the freshly-made materials so a later emissive:false can dim them in place
	_tag_emission_bases()


func _grow_branch(from_pos: Vector3, level: int, branch: int, center_x: float, spread: float) -> void:
	if level >= levels:
		return
	var y_next: float = span_height * (float(level + 1) / float(levels))
	var is_leaf_level: bool = (level + 1 >= levels)
	var n: int = 1 if branch <= 1 else branch

	# pruned: at PRUNE_ROW exactly one child of this parent grows on; the other two
	# are cut. Which one survives rotates per parent, so the survivors stay spread
	# across the full crown instead of all leaning the same way.
	var keep_i: int = -1
	var cutting: bool = _prune and level == PRUNE_ROW and n > 1 and not is_leaf_level
	if cutting:
		keep_i = _prune_parent % n
		_prune_parent += 1

	var i: int = 0
	while i < n:
		# spread children symmetrically around the parent's center_x
		var frac: float = 0.0
		if n > 1:
			frac = (float(i) / float(n - 1)) - 0.5  # -0.5..0.5
		var child_x: float = center_x + frac * spread
		var child_z: float = frac * spread * 0.5  # slight depth so it reads as 3D
		var to_pos: Vector3 = Vector3(child_x, y_next, child_z)

		# branch tube
		var tube_mat: StandardMaterial3D = _glow_mat(path_color, 1.6)
		var radius: float = lerpf(0.018, 0.008, float(level) / float(maxf(levels - 1, 1)))
		_fan_root.add_child(_cylinder_between(from_pos, to_pos, radius, tube_mat))

		if cutting and i != keep_i:
			# A CLOSED FUTURE. The branch arrives and stops: a flat amber cap where
			# the node sphere would be, and no recursion beyond it. The stump stays
			# standing so the subtree that did not happen is still counted for.
			_fan_root.add_child(_cylinder(to_pos, CAP_RADIUS, CAP_THICKNESS, _glow_mat(CAP_COLOR, 1.5)))
			_stump_count += 1
			i += 1
			continue

		# node sphere at the branch point / future
		var node_col: Color = leaf_color if is_leaf_level else path_color
		var node_r: float = 0.03 if is_leaf_level else 0.022
		var node_mat: StandardMaterial3D = _glow_mat(node_col, 2.0)
		var node: MeshInstance3D = _sphere(to_pos, node_r, node_mat)
		if is_leaf_level:
			node.set_meta("is_leaf", true)
			_leaf_count += 1
		_fan_root.add_child(node)

		# recurse — children spread tighter the deeper we go
		_grow_branch(to_pos, level + 1, branch, child_x, spread * 0.55)
		i += 1


# ------------------------------------------------------------------
# emissive, applied in place (no rebuild — the framing must survive)
# ------------------------------------------------------------------

## Record each emissive material's full-brightness energy at build time, so a later
## `emissive:false` can dim it and a later `emissive:true` can restore it without
## rebuilding the tree.
func _tag_emission_bases() -> void:
	for n in _owned:
		_walk_emission(n, true)


func _apply_emissive_in_place() -> void:
	for n in _owned:
		_walk_emission(n, false)


func _walk_emission(n: Node, tag_only: bool) -> void:
	if n is MeshInstance3D:
		var mi: MeshInstance3D = n as MeshInstance3D
		var m: StandardMaterial3D = mi.material_override as StandardMaterial3D
		if m != null and m.emission_enabled:
			var e: float = m.emission_energy_multiplier
			if tag_only:
				# the helpers bake the current `emissive` in; recover the full value.
				# Tag once only — _process re-drives the leaf energies every frame.
				if not m.has_meta("base_energy"):
					m.set_meta("base_energy", e if emissive else e / 0.3)
			else:
				# `emissive` has just flipped, so anything untagged (a material the
				# TextScreen made on its last text update) was built at the old value.
				var base: float = e if not emissive else e / 0.3
				if m.has_meta("base_energy"):
					base = float(m.get_meta("base_energy"))
				else:
					m.set_meta("base_energy", base)
				m.emission_energy_multiplier = base if emissive else base * 0.3
	for c in n.get_children():
		_walk_emission(c, tag_only)
