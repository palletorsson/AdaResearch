# sphere_mid.gd - Medium poly sphere (7 rings, 7 radial segments)
extends MeshInstance3D

# @identity
# essence: SphereMesh(rings=7, radial_segments=7) — mid-resolution sphere where the trade-off is legible
# desire: learner sees the transitional zone — faces are visible but the sphere reads as round at a distance
# critical_parameter: rings=7 and radial_segments=7 — the middle ground where geometry meets perception
# triggers: nothing — static; placed between sphere_low and sphere_high in the comparison trio
# emerges: the subjective nature of "enough resolution" — what counts as smooth depends on viewing distance
# needs: [missing VR controls — static display only]
# relationships: middle of the trio with sphere_low and sphere_high; cyan color distinguishes it from siblings
# truth: resolution is a budget decision — there is no correct polygon count, only contextually sufficient ones

# --- DNA (stage 2, promoted 2026-07-29) -------------------------------------
# resolution: how much budget. The artifact's own declared critical_parameter,
#   which until now was two literals nobody could reach.
# budget_bias: how the SAME budget is spent. This is the axis that belongs to
#   the middle term specifically. sphere_low/mid/high already argue about the
#   AMOUNT of resolution; nothing in the trio argues that a polygon budget is
#   also a DIRECTION. rings and radial_segments were both 7 — an isotropic
#   assumption presented as if it were the only option. At "latitude" the same
#   triangle count buys smooth vertical profile and coarse horizontal (a barrel
#   of stacked bands); at "longitude" it buys smooth horizontal and coarse
#   vertical (an orange cut into gores). Neither is worse. That is the point:
#   the truth line says resolution is a budget decision, and a budget is spent
#   somewhere, not merely sized.
const RESOLUTION = {
	"coarse": 4,
	"mid": 7,
	"fine": 16,
	"ultra": 32,
}
const BUDGET_MODES = ["even", "latitude", "longitude"]
const BASE_COLOR := Color(0.3, 0.8, 0.9)

# Named GridMatFactory, not GridMaterialFactory — that identifier is a global
# class name and shadowing it at script scope is a parse error.
const GridMatFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")

@export_enum("coarse", "mid", "fine", "ultra") var resolution: String = "mid"
@export_enum("even", "latitude", "longitude") var budget_bias: String = "even"

var _built: bool = false

func _ready():
	_build()

func _build() -> void:
	var n: int = int(RESOLUTION.get(resolution, 7))
	var rings: int = n
	var segments: int = n

	# Same budget, spent in a direction. n*2 by n/2 keeps the face count in the
	# same neighbourhood as n by n, so the comparison is about distribution.
	if budget_bias == "latitude":
		rings = n * 2
		segments = int(max(3.0, round(float(n) / 2.0)))
	elif budget_bias == "longitude":
		segments = n * 2
		rings = int(max(3.0, round(float(n) / 2.0)))

	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	sphere_mesh.radial_segments = segments
	sphere_mesh.rings = rings

	mesh = sphere_mesh

	# Apply grid material — unchanged; the wireframe is what makes the budget visible.
	material_override = GridMatFactory.make(BASE_COLOR, {})
	_built = true

func apply_grid_config(config_data: Dictionary) -> void:
	# Guarded: rebuild only when a declared value actually changed and _ready has
	# already built once. A placement that passes no resolution/budget_bias token
	# is left exactly as it shipped.
	var changed: bool = false

	if config_data.has("resolution"):
		var want: String = str(config_data["resolution"]).strip_edges().to_lower()
		if RESOLUTION.has(want) and want != resolution:
			resolution = want
			changed = true

	if config_data.has("budget_bias"):
		var want_bias: String = str(config_data["budget_bias"]).strip_edges().to_lower()
		if BUDGET_MODES.has(want_bias) and want_bias != budget_bias:
			budget_bias = want_bias
			changed = true

	if changed and _built:
		_build()
