# parametric-platonic-gallery__cube.gd — promoted from DNA gallery
extends Node3D
class_name CubePromoted

# @identity
# essence: cube — 6 faces, 8 vertices, 12 edges — promoted from the canonical Platonic-solid set
# desire: a stable, named Godot artifact for the exact parameter point that earned a 5★ verdict — placeable in maps, instanceable from code
# critical_parameter: (no overrides — canonical primitive)
# triggers: instantiated like any other primitive scene; the wrapper extends the underlying primitive so apply_grid_config + capture still work
# emerges: the human's "this is the keeper" signal becomes a thing the project can place, capture, and reference by name
# needs: underlying primitive [res://commons/primitives/cube/cube.tscn]; rating ≥ 4 stars [verified at promotion]
# relationships: thin wrapper over res://commons/primitives/cube/cube.gd; sibling to every other promoted cell under commons/primitives/promoted/
# truth: promoted from gallery "parametric-platonic-gallery" cell "cube" with rating 5★ (crown_jewel) on 2026-05-20T09:10:07.624Z.
#   The chamber takes code → gallery (capture an artifact as a parameter sweep). Promote is the inverse:
#   gallery → code (instantiate one cell as a named, placeable thing). A 5★ cell is the human's
#   signal that "this specific point in the parameter space deserves to be a *thing*, not just a sample."

const _PROMOTION_META := {
	"source_gallery": "parametric-platonic-gallery",
	"source_entry": "cube",
	"stars": 5,
	"verdict": "crown_jewel",
	"promoted_at": "2026-05-20T09:10:07.624Z",
}

func _ready() -> void:
	# The underlying primitive scene does the actual mesh build. This wrapper
	# only exists to (a) give the promoted cell a class_name + scene of its
	# own, (b) carry the @identity block linking back to the gallery, and
	# (c) bake the cell's parameter overrides into a single .tscn.
	pass

# Returns the promotion metadata block. Useful for capture / listing tooling
# that wants to know where a promoted artifact came from.
func get_promotion_meta() -> Dictionary:
	return _PROMOTION_META.duplicate(true)
