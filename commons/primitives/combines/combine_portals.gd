extends Node3D

# @identity
# essence: portals[i].ring_segments = base_segments + i*increment — a progression of torus discretization levels
# desire: learner walks through a corridor of increasingly refined tori and feels resolution as spatial experience
# critical_parameter: portal_count — how many steps the resolution ladder has; more steps = finer progression
# triggers: nothing at runtime — all portals are placed at ready() along Z axis
# emerges: the relationship between segment count and perceived smoothness — resolution is a resource allocation
# needs: [missing VR controls — purely spatial/visual; walk through to experience]
# relationships: demonstrates combine/instantiation pattern; related to sphere_low/mid/high resolution comparison
# truth: every smooth curve in 3D graphics is an illusion — beneath it are polygons, and you choose how many


# Spine-corridor contract — this artifact extends ~90m along +Z (20 portals
# × 4.5m spacing), which is 5+ corridor lengths. Tagged "oversized" so the
# spine_corridor generator skips it in 16m corridors.
func spine_hints() -> Dictionary:
	return {
		"role":         "primary",
		"footprint":    Vector2i(2, 16),
		"approach":     "south",
		"reading_dist": 1.0,
		"budget_ms":    3.0,
		"tags":         ["oversized", "corridor_incompatible"],
	}


@export var portal_count: int = 20
@export var portal_spacing: float = 4.5
@export var base_path: NodePath = NodePath("Lowrestorus")

## AXIS — WHAT ORDER THE SWEEP CLAIMS ITS FAMILY HAS. The members never change: the same
## twenty tori are built, in the same order, with the same rings and the same ring_segments
## on each. What changes is whether the display asserts that the family has a structure,
## and whose structure it is. Adopted word for word from [[combine_sphere]] and
## [[combine_capsule]], which sit in this same folder and are the same apparatus pointed at
## a different primitive — one grammar, one vocabulary, so a room holding all three cannot
## have two of them arguing taxonomy and the third arguing corridor.
##
##   table    the cross-product folded into a reading lattice — five across, four up,
##            every member at eye level and comparable to its neighbour without walking.
##            The periodic-table claim: the order is in the objects and the display
##            merely reports it.
##   ladder   one ascending file down +Z, each ring 4.5 m further away than the last.
##            The claim that the family is a SEQUENCE with a direction — coarse to fine,
##            near to far — and that you have to WALK it to have read it. THE LEGACY
##            LINEAGE, coordinate for coordinate.
##   stack    one column on one footprint, every ring through the same centre. The claim
##            that these are not twenty objects but ONE ring described twenty times.
##   heap     coordinates abandoned: the members piled at the origin on a hash of their
##            own index. The claim that the ordering was ours all along and the rings
##            never had it.
##
## THE EXTENT IS THE PIVOT HERE, where the captions are the pivot on combine_sphere. This
## artifact's own spine_hints() call it "oversized" and "corridor_incompatible" because
## `ladder` is ninety metres long: it is the one value you cannot see all of from anywhere,
## and the other three are the same twenty rings brought into a single view. Choosing a
## value chooses whether the resolution ladder is a thing you walk or a thing you read.
@export_enum("table", "ladder", "stack", "heap") var taxonomy: String = "ladder"
const TAXONOMIES: PackedStringArray = ["table", "ladder", "stack", "heap"]

## Columns in `table`. Five across × four up covers the default twenty without a ragged
## last row, and keeps the lattice wider than it is tall so it reads as a chart.
const TAX_COLS := 5

var _base_portal: MeshInstance3D
var _base_mesh: TorusMesh

func _ready() -> void:
	var t: String = str(taxonomy).strip_edges().to_lower()
	taxonomy = t if TAXONOMIES.has(t) else "ladder"
	_base_portal = get_node_or_null(base_path) as MeshInstance3D
	if _base_portal == null:
		push_warning("CombinePortals: Base portal node not found at %s" % base_path)
		return

	if _base_portal.get_parent() != self:
		push_warning("CombinePortals: Base portal must be a direct child of CombinePortals")
		return

	_base_mesh = _base_portal.mesh as TorusMesh
	if _base_mesh == null:
		push_warning("CombinePortals: Base portal requires a TorusMesh")
		return

	spawn_portals()

func spawn_portals() -> void:
	if _base_portal == null or _base_mesh == null:
		return

	_clear_existing_portals()
	_base_portal.visible = false

	var count = max(portal_count, 1)
	var spacing = max(portal_spacing, 0.1)
	var base_transform := _base_portal.transform

	var start_rings = max(_base_mesh.rings, 3)
	var start_segments = max(_base_mesh.ring_segments, 3)

	for i in range(count):
		var portal_instance := _base_portal.duplicate()
		portal_instance.visible = true
		portal_instance.name = "Portal_%02d" % i

		var transform := base_transform
		transform.origin += _taxonomy_offset(i, count, spacing)
		portal_instance.transform = transform

		var mesh_copy := _base_mesh.duplicate() as TorusMesh
		mesh_copy.rings = start_rings + i
		mesh_copy.ring_segments = start_segments + i * 2
		portal_instance.mesh = mesh_copy

		if owner:
			portal_instance.owner = owner
		add_child(portal_instance)

func _clear_existing_portals() -> void:
	for child in get_children():
		if child == _base_portal:
			continue
		if child.name.begins_with("Portal_"):
			child.queue_free()


## Gated on the key: a map that says nothing about taxonomy gets no rebuild at all, so a
## token carrying only other keys cannot disturb the corridor that is already standing.
## This artifact had no apply_grid_config before, so `combine_portals#taxonomy:table` in a
## map is the first configuration it has ever been able to hear.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("taxonomy"):
		return
	var want: String = str(config_data["taxonomy"]).strip_edges().to_lower()
	if not TAXONOMIES.has(want) or want == taxonomy:
		return
	taxonomy = want
	spawn_portals()


# ── TAXONOMY ─────────────────────────────────────────────────────────────────
# One axis, four claims about whether the family has an order. Shared word for word with
# combine_sphere.gd and combine_capsule.gd. Appended LAST so nothing above it moved:
# `ladder` returns the offset the legacy loop already applied — Vector3(0, 0, i * spacing),
# the same float, in the same place in the same statement — and every portal keeps its
# name, its mesh, its owner and its child index. The other three discard the file and
# re-site the member from its index alone. NO MESH IS TOUCHED BY THIS AXIS: rings and
# ring_segments are still start + i and start + 2i on every value, so what the corridor
# teaches about resolution is identical in all four.

## Where a member of the sweep stands, as an offset from the authored base transform.
func _taxonomy_offset(index: int, count: int, spacing: float) -> Vector3:
	match taxonomy:
		"table":
			# The file folded into a lattice. One cell is two spacings wide so the rings
			# stand clear of each other instead of threading through their neighbours,
			# and the grid is centred on the base so the chart faces you square.
			var cell: float = spacing * 2.0
			var cols: int = maxi(mini(TAX_COLS, count), 1)
			var rows: int = int(ceil(float(count) / float(cols)))
			var col: int = index % cols
			var row: int = index / cols
			return Vector3(
				(float(col) - float(cols - 1) * 0.5) * cell,
				(float(row) - float(rows - 1) * 0.5) * cell,
				0.0)
		"stack":
			# One column on one footprint: the same ring, described again and again.
			return Vector3(0.0, float(index) * spacing * 0.34, 0.0)
		"heap":
			# Coordinates abandoned. The scatter is a HASH of the index, never randf():
			# a random render path would make each sweep frame a different pile, and the
			# critic would be measuring the noise instead of the axis. The radius is
			# scaled to the RING's girth rather than to combine_sphere's bead spacing —
			# a pile has to be loose enough to read as a pile.
			var a: float = _index_hash(index * 2 + 1) * TAU
			var r: float = spacing * 1.6 * sqrt(_index_hash(index * 2 + 2))
			return Vector3(cos(a) * r, _index_hash(index * 2 + 7) * spacing * 0.9, sin(a) * r)
		_:
			return Vector3(0.0, 0.0, float(index) * spacing)   # "ladder" — the legacy file


## Deterministic 0..1 from an integer. Same value every boot, every frame, every machine.
func _index_hash(n: int) -> float:
	var s: float = sin(float(n) * 12.9898 + 78.233) * 43758.5453
	return s - floor(s)
