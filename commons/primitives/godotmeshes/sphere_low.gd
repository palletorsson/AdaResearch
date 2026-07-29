# sphere_low.gd - Low poly sphere (rings=1, radial_segments=10)
extends MeshInstance3D

# @identity
# essence: SphereMesh(rings=1, radial_segments=10) — a coarse sphere approximation revealing polygon faces
# desire: learner clearly sees the triangles that constitute the sphere — the illusion of roundness dissolves
# critical_parameter: rings=1 and radial_segments=10 — the minimum that still reads as "sphere-like"
# triggers: nothing — static; placed first in the resolution comparison trio
# emerges: that "low poly" is not a failure — it is a deliberate aesthetic that exposes the underlying geometry
# needs: [missing VR controls — static display only]
# relationships: first in the trio with sphere_mid and sphere_high; grid material makes faces visible
# truth: the low-poly sphere is more honest than the high-poly one — it does not pretend to be smooth

# --- DNA (stage 2, promoted 2026-07-29) -------------------------------------
# grain: the axis this artifact was hiding. rings=1 and radial_segments=10 are
#   not "low resolution" — they are a low resolution spent ENTIRELY IN ONE
#   DIRECTION. The shipped sphere is cut by ten meridians and no parallels, so
#   it reads as a lantern: coarse around the equator, catastrophic at the poles.
#   The three values all spend the same budget (~20 quads) and disagree about
#   where it goes: "meridian" 1x10 (shipped), "parallel" 10x3 — the transpose,
#   a banded spindle that stops reading as a ball at all, and "even" 4x4 — the
#   isotropic low-poly sphere everyone pictures when they say "low poly".
#   Turning this knob does not make the object bigger or smaller or smoother.
#   It changes WHICH failure of the approximation you are looking at, which is
#   the trio's whole argument stated inside a single token.
# facets: inherited deliberately from sphere_high so the trio shares one word.
#   The grid shader draws real triangle edges, so the mesh confesses what it is
#   made of ("shown"). "hidden" shades the same 20 quads as though they were a
#   surface — the pretence the truth line above accuses the high-poly sphere of,
#   staged here on the member least able to carry it. "only" drops the fill and
#   leaves nothing but the confession.
#   (Named facets, not skin: MeshInstance3D already owns a `skin` property.)
const GRAIN = {
	"meridian": [1, 10],
	"parallel": [10, 3],
	"even": [4, 4],
}
const FACET_MODES = ["shown", "hidden", "only"]
const BASE_COLOR := Color(0.8, 0.3, 0.9)

# Named GridMatFactory, not GridMaterialFactory — that identifier is a global
# class name and shadowing it at script scope is a parse error.
const GridMatFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")

@export_enum("meridian", "parallel", "even") var grain: String = "meridian"
@export_enum("shown", "hidden", "only") var facets: String = "shown"

var _built: bool = false

func _ready() -> void:
	_build()

func _build() -> void:
	var spec: Array = GRAIN.get(grain, GRAIN["meridian"])
	var ring_count: int = int(spec[0])
	var segment_count: int = int(spec[1])

	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	sphere_mesh.radial_segments = segment_count
	sphere_mesh.rings = ring_count

	mesh = sphere_mesh
	material_override = _build_material()
	_built = true

func _build_material() -> Material:
	if facets == "hidden":
		# No wireframe: the same triangles, shaded as if they were a surface.
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
	# has already built once. A placement that passes no grain/facets token is
	# left exactly as it shipped.
	var changed: bool = false

	if config_data.has("grain"):
		var want: String = str(config_data["grain"]).strip_edges().to_lower()
		if GRAIN.has(want) and want != grain:
			grain = want
			changed = true

	if config_data.has("facets"):
		var want_facets: String = str(config_data["facets"]).strip_edges().to_lower()
		if FACET_MODES.has(want_facets) and want_facets != facets:
			facets = want_facets
			changed = true

	if changed and _built:
		_build()
