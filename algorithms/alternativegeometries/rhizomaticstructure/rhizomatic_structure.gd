extends Node3D

# @identity
# essence: recursive branching with lateral reconnection — each new node grows from a random parent with direction = lerp(random, away_from_center, 1 - growth_direction_randomness), then probabilistically connects to nearby existing nodes
# desire: to grow a structure that has no center and no hierarchy — a rhizome where any point can connect to any other point, undermining tree-shaped thinking
# critical_parameter: connection_probability — at 0 the structure is a tree (hierarchical), at 1.0 every nearby node reconnects (rhizomatic), the transition is where Deleuze meets graph theory
# triggers: generate_structure builds the node/connection arrays; draw_structure renders CylinderMesh branches between connected nodes; regenerate() clears and regrows
# emerges: lateral connections create cycles in an otherwise tree-shaped growth, producing a network topology that resists reduction to any single root or trunk
# needs: slider_horizontal [missing]; push_button [missing]
# relationships: appears in GT_Network_Analysis as a Deleuze-Guattari-inspired contrast to hierarchical graph algorithms; challenges the tree assumption in tarjan and kosaraju
# truth: a rhizome has no beginning and no end — only middles, and every connection is as legitimate as every other

class_name RhizomaticStructure

# ═══════════════════════════════════════════════════════════════════
# CAPTIONS — the deliberate absence of one
# ═══════════════════════════════════════════════════════════════════
#
# There are no Label3D nodes here and none are being added. plates = 0 and
# crossing = 0 at every value of `mutuality`, by construction rather than by
# careful placement.
#
# That is an argument, not an oversight. This structure exists to say that no
# point in it is privileged — a nameplate hung over it would immediately BE the
# privileged point, and LabelFramer would turn it into an opaque anthracite
# panel floating in front of a 19 m tangle whose whole claim is that it has no
# front. A per-node caption would be worse still: 51 opaque plates would bury
# the graph they name.
#
# If a placement needs this thing named, that belongs to the map's own label
# utility, standing off to one side in the room, not to the artifact.
#
# The `# needs:` line above used to list a missing Label3D. It has been removed:
# the census kept counting a nameplate this artifact does not want.

# Parameters for the rhizomatic structure
@export var num_branches: int = 50
@export var min_branch_length: float = 1.0
@export var max_branch_length: float = 5.0
@export var min_branch_thickness: float = 0.1
@export var max_branch_thickness: float = 0.3
@export var growth_direction_randomness: float = 0.7
@export var connection_probability: float = 0.2
@export var min_distance_for_connection: float = 1.0
@export var max_distance_for_connection: float = 3.0
@export var material: Material = null

## How much the structure folds back on itself.
##
## The header above has always named `connection_probability` the critical
## parameter — "the transition is where Deleuze meets graph theory" — and for
## its whole life apply_grid_config was an empty `pass`, so that transition was
## reachable only by editing this script. Every placement grew the same 0.2
## tangle. This axis makes the header's own claim addressable from a map.
##
## The same word, and the same four rungs, are carried by `tarjan` and
## `kosaraju`. That is the point of a shared axis: one question — does this
## structure fold back on itself — asked once by a Deleuzian growth model and
## twice by an SCC algorithm, so a sweep row reading `mutuality: none` shows a
## tree, a topological order and a hierarchy standing side by side.
##
##   pockets  the shipped look. connection_probability 0.2 — 51 nodes, 62
##            branches, of which 12 are lateral chords closing cycles 3 to 7
##            branches long. A ~19.4 x 17.2 x 15.7 m tangle with rhizomatic
##            pockets in an otherwise tree-shaped growth.
##   none     connection_probability 0.0 — exactly 50 branches on the SAME 51
##            nodes. Removing an edge cannot move a node, so this is literally
##            the default's own tree with the 12 chords taken out: every branch
##            now traces back to the single root at the origin and nothing
##            returns. The hierarchy the artifact was built to refuse.
##   split    two roots 8 m apart, 25 branches each, reconnection permitted
##            inside a cluster and forbidden across. Growth is confined to its
##            own side of a 4 m corridor, so no branch crosses: two tangles
##            (14.8 x 11.6 x 8.8 m and 7.5 x 16.2 x 11.9 m) with 6.2 m of empty
##            air measured between them and zero cross-cluster edges. This is
##            the value that costs the argument something honest — a rhizome
##            that has come apart into two rhizomes is a real limit on the
##            anti-hierarchy claim, and reachability, not hierarchy, is what
##            broke.
##   total    connection_probability 1.0 — every pair within 1-3 m reconnects,
##            150 branches on the same 51 nodes. The interior fills with 100
##            chords, no trunk can be traced, and no branch is more central than
##            any other.
##
## Three of the four share one node cloud on purpose. What varies is only what
## folds back, which is the whole subject. `split` is the outlier because it is
## the only value that changes what a root is.
@export_enum("pockets", "none", "split", "total") var mutuality: String = "pockets"

const MUTUALITIES: PackedStringArray = ["pockets", "none", "split", "total"]

## Fixed growth seed. The shipped artifact drew a fresh tangle from the global
## RNG on every _ready, so no two builds ever matched and the pixel critic would
## read pure noise as signal. One draw is now frozen and it is this one — chosen
## because it lands on the numbers the axis is described by: 62 branches at
## `pockets`, a ~19 x 17 x 16 m envelope, 12 pockets.
const RNG_SEED: int = 2726

## split: each root sits this far out along x, so the pair stands 8 m apart.
const SPLIT_ROOT_X: float = 4.0

## split: no node may come nearer the mid-plane than this, which leaves a
## corridor 4 m wide that nothing can cross — a branch joins two nodes on the
## same side, so the segment stays on that side too.
const SPLIT_CORRIDOR_HALF: float = 2.0

## split: branches per root. Two of these against `num_branches` for the single
## rooted values, so the population is the same 50 either way.
const SPLIT_BRANCHES: int = 25

# Nodes in the structure
var nodes: Array[Vector3] = []
var connections: Array[Array] = []

## Which root each node grew from. One cluster for every value but `split`.
var _node_cluster: PackedInt32Array = PackedInt32Array()

## Private growth RNG — see DETERMINISM at the bottom of the file.
var _rng_state: int = 0

## The nodes THIS script made. Only these may ever be freed. The scene carries a
## Camera3D of its own and the grid adds children after _ready — label plates,
## packaging, tags — and freeing get_children() would take all of that with it.
var _spawned: Array[Node3D] = []

## False until _ready has built once. apply_grid_config can arrive before _ready
## on some paths, where there is nothing yet to rebuild.
var _built: bool = false


## Build SYNCHRONOUSLY. Auto-grounding measures this subtree's AABB immediately
## after the artifact is added, and a deferred build would hand it an empty box.
func _ready() -> void:
	_build_all()
	_built = true


func _build_all() -> void:
	generate_structure()
	draw_structure()


# ═══════════════════════════════════════════════════════════════════
# GROWTH
# ═══════════════════════════════════════════════════════════════════

# Generate the rhizomatic structure
func generate_structure() -> void:
	# Clear previous data
	nodes.clear()
	connections.clear()
	_node_cluster.clear()
	_rng_seed(RNG_SEED)

	var roots: Array[Vector3] = []
	var per_root: int = num_branches
	var conn_p: float = connection_probability
	var confine: bool = false

	match mutuality:
		"none":
			# A pure tree. The randf below is still drawn at every candidate
			# pair, exactly as it is at 0.2, so the growth stream is untouched
			# and this is the default's own node cloud minus its chords.
			roots.append(Vector3.ZERO)
			conn_p = 0.0
		"total":
			roots.append(Vector3.ZERO)
			conn_p = 1.0
		"split":
			roots.append(Vector3(-SPLIT_ROOT_X, 0.0, 0.0))
			roots.append(Vector3(SPLIT_ROOT_X, 0.0, 0.0))
			per_root = SPLIT_BRANCHES
			confine = true
		_:
			roots.append(Vector3.ZERO)

	# Both roots exist before either grows, so a cluster's members are only ever
	# its own.
	for i in range(roots.size()):
		nodes.append(roots[i])
		_node_cluster.append(i)

	for ci in range(roots.size()):
		_grow_cluster(ci, roots[ci], per_root, conn_p, confine)


## Grow one rooted cluster. For every value but `split` there is exactly one of
## these and the behaviour is the shipped algorithm unchanged.
func _grow_cluster(cluster_id: int, root: Vector3, count: int, conn_p: float, confine: bool) -> void:
	var members: PackedInt32Array = PackedInt32Array()
	for i in range(nodes.size()):
		if _node_cluster[i] == cluster_id:
			members.append(i)

	for _b in range(count):
		var parent_idx: int = members[_ri(members.size())]
		var parent_pos: Vector3 = nodes[parent_idx]

		# Determine growth direction - partly random, partly influenced by parent's position
		var direction: Vector3 = Vector3(
			_rfr(-1.0, 1.0),
			_rfr(-1.0, 1.0),
			_rfr(-1.0, 1.0)
		).normalized()

		# Mix with a tendency to grow away from center. Under `split` the centre
		# a cluster flees is its OWN root, not the world origin — otherwise the
		# left tangle would grow toward the corridor it is not allowed to enter.
		var rel: Vector3 = parent_pos - root
		var away_from_center: Vector3 = rel.normalized()
		if rel.length() < 0.1:
			away_from_center = Vector3(_rfr(-1.0, 1.0), _rfr(-1.0, 1.0), _rfr(-1.0, 1.0)).normalized()

		direction = direction.lerp(away_from_center, 1.0 - growth_direction_randomness)
		direction = direction.normalized()

		# Calculate new node position
		var branch_length: float = _rfr(min_branch_length, max_branch_length)
		var new_pos: Vector3 = parent_pos + direction * branch_length
		if confine:
			new_pos = _confine(parent_pos, direction, branch_length, root)

		# Add new node
		var new_idx: int = nodes.size()
		nodes.append(new_pos)
		_node_cluster.append(cluster_id)
		members.append(new_idx)

		# Add connection to parent
		connections.append([parent_idx, new_idx])

		# Try to make connections to nearby nodes (rhizomatic property)
		for j in range(new_idx):
			if j == parent_idx:
				continue
			# Under `split` a chord may never leave its cluster. Under every
			# other value there is only one cluster, so this never bites.
			if _node_cluster[j] != cluster_id:
				continue

			var other_pos: Vector3 = nodes[j]
			var distance: float = new_pos.distance_to(other_pos)

			if distance >= min_distance_for_connection and distance <= max_distance_for_connection:
				# Drawn at every candidate pair whatever conn_p is, so the three
				# single-rooted values share one node cloud to the last decimal.
				if _rf() < conn_p:
					connections.append([j, new_idx])


## Keep a node on its own side of the corridor. First try mirroring the growth
## direction in x — a tangle that hits the gap grows back into itself, which is
## what a confined rhizome does. If even the mirrored step would cross (a long
## branch from a node near the boundary), drop the x component entirely and let
## it climb instead; the parent already satisfies the constraint, so the child
## does too.
func _confine(parent_pos: Vector3, direction: Vector3, branch_length: float, root: Vector3) -> Vector3:
	var side: float = signf(root.x)
	if side == 0.0:
		side = 1.0
	var candidate: Vector3 = parent_pos + direction * branch_length
	if side * candidate.x >= SPLIT_CORRIDOR_HALF:
		return candidate

	var mirrored: Vector3 = Vector3(-direction.x, direction.y, direction.z)
	candidate = parent_pos + mirrored * branch_length
	if side * candidate.x >= SPLIT_CORRIDOR_HALF:
		return candidate

	return Vector3(
		parent_pos.x,
		parent_pos.y + mirrored.y * branch_length,
		parent_pos.z + mirrored.z * branch_length
	)


# ═══════════════════════════════════════════════════════════════════
# DRAWING
# ═══════════════════════════════════════════════════════════════════

# Draw the structure using MeshInstances
func draw_structure() -> void:
	for i in range(connections.size()):
		var start_idx: int = connections[i][0]
		var end_idx: int = connections[i][1]

		var start_pos: Vector3 = nodes[start_idx]
		var end_pos: Vector3 = nodes[end_idx]

		create_branch(start_pos, end_pos, _edge_thickness(start_idx, end_idx))


# Create a cylindrical branch between two points
func create_branch(start: Vector3, end: Vector3, thickness: float) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	add_child(mesh_instance)
	_spawned.append(mesh_instance)

	var direction: Vector3 = end - start
	var length: float = direction.length()
	direction = direction.normalized()

	# Create cylinder mesh
	var cylinder_mesh: CylinderMesh = CylinderMesh.new()
	cylinder_mesh.top_radius = thickness
	cylinder_mesh.bottom_radius = thickness
	cylinder_mesh.height = length

	if material:
		cylinder_mesh.material = material

	mesh_instance.mesh = cylinder_mesh

	# Position and rotate the cylinder
	mesh_instance.position = start + direction * (length / 2)

	# Calculate rotation to align with direction
	var origin: Vector3 = Vector3(0, 1, 0)
	var axis: Vector3 = origin.cross(direction).normalized()
	var angle: float = origin.angle_to(direction)

	if axis.length() < 0.001:
		if direction.dot(origin) > 0:
			mesh_instance.rotation = Vector3.ZERO
		else:
			mesh_instance.rotation = Vector3(PI, 0, 0)
	else:
		mesh_instance.transform.basis = Basis(axis, angle)


## Thickness is a hash of the two node indices, not a draw from the growth
## stream. A tree edge therefore renders at the SAME thickness under `none`,
## `pockets` and `total` — so the only difference between those three frames is
## which branches exist, which is the axis. Drawing it from the RNG would have
## re-thicknessed all 50 shared edges the moment 12 chords were inserted ahead
## of them in the list.
func _edge_thickness(a: int, b: int) -> float:
	var h: int = ((a + 1) * 73856093) ^ ((b + 1) * 19349663)
	h = h & 0x7FFFFFFF
	h = (h * 1103515245 + 12345) & 0x7FFFFFFF
	var t: float = float(h % 100000) / 100000.0
	return min_branch_thickness + (max_branch_thickness - min_branch_thickness) * t


# ═══════════════════════════════════════════════════════════════════
# DETERMINISM
# ═══════════════════════════════════════════════════════════════════
#
# A private 32-bit LCG rather than the global RNG. Local, so a `randomize()`
# anywhere else in the scene cannot reach it, and small enough to be replayed
# exactly outside Godot — which is how the branch counts and envelopes quoted
# above were measured without running a capture.
#
# (`_rng_state` is declared with the other members at the top of the class.)


func _rng_seed(s: int) -> void:
	_rng_state = s & 0xFFFFFFFF


func _rf() -> float:
	_rng_state = (_rng_state * 1664525 + 1013904223) & 0xFFFFFFFF
	return float(_rng_state) / 4294967296.0


func _rfr(a: float, b: float) -> float:
	return a + (b - a) * _rf()


func _ri(n: int) -> int:
	_rng_state = (_rng_state * 1664525 + 1013904223) & 0xFFFFFFFF
	return _rng_state % n


# ═══════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════

## Clear the structure. Frees ONLY what this script grew — it used to free every
## child, which took the scene's own Camera3D and any grid-added plate with it.
func clear() -> void:
	for c: Node3D in _spawned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_spawned.clear()

	nodes.clear()
	connections.clear()
	_node_cluster.clear()


## Regenerate the structure. Synchronous — nothing here is deferred, so the new
## tangle is standing before the frame ends.
func regenerate() -> void:
	_rebuild_now()


func _rebuild_now() -> void:
	clear()
	_build_all()


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	var before_mutuality: String = mutuality

	# Stage-2 DNA axis — #mutuality:none
	if config_data.has("mutuality"):
		mutuality = _pick_axis(str(config_data["mutuality"]), MUTUALITIES, mutuality)

	# No `emissive` key is accepted. curation_station hands every artifact it
	# curates {"emissive": false} one line after framing its labels; this one has
	# no emission to switch off, and accepting a key we would apply nowhere is
	# the exact lie this contract exists to stop. It falls through to the
	# early-return below and changes nothing, which is correct.

	if not _built:
		# _ready has not run yet; it will build with the value just resolved.
		return
	if mutuality == before_mutuality:
		# Nothing geometric changed. Rebuilding here would throw away the dark,
		# un-billboarded framing curation_station just applied.
		return

	_rebuild_now()
	print("[RhizomaticStructure] Config applied — mutuality=%s" % [mutuality])


## Accept an axis value only if it names something we actually grow. A typo in a
## map token has to land on the shipped look whole — a half-recognised value
## would strand a placement with a corridor and no second cluster to face it.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback
