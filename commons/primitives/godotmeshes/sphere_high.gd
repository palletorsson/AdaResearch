# sphere_high.gd - The high-resolution member of the sphere trio (16 rings, 16 radial segments)
extends MeshInstance3D

# @identity
# essence: SphereMesh(rings=16, radial_segments=16) — a sphere approximated by many small triangles
# desire: learner sees that a smooth sphere in 3D is a polygon mesh — smoothness is a resolution choice
# critical_parameter: rings and radial_segments — together they determine polygon count and visual smoothness
# triggers: nothing — static; placed alongside sphere_low and sphere_mid for direct comparison
# emerges: the point where more polygons stop being visually distinguishable — the perceptual limit
# needs: [missing VR controls — static display only]
# relationships: comparison trio with sphere_low and sphere_mid; grid material makes polygon faces visible
# truth: there is no smooth sphere in real-time 3D — only denser approximations approaching one

# --- DNA (stage 2, promoted 2026-07-29) -------------------------------------
# tessellation: the artifact's own declared critical_parameter, which until now
#   was two literals nobody could reach. The trio sphere_low/mid/high spends
#   three tokens saying "smoothness is a resolution choice"; this axis lets one
#   token say it. At "coarse" the object stops pretending — it is visibly a
#   polyhedron. At "ultra" it lies convincingly.
# facets: whether the approximation is admitted. The grid shader draws the
#   actual triangle edges, so the mesh confesses what it is made of ("shown").
#   "hidden" is the same geometry shaded as though it were a surface — the
#   illusion the truth line argues against, staged instead of exposed. "only"
#   drops the fill and leaves nothing but the confession.
#   (Named facets, not skin: MeshInstance3D already owns a `skin` property.)
const TESSELLATION = {
	"coarse": 4,
	"low": 7,
	"high": 16,
	"ultra": 32,
}
const FACET_MODES = ["shown", "hidden", "only"]
const BASE_COLOR := Color(0.9, 0.8, 0.3)

# Named GridMatFactory, not GridMaterialFactory — that identifier is a global
# class name and shadowing it at script scope is a parse error.
const GridMatFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")

@export_enum("coarse", "low", "high", "ultra") var tessellation: String = "high"
@export_enum("shown", "hidden", "only") var facets: String = "shown"

var _built: bool = false

func _ready():
	_build()

func _build() -> void:
	var segments: int = int(TESSELLATION.get(tessellation, 16))

	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	sphere_mesh.radial_segments = segments
	sphere_mesh.rings = segments

	mesh = sphere_mesh
	material_override = _build_material()
	_built = true

func _build_material() -> Material:
	if facets == "hidden":
		# No wireframe: the same triangles, rendered as if they were a surface.
		var plain := StandardMaterial3D.new()
		plain.albedo_color = BASE_COLOR
		plain.emission_enabled = true
		plain.emission = BASE_COLOR * 0.3
		return plain
	if facets == "only":
		return GridMatFactory.make(BASE_COLOR, {"show_only_wireframe": true})
	# "shown" — the shipped SimpleGrid material, unchanged.
	return GridMatFactory.make(BASE_COLOR, {})

func apply_grid_config(config_data: Dictionary) -> void:
	# Guarded: rebuild only when a declared value actually changed and _ready
	# has already built once. A placement that passes no tessellation/facets
	# token is left exactly as it shipped.
	var changed: bool = false

	if config_data.has("tessellation"):
		var want: String = str(config_data["tessellation"]).strip_edges().to_lower()
		if TESSELLATION.has(want) and want != tessellation:
			tessellation = want
			changed = true

	if config_data.has("facets"):
		var want_facets: String = str(config_data["facets"]).strip_edges().to_lower()
		if FACET_MODES.has(want_facets) and want_facets != facets:
			facets = want_facets
			changed = true

	if changed and _built:
		_build()
