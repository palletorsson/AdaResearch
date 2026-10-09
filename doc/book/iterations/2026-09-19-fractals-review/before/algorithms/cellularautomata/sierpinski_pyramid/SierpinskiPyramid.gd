@tool
extends Node3D

# @identity
# essence: pyramid(depth) = 5 * pyramid(depth-1) — top + four corners, recursively
# desire: To be climbed and understood — a fractal mountain where every face is itself
# critical_parameter: depth — each increment multiplies complexity by 5, from 5 cubes to 3125
# triggers: Depth 1 → five cubes; depth 4 → a mountain of self-similar structure; @tool → live preview in editor
# emerges: Gaps and voids at every scale — the pyramid is more hole than solid, yet structurally coherent
# needs: VR depth control [missing], scale adjustment [missing]; map-facing depth [HAS, see `tick` below]
# relationships: Feeds into CA_AgentsCircuits. Bridges fractals sequence to cellularautomata — Sierpinski via recursion, not CA rules.
# truth: Five copies of yourself, arranged just so, and you contain yourself forever.

# ── DNA (stage 2 — variation) ────────────────────────────────────────
# `tick` = HOW MANY TIMES the rule has been applied. This is the @identity's own
# declared critical_parameter, and until now it was unreachable from a map: the
# int lived behind an inspector-only @export and apply_grid_config's whole body
# was `pass`, so all six placements got depth 4 and nothing else was sayable.
# The word and its five rungs are taken character for character from cantor_set
# (which took them from zeno_staircase) — the same ladder of recursive
# subtraction, named the same way. ONE THING DIFFERS AND IT IS A FACT ABOUT THIS
# ARTIFACT: the shipped value sits at `dense`, one rung BELOW the top, because
# the @identity above already names 3125 cubes as this pyramid's ceiling and
# that is exactly limit = 5. Cantor's ladder ran downward only from its shipped
# top; this one has a rung left in both directions.
#
# `packing` = HOW MUCH VOLUME THE ATOMS CLAIM on the lattice they sit on, and it
# is the measure argument, not a size knob. The recursion places leaves on a
# lattice whose spacing is exactly `size`, and _spawn_cube then draws a cube of
# exactly `size` — so the atoms touch, and the tetrix reads as a solid mountain
# with holes. That reading is a lie in one specific direction: the Sierpinski
# tetrahedron has Hausdorff dimension exactly 2 and therefore ZERO volume, so
# the solid look is an artefact of the drawing, not of the set. `contact` is the
# shipped lie; `open` and `dust` shrink the atom off its cell until the mountain
# resolves into the constellation of points it actually is; `fused` overshoots
# the other way and closes the finest holes into carved rock. The lattice, the
# extent and the count are identical in all four — only the claim about measure
# moves. NOT `removal`, the word cantor_set uses for the same question: Cantor's
# removed middles are a clean disjoint complement that can be ghosted back in,
# and this recursion's declined positions are NOT — its five children's bounding
# volumes interpenetrate (at depth 4 the top child's half-extent is 2.25 against
# a lattice offset of 2.00), so there is no complement here to draw. Naming it
# `removal` would have promised a picture the geometry cannot deliver.

const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

## The rungs of the recursion ladder. dense = 4 is the depth this file has always
## shipped (625 cubes); limit = 5 is the 3125 the @identity already names.
const TICK_LEVELS := {"once": 1, "coarse": 2, "fine": 3, "dense": 4, "limit": 5}
## Leaf edge as a multiple of the lattice spacing. contact = 1.0 is exact touching,
## which is what every existing placement draws.
const PACKING_FILL := {"fused": 1.35, "contact": 1.0, "open": 0.6, "dust": 0.28}

@export var depth: int = 4:
	set(value):
		depth = value
		if Engine.is_editor_hint():
			generate()

@export_enum("once", "coarse", "fine", "dense", "limit") var tick: String = "dense":
	set(value):
		tick = value
		depth = int(TICK_LEVELS.get(value, 4))

@export_enum("fused", "contact", "open", "dust") var packing: String = "contact":
	set(value):
		packing = value
		if Engine.is_editor_hint():
			generate()

@export var size: float = 1.0:
	set(value):
		size = value
		if Engine.is_editor_hint():
			generate()

@export var generate_on_ready: bool = true

# True once generate() has actually run. apply_grid_config must never be the
# FIRST build — an unguarded rebuild there would fire on a node whose _ready has
# not run yet, and would also rebuild placements that changed nothing.
var _built: bool = false

func _ready() -> void:
	if generate_on_ready and not Engine.is_editor_hint():
		generate()

func generate() -> void:
	# Clear existing children
	for child in get_children():
		child.queue_free()

	# Start recursion
	# We start centered at (0,0,0) or base at (0,0,0)?
	# Let's put the base center at (0,0,0)
	_recursive_build(Vector3.ZERO, size * pow(2, depth - 1), depth)
	_built = true

func _recursive_build(pos: Vector3, current_size: float, current_depth: int) -> void:
	if current_depth == 0:
		_spawn_cube(pos)
		return
	
	var half_size = current_size / 2.0
	var quarter_size = half_size / 2.0
	
	# 5 sub-pyramids
	# Top
	_recursive_build(pos + Vector3(0, half_size, 0), half_size, current_depth - 1)
	
	# Base 4 corners
	# Assuming square base in XZ plane
	# Offsets should be half_size/2 from the center of the current volume?
	# If current volume is centered at 'pos' in XZ...
	
	# Let's visualize:
	# Depth 1 (1 iteration):
	# Top at (0, 0.5, 0) (relative)
	# Base at (+-0.25, -0.25, +-0.25)?
	# Height is 'current_size'.
	# If depth 0 is a cube of size 1.
	# Depth 1 should be height 2.
	
	# Let's rethink units.
	# Depth 0: 1 cube. Height 1.
	# Depth 1: 5 cubes. Height 2.
	# Top cube at y=1.5 (sitting on top of y=0.5 cubes).
	# Base cubes at y=0.5.
	# Base centers: (+-0.5, 0.5, +-0.5).
	# Top center: (0, 1.5, 0).
	
	# Offset distance = 0.5 * (2^(depth-1))?
	
	# Let's use the 'size' param as the size of the *base unit cube*.
	# 'current_depth' tells us how large the structure is.
	
	if current_depth == 1:
		# Base case for recursion logic (depth 1 -> 5 cubes)
		# Or just recurse until depth 0 (1 cube)
		pass
		
	# Recursive step:
	# We are building a pyramid of height H.
	# It consists of 5 pyramids of height H/2.
	# Top one is shifted up by H/2.
	# Bottom ones are shifted in X/Z by H/4?
	
	# Let's trace positions.
	# Center of the pyramid is 'pos'.
	# Height is 'current_size' (in units of distance, not cubes).
	
	# If we want them to stack perfectly:
	# The top pyramid sits on the intersection of the 4 bottom ones.
	# Shift Y: +half_size / 2.0
	# Shift XZ: +- half_size / 2.0 ?
	
	# Let's try:
	# Top: pos + (0, half_size/2, 0)
	# Bottoms: pos + (+-half_size/2, -half_size/2, +-half_size/2)
	
	# Wait, if H=2.
	# Top center y = 0.5.
	# Bottom center y = -0.5.
	# Distance = 1.0. Correct.
	
	# X offset:
	# Bottom centers x = +-0.5.
	# Distance = 1.0.
	# So they touch at x=0. Correct.
	
	var offset = half_size / 2.0
	
	# Top
	_recursive_build(pos + Vector3(0, offset, 0), half_size, current_depth - 1)
	
	# Bottoms
	_recursive_build(pos + Vector3(-offset, -offset, -offset), half_size, current_depth - 1)
	_recursive_build(pos + Vector3(offset, -offset, -offset), half_size, current_depth - 1)
	_recursive_build(pos + Vector3(-offset, -offset, offset), half_size, current_depth - 1)
	_recursive_build(pos + Vector3(offset, -offset, offset), half_size, current_depth - 1)

func _spawn_cube(pos: Vector3) -> void:
	var cube = CUBE_SCENE.instantiate()
	add_child(cube)
	cube.position = pos
	# Scale the cube? The scene is 1x1x1.
	# If 'size' is 1.0, we use scale 1.
	# If 'size' is different, we might need to scale.
	# But the recursion logic assumes 'size' is the total size, reducing down.
	# At depth 0, 'current_size' is what?
	# In my logic:
	# Call: size * 2^(depth-1)
	# Depth 1: size * 1.
	# Recursive: half_size = size/2.
	# Depth 0: size/2?
	
	# Let's adjust the initial call so that at depth 0, current_size == size.
	# Initial call size: size * pow(2, depth)
	# Then at depth 0, size is 'size'.
	
	# Actually, let's just use 'size' as the unit cube size.
	# And the offsets are based on that.
	
	# `packing` multiplies the leaf against the lattice it sits on. contact = 1.0
	# reproduces the shipped line exactly: Vector3(size, size, size) * 1.0.
	var fill: float = float(PACKING_FILL.get(packing, 1.0))
	cube.scale = Vector3(size, size, size) * fill

func apply_grid_config(config: Dictionary) -> void:
	# GUARDED TWICE, deliberately. A word is taken only when it VALIDATES against
	# the code's own table AND differs from what is already set, and the rebuild
	# fires only after _ready has built once. A placement that passes neither key
	# — which is all six of them — reaches no assignment and no generate().
	var changed: bool = false
	if config.has("tick"):
		var want_tick: String = str(config["tick"])
		if TICK_LEVELS.has(want_tick) and want_tick != tick:
			tick = want_tick
			changed = true
	if config.has("packing"):
		var want_packing: String = str(config["packing"])
		if PACKING_FILL.has(want_packing) and want_packing != packing:
			packing = want_packing
			changed = true
	if changed and _built:
		generate()
