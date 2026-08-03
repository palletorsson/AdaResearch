extends Node3D

# Script to create a 1x1x1 cube outline with lines

## AXIS 1 — DISCLOSURE: how much of the cube the drawing asserts, and how much it hands to
## the eye to infer. The registry already says what this artifact is for — "twelve thin lines
## and no faces: the cube reduced to its adjacency, an inventory of edges showing the volume
## was always an inference the eye supplies." Shipping only the complete twelve made that one
## sentence unarguable. Each value keeps the SAME twelve edge positions and changes only which
## of them are drawn, so nothing moves and nothing is invented — the cube is stated at a
## different volume of speech.
##
##   frame        all twelve edges, equal weight, nothing occluded — the x-ray claim. A cube
##                is its complete adjacency, and the drawing openly lies about what a body
##                would hide. THE LEGACY LINEAGE, byte for byte.
##   visible      the nine a solid cube would show from the near corner; the three meeting the
##                far vertex are dropped. The draughtsman's hidden-line removal — this asserts
##                a VIEWER and an opaque body, which the wireframe refuses to.
##   silhouette   the six edges of the hexagonal outline, the ones touching neither the near
##                nor the far vertex — the cube as its own boundary. Every interior edge gone,
##                the volume left entirely to inference. The strongest form of the claim.
##   plan         the four floor edges — the cube as a FOOTPRINT, the drawing an architect
##                makes. Height is asserted nowhere; a plan is a cube that declined to have one.
##   corner       the three edges meeting at the far-back-left vertex — exactly the three that
##                `visible` hides. Not a cube at all any more but a coordinate triad: three
##                directions leaving an origin, the cube as the thing those axes would enclose.
@export var disclosure: String = "frame"
const DISCLOSURES: PackedStringArray = ["frame", "visible", "silhouette", "plan", "corner"]

## AXIS 2 — CODING: whether the twelve edges are one family or several, and by what. The
## legacy answer is a single blue for all twelve: the cube is ONE THING and its edges are
## interchangeable. That is a position, not a neutral fact, and the folder it lives in argues
## the other side — LINE_POETICS.md holds that a vertical and a horizontal have different
## roles, that turning the image 45° gives each a new one.
##
##   uniform   one blue on all twelve — the edges are interchangeable members of one object.
##             THE LEGACY LINEAGE, Color(0.4, 0.8, 1.0) exactly as it shipped.
##   axes      red / green / blue by the direction the edge runs — the CAD convention. The
##             cube is not one thing but THREE DIRECTIONS, met at right angles; the object
##             is a side effect of the coordinate system.
##   depth     the legacy blue fading toward the dark by distance from the near corner — the
##             draughtsman's depth cue. The edges are equal in the world and unequal in the
##             picture, which is what having a viewpoint costs.
##   horizon   verticals amber, horizontals the legacy blue — the plumb and the horizon,
##             LINE_POETICS' own division. Gravity sorts the edges into two families, and
##             the cube is where those two families meet.
@export var coding: String = "uniform"
const CODINGS: PackedStringArray = ["uniform", "axes", "depth", "horizon"]

const EDGE_THICKNESS: float = 0.008
const LEGACY_TINT: Color = Color(0.4, 0.8, 1.0, 1.0)
const NEAR_CORNER: Vector3 = Vector3(0.5, 0.5, 0.5)
const FAR_CORNER: Vector3 = Vector3(-0.5, -0.5, -0.5)

var _built: bool = false


func _ready():
	setup_cube()
	_built = true

func setup_cube():
	if not DISCLOSURES.has(disclosure):
		disclosure = "frame"
	if not CODINGS.has(coding):
		coding = "uniform"

	# Define the 8 vertices of a 1x1x1 cube centered at origin
	var vertices = [
		# Bottom face (y = -0.5)
		Vector3(-0.5, -0.5, -0.5),  # 0: Bottom-back-left
		Vector3(0.5, -0.5, -0.5),   # 1: Bottom-back-right
		Vector3(0.5, -0.5, 0.5),    # 2: Bottom-front-right
		Vector3(-0.5, -0.5, 0.5),   # 3: Bottom-front-left
		# Top face (y = 0.5)
		Vector3(-0.5, 0.5, -0.5),   # 4: Top-back-left
		Vector3(0.5, 0.5, -0.5),    # 5: Top-back-right
		Vector3(0.5, 0.5, 0.5),     # 6: Top-front-right
		Vector3(-0.5, 0.5, 0.5)     # 7: Top-front-left
	]

	# Define the 12 edges of the cube
	var line_configs = [
		# Bottom face (4 edges)
		{"line_name": "Line1", "start": vertices[0], "end": vertices[1]},   # Back edge
		{"line_name": "Line2", "start": vertices[1], "end": vertices[2]},   # Right edge
		{"line_name": "Line3", "start": vertices[2], "end": vertices[3]},   # Front edge
		{"line_name": "Line4", "start": vertices[3], "end": vertices[0]},   # Left edge
		# Top face (4 edges)
		{"line_name": "Line5", "start": vertices[4], "end": vertices[5]},   # Back edge
		{"line_name": "Line6", "start": vertices[5], "end": vertices[6]},   # Right edge
		{"line_name": "Line7", "start": vertices[6], "end": vertices[7]},   # Front edge
		{"line_name": "Line8", "start": vertices[7], "end": vertices[4]},   # Left edge
		# Vertical edges (4 edges)
		{"line_name": "Line9", "start": vertices[0], "end": vertices[4]},   # Back-left vertical
		{"line_name": "Line10", "start": vertices[1], "end": vertices[5]},  # Back-right vertical
		{"line_name": "Line11", "start": vertices[2], "end": vertices[6]},  # Front-right vertical
		{"line_name": "Line12", "start": vertices[3], "end": vertices[7]}   # Front-left vertical
	]

	# Configure each line. Positions and thickness are the shipped ones for every value of
	# every axis — DISCLOSURE only decides whether an edge is drawn, CODING only its tint.
	var drawn: PackedInt32Array = _drawn_edges()
	for idx in range(line_configs.size()):
		var config: Dictionary = line_configs[idx]
		var edge_name: String = str(config["line_name"])
		var start: Vector3 = config["start"]
		var end: Vector3 = config["end"]

		var line_root: Node3D = get_node_or_null(edge_name) as Node3D
		if line_root:
			line_root.visible = drawn.has(idx + 1)

		var line_node = get_node_or_null(edge_name + "/lineContainer")
		if line_node:
			# Set positions
			line_node.set_positions(start, end)

			# Set line properties
			line_node.set_line_properties(EDGE_THICKNESS, _edge_tint(start, end))


# ── DISCLOSURE ───────────────────────────────────────────────────────────────
# Which of the twelve are drawn, by the numbering in line_configs above. Nothing here moves
# an edge; a hidden edge keeps its place in the scene and its place in the list.
func _drawn_edges() -> PackedInt32Array:
	match disclosure:
		"visible":
			# everything except the three meeting the far vertex (Line1, Line4, Line9)
			return PackedInt32Array([2, 3, 5, 6, 7, 8, 10, 11, 12])
		"silhouette":
			# the hexagon: edges touching neither the near nor the far vertex
			return PackedInt32Array([2, 3, 5, 8, 10, 12])
		"plan":
			# the bottom face alone
			return PackedInt32Array([1, 2, 3, 4])
		"corner":
			# the triad at the far vertex — the exact complement of "visible"
			return PackedInt32Array([1, 4, 9])
		_:
			return PackedInt32Array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])


# ── CODING ───────────────────────────────────────────────────────────────────
func _edge_tint(start: Vector3, end: Vector3) -> Color:
	var run: Vector3 = (end - start).abs()
	match coding:
		"axes":
			if run.x >= run.y and run.x >= run.z:
				return Color(1.0, 0.42, 0.38, 1.0)
			if run.y >= run.z:
				return Color(0.45, 0.95, 0.50, 1.0)
			return LEGACY_TINT
		"depth":
			var mid: Vector3 = (start + end) * 0.5
			var reach: float = NEAR_CORNER.distance_to(FAR_CORNER)
			var t: float = clampf(mid.distance_to(NEAR_CORNER) / maxf(reach, 0.001), 0.0, 1.0)
			return LEGACY_TINT.lerp(Color(0.08, 0.14, 0.24, 1.0), t)
		"horizon":
			if run.y >= run.x and run.y >= run.z:
				return Color(1.0, 0.72, 0.30, 1.0)
			return LEGACY_TINT
		_:
			return LEGACY_TINT


# Guarded: only rebuilds when a value the artifact can actually build ARRIVED and DIFFERS,
# and only once _ready has already built the cube. A map that names no axis never reaches
# setup_cube() a second time, so shipped placements are untouched. An unrecognised word keeps
# the current value rather than falling through to a default — a typo must not silently
# become a different claim.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return

	var changed: bool = false

	if config_data.has("disclosure"):
		var want_d: String = str(config_data["disclosure"]).strip_edges().to_lower()
		if DISCLOSURES.has(want_d) and want_d != disclosure:
			disclosure = want_d
			changed = true

	if config_data.has("coding"):
		var want_c: String = str(config_data["coding"]).strip_edges().to_lower()
		if CODINGS.has(want_c) and want_c != coding:
			coding = want_c
			changed = true

	if changed and _built:
		setup_cube()
