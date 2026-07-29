extends Node3D

# @identity
# essence: all lines → (0,0,0) — convergence to a single vanishing point as perspective law
# desire: learner sees how parallel lines in 3D space appear to converge when projected onto a 2D view
# critical_parameter: the shared origin — all four line endpoints are forced to (0,0,0)
# triggers: nothing at runtime — configured once in _ready() and remains static
# emerges: the vanishing point as the infinite location of all parallel directions — a limit, not a place
# needs: [missing VR controls — static demonstration only]
# relationships: sibling to scale_lines; both are special configurations of the line primitive
# truth: perspective is not distortion — it is projection, and projection reveals the vanishing point

# Script to ensure perspective lines converge correctly to a vanishing point

# --- DNA (stage 2, promoted 2026-07-29) -------------------------------------
# vanishing_points: the artifact's own declared critical_parameter — "all four
#   line endpoints are forced to (0,0,0)" — was a literal Vector3.ZERO shared by
#   every line. That forcing is the whole argument, and it was unreachable. One
#   point says: all parallels meet in one place, the law as Alberti stated it.
#   Two says: WHICH point depends on which family of parallels you are following,
#   so the vanishing point is a property of a direction, not of the world. Three
#   adds the zenith and withdraws the last exemption — even "up" converges once
#   the picture plane is tilted. Same four lines, three different claims about
#   what perspective is.
# reach: whether the lines arrive. The identity line already says the vanishing
#   point is "a limit, not a place", and the shipped drawing contradicts it by
#   letting all four cylinders touch the point and stop there. "short" leaves the
#   gap — the point is where they WOULD meet. "through" runs them past it, so
#   convergence reads as a crossing seen from here rather than a destination.
const VANISHING_MODES = ["one", "two", "three"]
const REACH_MODES = {
	"touch": 1.0,
	"short": 0.82,
	"through": 1.35,
}

const FRAME_Z := -2.0
const FRAME_HALF := 0.5
const LINE_THICKNESS := 0.008

# Index 0 is the shipped colour; in "one" mode every line uses it, so the
# default placement is unchanged. The other two only appear once there is more
# than one family of parallels to tell apart.
const FAMILY_COLORS = [
	Color(1.0, 0.3, 0.5, 1.0),
	Color(0.35, 0.85, 1.0, 1.0),
	Color(1.0, 0.78, 0.3, 1.0),
]

@export_enum("one", "two", "three") var vanishing_points: String = "one"
@export_enum("touch", "short", "through") var reach: String = "touch"

var _built: bool = false

func _ready():
	setup_perspective_lines()

func setup_perspective_lines():
	# The four corners of the rectangle in the distance
	var corners: Array[Vector3] = [
		Vector3(-FRAME_HALF, -FRAME_HALF, FRAME_Z),  # Bottom-left
		Vector3(FRAME_HALF, -FRAME_HALF, FRAME_Z),   # Bottom-right
		Vector3(-FRAME_HALF, FRAME_HALF, FRAME_Z),   # Top-left
		Vector3(FRAME_HALF, FRAME_HALF, FRAME_Z)     # Top-right
	]

	var targets: Array[Vector3] = _targets_for_mode()
	var families: Array[int] = _families_for_mode()
	var travel: float = float(REACH_MODES.get(reach, 1.0))

	# Configure each line
	for i in range(4):
		var line_node = get_node_or_null("Line" + str(i + 1) + "/lineContainer")
		if line_node == null:
			continue

		var start_point: Vector3 = corners[i]
		var vanishing_point: Vector3 = targets[i]
		var end_point: Vector3 = start_point.lerp(vanishing_point, travel)

		# Set positions - one point at the corner, one at (or past, or short of)
		# the vanishing point
		line_node.set_positions(start_point, end_point)

		# Set line properties
		var family: int = families[i]
		line_node.set_line_properties(LINE_THICKNESS, FAMILY_COLORS[family])

	_built = true

func _targets_for_mode() -> Array[Vector3]:
	# Order matches `corners`: bottom-left, bottom-right, top-left, top-right.
	if vanishing_points == "two":
		var left := Vector3(-1.6, 0.0, 0.0)
		var right := Vector3(1.6, 0.0, 0.0)
		var pair: Array[Vector3] = [left, right, left, right]
		return pair

	if vanishing_points == "three":
		var left_low := Vector3(-1.6, -0.15, 0.0)
		var right_low := Vector3(1.6, -0.15, 0.0)
		var zenith := Vector3(0.0, 1.9, 0.0)
		var triple: Array[Vector3] = [left_low, right_low, zenith, zenith]
		return triple

	# "one" — the shipped behaviour: every endpoint forced to the origin.
	var origin := Vector3.ZERO
	var single: Array[Vector3] = [origin, origin, origin, origin]
	return single

func _families_for_mode() -> Array[int]:
	if vanishing_points == "two":
		var pair: Array[int] = [0, 1, 0, 1]
		return pair
	if vanishing_points == "three":
		var triple: Array[int] = [0, 1, 2, 2]
		return triple
	var single: Array[int] = [0, 0, 0, 0]
	return single

func apply_grid_config(config_data: Dictionary) -> void:
	# Guarded: rebuild only when a declared value actually changed and _ready has
	# already run once. A placement that passes no vanishing_points/reach token is
	# left exactly as it shipped.
	var changed: bool = false

	if config_data.has("vanishing_points"):
		var want: String = str(config_data["vanishing_points"]).strip_edges().to_lower()
		if VANISHING_MODES.has(want) and want != vanishing_points:
			vanishing_points = want
			changed = true

	if config_data.has("reach"):
		var want_reach: String = str(config_data["reach"]).strip_edges().to_lower()
		if REACH_MODES.has(want_reach) and want_reach != reach:
			reach = want_reach
			changed = true

	if changed and _built:
		setup_perspective_lines()
