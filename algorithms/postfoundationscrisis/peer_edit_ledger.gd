# Peer Edit Ledger — diffs accumulate, never reduce to a final form
#
# A tall ledger book pulses with stacked layers of edits. Each layer is a different color
# representing a different editor. The ledger is *deep*: scrolling back through its layers
# reveals the history, but the surface always shows the most recent state. Crucially,
# no edit overwrites the prior layer — they remain visible as glow within the stack.
#
# Models distributed knowledge with memory. The current state is the accumulation, never
# the replacement. Foreshadows graph theory's understanding of edges-as-history.
#
# @identity: First map where edits accumulate without overwriting.
# @qfep_term: Edge — peer process, not single author.

extends Node3D
class_name PeerEditLedger

@export var ledger_base_color: Color = Color(0.45, 0.3, 0.22, 1.0)
@export var layer_colors: Array = [
	Color(0.55, 0.85, 1.0, 1.0),
	Color(0.95, 0.55, 0.4, 1.0),
	Color(0.6, 0.9, 0.55, 1.0),
	Color(1.0, 0.85, 0.4, 1.0),
	Color(0.85, 0.55, 0.95, 1.0),
]
@export var layer_count: int = 24
@export var layer_height: float = 0.04

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA AXIS
# ═══════════════════════════════════════════════════════════════════

## How many hands are in the stack, and whether their layers survived.
##
## The stack IS the claim. Pinned at 24 evenly banded layers over a five-colour
## palette it made exactly one claim — many hands, all preserved, evenly — so every
## placement showed a commons that is always healthy and the failure modes were built
## nowhere. Each value here is a different fate for the same history:
##
##   many      the legacy look: 24 translucent layers cycling the palette, widths jittered
##   sole      one author — the stack has no seams at all: a single unbroken opaque column
##             of the same total height, striations gone, one solid object at room distance
##   squashed  history compaction — the ordinary thing that destroys the property this
##             artifact celebrates: two thirds of the object goes from banded to slab
##   fork      the split that never merged — the upper history runs twice, side by side,
##             and the silhouette becomes a Y
##
## None of them rely on a hue delta to survive a still: `sole` and `squashed` and `fork`
## all change silhouette or mass as well as the colour field. `fork` is spelled exactly as
## on merge_conflict_visualizer, same meaning.
@export_enum("many", "sole", "squashed", "fork") var authorship: String = "many"

const AUTHORSHIPS: PackedStringArray = ["many", "sole", "squashed", "fork"]

# Stack geometry, named so every branch works from the same numbers the legacy
# build used inline. Changing none of them keeps `many` byte-for-byte.
const STACK_BASE_Y: float = 0.65
const LAYER_GAP: float = 0.005
const LAYER_WIDTH: float = 0.58
const LAYER_JITTER: float = 0.04
const LAYER_DEPTH: float = 0.38

## squashed: the bottom 20 layers become one block. 0.80 m tall — the run it replaces
## is ~0.895 m of banding, so the compaction reads as a shortening as well as a
## smoothing. Only the last SQUASH_KEEP edits are still separable.
const SQUASH_KEEP: int = 4
const SQUASH_BLOCK_HEIGHT: float = 0.80

## fork: where the shared history ends, how far apart the two branches sit, and how far
## each leans outward. 0.35 m each way makes the object 1.28 m wide against a 0.58 m
## stack — a divergence you can read from across the room rather than a polite nudge.
const FORK_SPLIT_INDEX: int = 12
const FORK_OFFSET_X: float = 0.35
const FORK_LEAN_DEG: float = 6.0

## Fixed seed for the width jitter. Two builds of the same axis value have to be
## pixel-identical — a pixel critic diffs renders to decide whether an axis is real, and
## per-build jitter makes an inert axis look alive and a live one look noisy.
const JITTER_SEED: int = 20260728

var _layers: Array = []
var _t: float = 0.0
## Y of the highest built geometry, so the label clears whatever the axis built.
var _label_y: float = 0.0
## Every node THIS script parented to self. A rebuild frees these and only these —
## label plates, packaging and tags added by the grid system are not ours to destroy.
var _owned: Array[Node] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _built: bool = false


func _ready() -> void:
	_build_all()
	_built = true


func _build_all() -> void:
	_rng.seed = JITTER_SEED
	_build_base()
	_build_layers()
	_build_label()


func apply_grid_config(config_data: Dictionary) -> void:
	var before_authorship: String = authorship

	# Stage-2 DNA axis — #authorship:squashed
	if config_data.has("authorship"):
		authorship = _pick_axis(str(config_data["authorship"]), AUTHORSHIPS, authorship)

	if not _built:
		# _ready has not run yet; it will build with these values. Do NOT build here.
		return
	if authorship == before_authorship:
		# Nothing geometric changed. curation_station passes {"emissive": false} after it
		# has already framed our labels — rebuilding here would throw that framing away on
		# maps that shipped long before this axis existed. A config that changes nothing
		# says nothing.
		return

	_rebuild_now()
	print("[PeerEditLedger] Config applied — authorship=%s" % [authorship])


## Accept an axis value only if it names something we actually build. A typo in a map
## token has to land on the legacy look, never half-apply — a ledger with a split that
## only half happened would be a claim nobody authored.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Synchronous rebuild. remove_child() takes the old geometry out of the tree in this
## frame, so nothing double-renders and nothing lands after the grid's label framing or
## its deferred auto-grounding pass (which would measure a zero AABB and give up).
func _rebuild_now() -> void:
	# Drop the pulse targets first — _process must not touch nodes queued for free.
	_layers.clear()
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_label_y = 0.0
	_build_all()


func _process(delta: float) -> void:
	_t += delta * 0.8
	# Each layer pulses faintly, individually — many authors, each still present.
	for i in _layers.size():
		var layer: MeshInstance3D = _layers[i]
		if not is_instance_valid(layer):
			continue
		var mat := layer.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 0.8 + 0.5 * sin(_t + float(i) * 0.45)


func _build_base() -> void:
	var base := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.1, 0.4)
	base.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ledger_base_color
	mat.roughness = 0.6
	base.material_override = mat
	base.position.y = 0.55
	_own(base)
	# Stand.
	var stand := MeshInstance3D.new()
	var s_cyl := CylinderMesh.new()
	s_cyl.top_radius = 0.1
	s_cyl.bottom_radius = 0.2
	s_cyl.height = 0.5
	stand.mesh = s_cyl
	stand.material_override = mat
	stand.position.y = 0.25
	_own(stand)


## Parent a node we created to self and remember it, so a rebuild frees ours alone.
func _own(node: Node3D) -> void:
	add_child(node)
	_owned.append(node)


func _build_layers() -> void:
	match authorship:
		"sole":
			_build_sole_stack()
		"squashed":
			_build_squashed_stack()
		"fork":
			_build_forked_stack()
		_:
			_build_many_stack()


## many — the legacy build, untouched. Every layer its own author, every width its own
## jitter, the palette cycling all the way up.
func _build_many_stack() -> void:
	for i in layer_count:
		var w: float = LAYER_WIDTH + _rng.randf_range(-LAYER_JITTER, LAYER_JITTER)
		_add_layer(self, i, STACK_BASE_Y + float(i) * (layer_height + LAYER_GAP),
			w, _palette(i))
	_label_y = STACK_BASE_Y + float(layer_count) * layer_height + 0.2


## sole — one author, so the stack has no seams. Not 24 layers in one colour (that was a
## hue change plus a 4 cm jitter delta on a 0.58 m stack — nothing a still could read):
## a SINGLE continuous prism spanning the exact height `many` occupies, base of layer 0 to
## top of the last one, with the LAYER_GAP striations gone and the surface opaque. At room
## distance `many` reads as a stack of contributions and `sole` reads as one solid object.
## Distinct from `squashed`, which is a short compacted block with survivors banded above it.
func _build_sole_stack() -> void:
	var bottom: float = STACK_BASE_Y - layer_height * 0.5
	var span: float = _stack_span()
	# One slab, opaque — no internal edges to catch the light, so no seam anywhere.
	_add_slab(self, bottom + span * 0.5, LAYER_WIDTH, span, _palette(0), 1.0)
	_label_y = bottom + span + 0.2


## The full vertical extent `many` occupies: bottom face of layer 0 to top face of the
## last layer. `sole` matches it exactly so the difference is seams, not size.
func _stack_span() -> float:
	var n: int = maxi(layer_count, 1)
	return float(n - 1) * (layer_height + LAYER_GAP) + layer_height


## squashed — history compaction. The bottom layer_count - SQUASH_KEEP edits are gone
## into one opaque block in the ledger's own base colour: no banding, no glow, nothing
## to pulse. Only the last four edits are still separable above it.
func _build_squashed_stack() -> void:
	var keep: int = mini(SQUASH_KEEP, layer_count)
	var eaten: int = layer_count - keep
	var stack_bottom: float = STACK_BASE_Y - layer_height * 0.5
	var block_top: float = stack_bottom

	if eaten > 0:
		var block := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(LAYER_WIDTH, SQUASH_BLOCK_HEIGHT, LAYER_DEPTH)
		block.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = ledger_base_color
		mat.roughness = 0.6
		# Opaque, unlit-from-within: the compacted history is not readable any more.
		block.material_override = mat
		block.position.y = stack_bottom + SQUASH_BLOCK_HEIGHT * 0.5
		_own(block)
		block_top = stack_bottom + SQUASH_BLOCK_HEIGHT

	# The survivors keep their original palette indices, so they are recognisably the
	# TOP of the same stack rather than a fresh one.
	for j in keep:
		var i: int = eaten + j
		var y: float = block_top + layer_height * 0.5 + float(j) * (layer_height + LAYER_GAP)
		var w: float = LAYER_WIDTH + _rng.randf_range(-LAYER_JITTER, LAYER_JITTER)
		_add_layer(self, i, y, w, _palette(i))

	_label_y = block_top + float(keep) * (layer_height + LAYER_GAP) + 0.2


## fork — the split that never merged. The first FORK_SPLIT_INDEX layers are shared
## history on the centre line; above them the upper half runs TWICE, as two parallel
## stacks offset to x -0.35 and x +0.35 and each leaning FORK_LEAN_DEG outward. The
## silhouette is a Y.
func _build_forked_stack() -> void:
	var split: int = clampi(FORK_SPLIT_INDEX, 1, layer_count)
	var branch_len: int = layer_count - split
	if branch_len <= 0:
		branch_len = split

	for i in split:
		var w: float = LAYER_WIDTH + _rng.randf_range(-LAYER_JITTER, LAYER_JITTER)
		_add_layer(self, i, STACK_BASE_Y + float(i) * (layer_height + LAYER_GAP),
			w, _palette(i))

	var split_y: float = STACK_BASE_Y + float(split) * (layer_height + LAYER_GAP)
	var lean: float = deg_to_rad(FORK_LEAN_DEG)

	for side in 2:
		var dir: float = -1.0 if side == 0 else 1.0
		var branch := Node3D.new()
		branch.name = "ForkLeft" if side == 0 else "ForkRight"
		branch.position = Vector3(dir * FORK_OFFSET_X, split_y, 0.0)
		# Rotating about Z tips the branch away from the centre line, so the two
		# stacks open outward rather than standing as two towers.
		branch.rotation.z = -dir * lean
		_own(branch)
		for j in branch_len:
			var i: int = split + j
			var w: float = LAYER_WIDTH + _rng.randf_range(-LAYER_JITTER, LAYER_JITTER)
			_add_layer(branch, i, float(j) * (layer_height + LAYER_GAP), w, _palette(i))

	# Branch tops tilt slightly inward of vertical; cos() keeps the label clear of them.
	_label_y = split_y + float(branch_len) * (layer_height + LAYER_GAP) * cos(lean) + 0.2


func _palette(i: int) -> Color:
	# Typed local first — a bare `return layer_colors[...]` is an unsafe Variant return.
	var c: Color = layer_colors[i % layer_colors.size()]
	return c


func _add_layer(parent: Node3D, index: int, local_y: float, width: float, color: Color) -> void:
	# index is kept in the signature for call-site readability; the palette is resolved
	# by the caller so branches can reuse the shared history's indices.
	_add_slab(parent, local_y, width, layer_height, color, 0.7)


## One box in the stack. `height` and `alpha` are parameters so `sole` can raise a single
## opaque slab through the same path the banded layers use — same material, same pulse.
func _add_slab(parent: Node3D, local_y: float, width: float, height: float, color: Color, alpha: float) -> void:
	var layer := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, height, LAYER_DEPTH)
	layer.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if alpha < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = alpha
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.0
	layer.material_override = mat
	layer.position.y = local_y
	if parent == self:
		_own(layer)
	else:
		parent.add_child(layer)
	_layers.append(layer)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "edits accumulate"
	label.font_size = 24
	label.outline_size = 5
	label.modulate = Color(0.95, 0.85, 0.55, 1.0)
	label.position = Vector3(0, _label_y, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_own(label)
